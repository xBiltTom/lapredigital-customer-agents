import sql from "mssql";
import { getPool } from "../database/pool.ts";
import { CONSULTAR_DASHBOARD } from "../database/consultas/dashboard.ts";
import {
  calcularRiesgo,
  leerContextoNarrativo,
  type CasoRiesgo,
  type DificultadRiesgo,
  type MensajeRiesgo,
  type ValoracionRiesgo,
} from "../academico/riesgo.ts";
import type { ParametrosRiesgo } from "../academico/reglas.ts";
import { presentarIndicadores } from "./indicadores.ts";

type Asignado<T> = T & { estudianteId: number };
type ResumenAlumno = {
  id: number;
  codigo: string;
  nombre: string;
  etapa: string;
  servicioActivo: boolean;
  completados: number;
  total: number;
  planificadas: number;
  completadas: number;
  usoId: number | null;
  usoFecha: Date | null;
};
type ConsultaDueno = {
  ConsultaId: number;
  EstudianteId: number;
  ContactoId: number;
  Rol: string;
  Canal: string;
  Pregunta: string;
  Respuesta: string | null;
  Estado: string;
  Fecha: Date;
};
type DatosDashboard = [
  { corte: Date }[],
  ParametrosRiesgo[],
  ResumenAlumno[],
  Asignado<CasoRiesgo>[],
  Asignado<DificultadRiesgo>[],
  Asignado<MensajeRiesgo>[],
  Asignado<ValoracionRiesgo>[],
  ConsultaDueno[],
  ...Record<string, number | Date>[][],
];

function agrupar<T>(filas: Asignado<T>[]) {
  const grupos = new Map<number, T[]>();
  for (const { estudianteId, ...dato } of filas) {
    const grupo = grupos.get(estudianteId) ?? [];
    grupo.push(dato as T);
    grupos.set(estudianteId, grupo);
  }
  return grupos;
}

// Sin caché de negocio: cada ejecución usa un corte SQL y valida al dueño en el lote.
export async function resumenDashboard(owner: number) {
  if (!Number.isSafeInteger(owner) || owner < 1)
    throw new Error("Identidad requerida.");
  const result = await (await getPool())
    .request()
    .input("owner", sql.Int, owner)
    .query(CONSULTAR_DASHBOARD);
  const [
    tiempo,
    politicas,
    filas,
    casos,
    dificultades,
    mensajes,
    valoraciones,
    consultas,
    ...kpi
  ] = result.recordsets as unknown as DatosDashboard;
  const corte = tiempo[0]!.corte;
  const politica = politicas[0];
  if (!politica) throw new Error("Falta la política de riesgo vigente.");
  const casosPorAlumno = agrupar(casos),
    dificultadesPorAlumno = agrupar(dificultades);
  const mensajesPorAlumno = agrupar(mensajes),
    valoracionesPorAlumno = agrupar(valoraciones);
  const alumnos = await Promise.all(
    filas.map(async (fila) => {
      const mensajesAlumno = mensajesPorAlumno.get(fila.id) ?? [];
      const valoracionesAlumno = valoracionesPorAlumno.get(fila.id) ?? [];
      const casosAlumno = casosPorAlumno.get(fila.id) ?? [];
      const { contexto } = await leerContextoNarrativo(
        fila.id,
        mensajesAlumno,
        valoracionesAlumno,
        politica,
      );
      const { riesgo } = calcularRiesgo({
        corte,
        politica,
        contexto,
        mensajes: mensajesAlumno,
        valoraciones: valoracionesAlumno,
        casos: casosAlumno,
        dificultades: dificultadesPorAlumno.get(fila.id) ?? [],
        uso:
          fila.usoId !== null && fila.usoFecha
            ? { id: fila.usoId, fecha: fila.usoFecha }
            : null,
      });
      return {
        id: fila.id,
        codigo: fila.codigo,
        nombre: fila.nombre,
        etapa: fila.etapa,
        servicioActivo: Boolean(fila.servicioActivo),
        riesgo: riesgo.nivel ?? "PENDIENTE",
        completados: fila.completados,
        total: fila.total,
        cumplimiento: fila.planificadas
          ? (100 * fila.completadas) / fila.planificadas
          : null,
        incidencias: casosAlumno.length,
      };
    }),
  );
  return {
    indicadores: presentarIndicadores(kpi),
    definiciones: {
      completados:
        "Temas completados del temario UNT 2027, no actividades de ruta ni dominio demostrado",
      cumplimiento:
        "Porcentaje de actividades completadas de la ruta vigente en ventana de 30 días; tiene otro alcance que el temario",
      incidencias:
        "Casos de atención no resueltos; incluye consultas, no solo incidencias",
    },
    alumnos,
    consultas,
  };
}
