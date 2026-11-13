import sql from "mssql";
import { getPool } from "../database/pool.ts";
import {
  autorizarAlumno,
  autorizarHerramienta,
} from "../seguridad/alcance-herramientas.ts";

// Vistas de negocio: las proyecciones y relaciones son código del servidor.
// El modelo elige recurso/filtros, nunca SQL ni columnas o tablas arbitrarias.
import { consultasRecursos as recursos } from "../database/consultas/recursos.ts";
export type RecursoConsulta = keyof typeof recursos;
export type FiltrosConsulta = {
  recurso: RecursoConsulta;
  estudianteId?: number;
  estado?: string;
  tipo?: string;
  buscar?: string;
  desde?: string;
  hasta?: string;
  orden: "RECIENTE" | "ANTIGUO" | "IMPORTE_MAYOR";
  limite: number;
  pagina: number;
};
// Flujo: verificar identidad → limitar alumno → validar filtros → ejecutar lectura parametrizada.
export async function consultarBase(
  auth: {
    authenticator?: string;
    attributes?: Readonly<Record<string, string | readonly string[]>>;
  } | null,
  opciones: FiltrosConsulta,
) {
  const atributos = auth?.attributes;
  const global = atributos?.modo === "global",
    participante = atributos?.modo === "participante";
  const e =
    global && opciones.estudianteId === undefined
      ? (await autorizarHerramienta(auth, "global"), undefined)
      : (await autorizarAlumno(auth, opciones.estudianteId)).estudianteId;
  // Solo se aceptan filtros que existen en el recurso seleccionado.
  const columnas: Record<RecursoConsulta, readonly string[]> = {
    PAGOS: ["estado", "tipo"],
    SERVICIO: ["estado", "tipo"],
    ACTIVIDADES: ["estado", "tipo"],
    EVALUACIONES: ["tipo"],
    INCIDENCIAS: ["estado", "tipo"],
    VALORACIONES: ["tipo"],
  };
  if (opciones.estado && !columnas[opciones.recurso].includes("estado"))
    throw new Error("Este recurso no tiene filtro estado");
  if (
    opciones.orden === "IMPORTE_MAYOR" &&
    !["PAGOS", "SERVICIO"].includes(opciones.recurso)
  )
    throw new Error("Orden por importe solo disponible para pagos/servicio");
  // El alcance del alumno se aplica siempre, incluso si el modelo omite filtros.
  const filtros = ["(@e IS NULL OR estudianteId=@e)"];
  // Planificación y contratos pueden tener vigencia futura; los hechos observados no.
  if (!["ACTIVIDADES", "SERVICIO"].includes(opciones.recurso))
    filtros.push("fecha<=@corte");
  if (opciones.desde && opciones.hasta && opciones.desde > opciones.hasta)
    throw new Error("La fecha desde debe ser anterior o igual a hasta.");
  if (opciones.estado) filtros.push("estado=@estado");
  if (opciones.tipo) filtros.push("tipo=@tipo");
  if (opciones.buscar) filtros.push("descripcion LIKE @buscar ESCAPE '~'");
  if (opciones.desde) filtros.push("fecha>=@desde");
  if (opciones.hasta) filtros.push("fecha<DATEADD(DAY,1,@hasta)");
  // Los valores y fechas siempre viajan parametrizados; los identificadores vienen del mapa cerrado.
  const orden =
    opciones.orden === "IMPORTE_MAYOR"
      ? "importePEN DESC, fecha DESC"
      : opciones.orden === "ANTIGUO"
        ? "fecha ASC"
        : "fecha DESC";

  const query = `
    DECLARE @corte DATETIME2(0)=GETDATE();
    WITH datos AS (
      ${recursos[opciones.recurso]}
    ) SELECT COUNT(*) total FROM datos WHERE ${filtros.join(" AND ")};
    WITH datos AS (
      ${recursos[opciones.recurso]}
    )
    SELECT *
    FROM datos
    WHERE ${filtros.join(" AND ")}
    ORDER BY ${orden}, id DESC
    OFFSET @offset ROWS
    FETCH NEXT @limite ROWS ONLY;
    SELECT @corte corte;
  `;
  const r = await (
    await getPool()
  )
    .request()
    .input("e", sql.Int, e ?? null)
    .input("estado", sql.VarChar(30), opciones.estado ?? null)
    .input("tipo", sql.VarChar(100), opciones.tipo ?? null)
    .input(
      "buscar",
      sql.NVarChar(300),
      opciones.buscar
        ? "%" + opciones.buscar.replace(/[~%_\[]/g, "~$&") + "%"
        : null,
    )
    .input("desde", sql.Date, opciones.desde ?? null)
    .input("hasta", sql.Date, opciones.hasta ?? null)
    .input("offset", sql.Int, (opciones.pagina - 1) * opciones.limite)
    .input("limite", sql.Int, opciones.limite)
    .query(query);
  const [conteo, filas, tiempos] = r.recordsets as unknown as [
    { total: number }[],
    Record<string, unknown>[],
    { corte: Date }[],
  ];
  const total = Number(conteo[0]!.total);
  const registros = filas.map((fila) => {
    if (!participante) return fila;
    const { pagadorContactoId: _pagador, ...publica } = fila;
    return publica;
  });
  return {
    recurso: opciones.recurso,
    estudianteId: e ?? null,
    pagina: opciones.pagina,
    limite: opciones.limite,
    corte: tiempos[0]!.corte,
    total,
    estadoDatos: total ? "CON_DATOS" : "SIN_REGISTROS",
    siguientePagina:
      total > opciones.pagina * opciones.limite ? opciones.pagina + 1 : null,
    registros,
    criterios: opciones,
    interpretacion:
      opciones.recurso === "PAGOS"
        ? "Último pago recibido: filtrar tipo COBRO, estado CONFIRMADO y orden RECIENTE. El importe es el cobro bruto para la suscripción del estudiante, no identifica quién pagó. REEMBOLSO/REVERSION/DISPUTA son operaciones separadas; no son nuevos cobros. No confundir importe exigible del servicio con dinero cobrado. Ausencia de cobros no demuestra deuda; comprobar beca y vigencia."
        : undefined,
  };
}
