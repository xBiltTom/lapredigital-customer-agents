import { z } from "zod";
import { getReadOnlyPool } from "../database/lectura.ts";
import {
  tablasNegocio,
  SQL_CATALOGO_NEGOCIO,
  type CatalogoNegocio,
  type ColumnaNegocio,
  type RelacionNegocio,
} from "../database/catalogo-negocio.ts";
import {
  autorizarHerramienta,
  type AuthHerramienta,
} from "../seguridad/alcance-herramientas.ts";

const nombre = z.string().regex(/^[A-Za-z][A-Za-z0-9_]{0,63}$/);
const valor = z.union([z.string().max(2000), z.number().finite(), z.boolean()]);
export const consultaNegocioSchema = z.object({
  accion: z.enum(["CATALOGO", "CONSULTAR"]),
  tabla: z.enum(tablasNegocio).optional(),
  alias: nombre.default("base"),
  relaciones: z
    .array(
      z.object({
        tabla: z.enum(tablasNegocio),
        alias: nombre,
        desde: nombre,
        claveForanea: nombre.optional(),
      }),
    )
    .max(4)
    .default([]),
  columnas: z.array(z.string().max(130)).min(1).max(20).optional(),
  filtros: z
    .array(
      z.object({
        campo: z.string().max(130),
        operador: z.enum([
          "IGUAL",
          "DISTINTO",
          "MAYOR_IGUAL",
          "MENOR_IGUAL",
          "CONTIENE",
          "NULO",
          "NO_NULO",
          "EN",
        ]),
        valor: valor.optional(),
        valores: z.array(valor).min(1).max(50).optional(),
      }),
    )
    .max(16)
    .default([]),
  agruparPor: z.array(z.string().max(130)).max(4).default([]),
  medidas: z
    .array(
      z.object({
        operacion: z.enum([
          "CONTAR",
          "CONTAR_DISTINTOS",
          "SUMAR",
          "PROMEDIO",
          "MINIMO",
          "MAXIMO",
        ]),
        campo: z.string().max(130).optional(),
        alias: nombre,
      }),
    )
    .max(4)
    .default([]),
  orden: z
    .array(
      z.object({
        campo: z.string().max(130),
        direccion: z.enum(["ASC", "DESC"]).default("ASC"),
      }),
    )
    .max(4)
    .default([]),
  pagina: z.number().int().min(1).max(10000).default(1),
  limite: z.number().int().min(1).max(100).default(20),
});
export type ConsultaNegocio = z.infer<typeof consultaNegocioSchema>;
const citar = (s: string) => "[" + s.replaceAll("]", "]]") + "]";
const numericos = new Set([
  "tinyint",
  "smallint",
  "int",
  "bigint",
  "decimal",
  "numeric",
  "float",
  "real",
  "money",
  "smallmoney",
]);

// Constructor estructurado: solo identificadores del catálogo y valores parametrizados.
// Ningún fragmento SQL del modelo entra en la consulta.
export function construirConsultaNegocio(
  b: ConsultaNegocio,
  catalogo: CatalogoNegocio,
) {
  if (!b.tabla || !tablasNegocio.includes(b.tabla))
    throw new Error("Elige una tabla del catálogo.");
  if (!catalogo.columnas.some((c) => c.tabla === b.tabla))
    throw new Error(
      "La tabla no está disponible en esta base. Consulta CATALOGO.",
    );
  const aliases = new Map([[b.alias, b.tabla as string]]);
  let origen = `dbo.${citar(b.tabla)} ${citar(b.alias)}`;
  for (const j of b.relaciones) {
    const desde = aliases.get(j.desde);
    if (!desde || aliases.has(j.alias) || !tablasNegocio.includes(j.tabla))
      throw new Error("Relación o alias fuera del catálogo.");
    const candidatas = catalogo.relaciones.filter(
      (r) =>
        (r.origen === desde && r.destino === j.tabla) ||
        (r.destino === desde && r.origen === j.tabla),
    );
    const nombres = [...new Set(candidatas.map((r) => r.nombre))];
    const clave =
      j.claveForanea ?? (nombres.length === 1 ? nombres[0] : undefined);
    const columnas = candidatas
      .filter((r) => r.nombre === clave)
      .sort((a, b) => a.orden - b.orden);
    if (!columnas.length)
      throw new Error(
        "Indica una claveForanea del catálogo entre esas tablas.",
      );
    const condiciones = columnas.map((r) => {
      const directa = r.origen === desde;
      return `${citar(j.desde)}.${citar(directa ? r.columnaOrigen : r.columnaDestino)}=${citar(j.alias)}.${citar(directa ? r.columnaDestino : r.columnaOrigen)}`;
    });
    origen += ` LEFT JOIN dbo.${citar(j.tabla)} ${citar(j.alias)} ON ${condiciones.join(" AND ")}`;
    aliases.set(j.alias, j.tabla);
  }
  const campo = (v: string) => {
    const [alias, columna, extra] = v.split(".");
    const tabla = aliases.get(alias!);
    const meta = catalogo.columnas.find(
      (c) => c.tabla === tabla && c.columna === columna,
    );
    if (extra || !meta)
      throw new Error(
        `Campo no disponible: ${v}. Consulta el catálogo de la tabla.`,
      );
    return { sql: `${citar(alias!)}.${citar(columna!)}`, tipo: meta.tipo };
  };
  const parametros: { nombre: string; valor: string | number | boolean }[] = [];
  const parametro = (v: string | number | boolean) => {
    const nombre = "p" + parametros.length;
    parametros.push({ nombre, valor: v });
    return "@" + nombre;
  };
  const condiciones = b.filtros.map((f) => {
    const c = campo(f.campo).sql;
    if (f.operador === "NULO") return `${c} IS NULL`;
    if (f.operador === "NO_NULO") return `${c} IS NOT NULL`;
    if (f.operador === "EN") {
      if (!f.valores?.length) throw new Error("El filtro EN necesita valores.");
      return `${c} IN (${f.valores.map(parametro).join(",")})`;
    }
    if (f.valor === undefined) throw new Error("El filtro necesita un valor.");
    if (f.operador === "CONTIENE")
      return `${c} LIKE ${parametro("%" + String(f.valor).replace(/[~%_\[]/g, "~$&") + "%")} ESCAPE '~'`;
    const op = {
      IGUAL: "=",
      DISTINTO: "<>",
      MAYOR_IGUAL: ">=",
      MENOR_IGUAL: "<=",
    }[f.operador];
    return `${c}${op}${parametro(f.valor)}`;
  });
  const grupos = b.agruparPor.map((c) => campo(c).sql);
  const nombresMedidas = new Set<string>();
  const medidas = b.medidas.map((m) => {
    if (nombresMedidas.has(m.alias) || aliases.has(m.alias))
      throw new Error("El alias de cada medida debe ser único.");
    nombresMedidas.add(m.alias);
    const c = m.campo ? campo(m.campo) : undefined;
    if (!c && m.operacion !== "CONTAR")
      throw new Error("La medida necesita un campo.");
    if (["SUMAR", "PROMEDIO"].includes(m.operacion) && !numericos.has(c!.tipo))
      throw new Error("Sumas y promedios requieren un campo numérico.");
    const expresion =
      m.operacion === "CONTAR"
        ? `COUNT_BIG(${c?.sql ?? "*"})`
        : m.operacion === "CONTAR_DISTINTOS"
          ? `COUNT_BIG(DISTINCT ${c!.sql})`
          : m.operacion === "SUMAR"
            ? `SUM(CONVERT(decimal(28,6),${c!.sql}))`
            : m.operacion === "PROMEDIO"
              ? `AVG(CONVERT(decimal(28,6),${c!.sql}))`
              : `${m.operacion === "MINIMO" ? "MIN" : "MAX"}(${c!.sql})`;
    return `${expresion} AS ${citar(m.alias)}`;
  });
  const agregado = medidas.length > 0 || grupos.length > 0;
  if (agregado && b.columnas?.some((c) => !b.agruparPor.includes(c)))
    throw new Error(
      "En un resumen las columnas deben pertenecer a agruparPor.",
    );
  const seleccion = agregado
    ? [
        ...grupos.map((c, i) => `${c} AS ${citar(b.agruparPor[i]!)}`),
        ...medidas,
      ]
    : (
        b.columnas ??
        catalogo.columnas
          .filter((c) => c.tabla === b.tabla && c.columna !== "Documento")
          .slice(0, 12)
          .map((c) => `${b.alias}.${c.columna}`)
      ).map((c) => `${campo(c).sql} AS ${citar(c)}`);
  if (!seleccion.length) throw new Error("Selecciona columnas o medidas.");
  const orden = b.orden.map((o) => {
    if (nombresMedidas.has(o.campo)) return `${citar(o.campo)} ${o.direccion}`;
    if (agregado && !b.agruparPor.includes(o.campo))
      throw new Error("Ordena por una agrupación o medida.");
    return `${campo(o.campo).sql} ${o.direccion}`;
  });
  const consulta = `SELECT ${seleccion.join(",")} FROM ${origen}${condiciones.length ? " WHERE " + condiciones.join(" AND ") : ""}${grupos.length ? " GROUP BY " + grupos.join(",") : ""}`;
  // El conteo se calcula antes de paginar, incluso cuando la página queda vacía.
  const predeterminado = agregado
    ? "1"
    : campo(
        `${b.alias}.${catalogo.columnas.find((c) => c.tabla === b.tabla)!.columna}`,
      ).sql;
  return {
    sql: `DECLARE @corte datetime2(0)=GETDATE(); SELECT COUNT_BIG(*) total FROM (${consulta}) resultado; ${consulta} ORDER BY ${orden.length ? orden.join(",") : predeterminado} OFFSET @offset ROWS FETCH NEXT @limite ROWS ONLY; SELECT @corte corte;`,
    parametros,
    tablas: [...new Set(aliases.values())],
  };
}

export async function consultarDatosNegocio(
  auth: AuthHerramienta,
  entrada: ConsultaNegocio,
) {
  await autorizarHerramienta(auth, "global");
  const b = consultaNegocioSchema.parse(entrada);
  const pool = await getReadOnlyPool();
  const resultado = await pool.request().query(SQL_CATALOGO_NEGOCIO);
  const [columnas, relaciones] = resultado.recordsets as unknown as [
    ColumnaNegocio[],
    RelacionNegocio[],
  ];
  const catalogo: CatalogoNegocio = {
    columnas: columnas.filter((c) =>
      tablasNegocio.includes(c.tabla as (typeof tablasNegocio)[number]),
    ),
    relaciones: relaciones.filter(
      (r) =>
        tablasNegocio.includes(r.origen as (typeof tablasNegocio)[number]) &&
        tablasNegocio.includes(r.destino as (typeof tablasNegocio)[number]),
    ),
  };
  if (b.accion === "CATALOGO")
    return b.tabla
      ? {
          tabla: b.tabla,
          columnas: catalogo.columnas.filter((c) => c.tabla === b.tabla),
          relaciones: catalogo.relaciones.filter(
            (r) => r.origen === b.tabla || r.destino === b.tabla,
          ),
        }
      : {
          tablas: tablasNegocio.filter((t) =>
            catalogo.columnas.some((c) => c.tabla === t),
          ),
          uso: "Consulta CATALOGO con tabla para ver campos y claves. CONSULTAR usa campos alias.Columna, relaciones por claves verificadas, filtros parametrizados y medidas. No recibe SQL. Los historiales son filas anteriores; los KPI oficiales se consultan con consultar_indicadores.",
        };
  const plan = construirConsultaNegocio(b, catalogo);
  const request = pool
    .request()
    .input("offset", (b.pagina - 1) * b.limite)
    .input("limite", b.limite);
  for (const p of plan.parametros) request.input(p.nombre, p.valor);
  const r = await request.query(plan.sql);
  const [conteo, registros, tiempos] = r.recordsets as unknown as [
    { total: number }[],
    Record<string, unknown>[],
    { corte: Date }[],
  ];
  const total = Number(conteo[0]!.total);
  return {
    fuente: plan.tablas,
    corte: tiempos[0]!.corte,
    total,
    pagina: b.pagina,
    limite: b.limite,
    siguientePagina: total > b.pagina * b.limite ? b.pagina + 1 : null,
    registros,
  };
}
