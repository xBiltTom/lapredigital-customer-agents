import { politicaActual, politicaVersion } from '../servicios/politicas.ts';
import {
  CONSULTAR_DIAGNOSTICO,
  CONSULTAR_TEMARIO_DIAGNOSTICO,
} from '../database/consultas/diagnostico.ts';
import { leerContextoNarrativo, calcularRiesgo, directorioContextos } from './riesgo.ts';
import sql from 'mssql';
import { randomUUID } from 'node:crypto';
import { mkdir, writeFile, rename } from 'node:fs/promises';
import { getPool } from '../database/pool.ts';
import { obtenerFichaEstudiante } from '../database/estudiantes.ts';
import {
  vigente,
  cumplimiento,
  mejoras,
  type Contexto,
  type Intento,
} from './reglas.ts';

type Ruta = { id: number; version: number; vigente: boolean };
type Actividad = {
  id: number;
  rutaId: number;
  titulo: string;
  estado: string;
  planificada: Date;
  limite: Date;
  completada: Date | null;
};
type Mensaje = {
  id: number;
  fecha: Date;
  contenido: string;
  intencion: string | null;
};
type Valoracion = {
  id: number;
  fecha: Date;
  estrellas: number;
  comentario: string | null;
  aspecto: string;
};
type Caso = {
  id: number;
  tipo: string;
  ambito: string;
  estado: string;
  apertura: Date;
  descripcion: string;
};
type Dificultad = {
  id: number;
  fecha: Date;
  estado: string;
  descripcion: string;
};
type Permiso = {
  canal: string;
  autorizado: boolean;
  fecha: Date;
  evidencia: string;
};
type Accion = {
  id: number;
  tipo: string;
  estado: string;
  recomendacion: string;
  resultado: string | null;
  fecha: Date;
  evaluacionId: number | null;
  requiereAprobacion: boolean;
};
type Revision = {
  id: number;
  rutaId: number;
  motivo: string;
  estado: string;
  recomendacion: string | null;
  resultado: string | null;
};
type Evaluacion = {
  id: number;
  fecha: Date;
  estado: string;
  nivel: string | null;
  versionReglas: string;
};
const directorio = directorioContextos;

// Construye la ficha operativa del alumno a partir de fuentes actuales, sin escribir en SQL.
export async function diagnostico(
  personalInternoId: number,
  estudianteId: number,
) {
  const ficha = await obtenerFichaEstudiante(
    { personalInternoId },
    estudianteId,
  );
  if (!ficha) throw new Error('Estudiante no disponible para esta identidad.');
  const politica = await politicaActual();
  const pool = await getPool();
  const result = await pool
    .request()
    .input('id', sql.Int, estudianteId)
    .query(CONSULTAR_DIAGNOSTICO);
  const [
    tiempo,
    rutas,
    actividades,
    intentos,
    uso,
    frecuencia,
    casos,
    dificultades,
    mensajes,
    valoraciones,
    permisos,
    acciones,
    revisiones,
    evaluaciones,
  ] = result.recordsets as unknown as [
    { corte: Date }[],
    Ruta[],
    Actividad[],
    Intento[],
    { id: number; fecha: Date }[],
    { recientes: number; anteriores: number }[],
    Caso[],
    Dificultad[],
    Mensaje[],
    Valoracion[],
    Permiso[],
    Accion[],
    Revision[],
    Evaluacion[],
  ];
  const corte = tiempo[0]!.corte,
    inicio = new Date(+corte - 30 * 86400000);
  const { huella, contexto } = await leerContextoNarrativo(estudianteId, mensajes, valoraciones, politica);
  const { riesgo, narrativaPendiente } = calcularRiesgo({ corte, politica, uso: uso[0] ?? null, casos, dificultades, mensajes, valoraciones, contexto });
  const ruta = rutas.find((r) => r.vigente) ?? null;
  // Explicar por qué el seguimiento está permitido o bloqueado.
  const causas: string[] = [];
  if (!ficha.servicioActual || ficha.estudiante.etapaActual !== 'CUSTOMER')
    causas.push('Sin servicio CUSTOMER vigente');
  if (!ficha.prestaciones.some((p) => p.codigo === 'SEGUIMIENTO_IA'))
    causas.push('Plan sin seguimiento IA');
  if (contexto.noContacto.length)
    causas.push('Petición de no contacto proactivo');
  if (narrativaPendiente)
    causas.push('Revisar conversaciones y valoraciones antes del seguimiento');
  if (!['MEDIO', 'ALTO'].includes(riesgo.nivel ?? ''))
    causas.push('Riesgo sin clasificación media o alta');
  const canales = permisos.filter((p) => p.autorizado).map((p) => p.canal);
  if (!canales.length) causas.push('Sin canal académico autorizado');
  const calificaciones = valoraciones.filter((v) => v.fecha >= inicio);
  const ultima = evaluaciones[0] ?? null;
  const politicaGuardada = ultima ? await politicaVersion(ultima.versionReglas) : null;
  const temario = (
    await pool
      .request()
      .input('e', sql.Int, estudianteId)
      .query(CONSULTAR_TEMARIO_DIAGNOSTICO)
  ).recordset;
  return {
    temario,
    estudianteId,
    corte,
    inicio,
    versionReglas: politica.VersionReglas,
    reglas: politica,
    huella,
    ficha,
    ruta,
    rutas,
    actividades,
    intentos,
    cumplimiento: cumplimiento(actividades, ruta?.id ?? null, inicio, corte),
    mejoras: mejoras(intentos),
    uso: uso[0] ?? null,
    frecuencia: frecuencia[0]!,
    casos,
    dificultades,
    revisiones,
    mensajes,
    valoraciones,
    permisos,
    acciones,
    satisfaccion: calificaciones.length
      ? calificaciones.reduce((s, v) => s + v.estrellas, 0) /
        calificaciones.length
      : null,
    riesgo,
    narrativaPendiente,
    contexto,
    seguimiento: { permitido: causas.length === 0, causas, canales },
    evaluacionGuardada: ultima
      ? {
          ...ultima,
          vigente:
            ultima.estado === 'CLASIFICADA' && vigente(ultima.fecha, corte, politicaGuardada!.VigenciaDias),
          politicaActual: ultima.versionReglas === politica.VersionReglas,
        }
      : null,
  };
}

// Guarda la interpretación del agente solo si los IDs y la huella siguen coincidiendo.
export async function guardarContexto(
  personalInternoId: number,
  estudianteId: number,
  huella: string,
  contexto: Contexto,
) {
  const d = await diagnostico(personalInternoId, estudianteId);
  if (d.huella !== huella)
    throw new Error(
      'La evidencia cambió. Consultar de nuevo antes de interpretar.',
    );
  for (const ids of [
    contexto.revisados,
    contexto.cancelacion,
    contexto.noContacto,
  ])
    if (ids.some((id) => !d.mensajes.some((m) => m.id === id)))
      throw new Error('Mensaje ajeno o inexistente.');
  if (
    contexto.insatisfaccion.some(
      (id) => !d.valoraciones.some((v) => v.id === id && v.estrellas <= d.reglas.MaxEstrellasInsatisfaccion),
    )
  )
    throw new Error('Valoración inválida para insatisfacción.');
  if (
    contexto.valoracionesRevisadas.some(
      (id) => !d.valoraciones.some((v) => v.id === id),
    )
  )
    throw new Error('Valoración ajena o inexistente.');
  await mkdir(directorio, { recursive: true, mode: 0o700 });
  const temp = `${directorio}/${estudianteId}.${randomUUID()}.tmp`;
  await writeFile(temp, JSON.stringify({ huella, contexto, maxEstrellas: d.reglas.MaxEstrellasInsatisfaccion }), { mode: 0o600 });
  await rename(temp, `${directorio}/${estudianteId}.json`);
  return diagnostico(personalInternoId, estudianteId);
}

// Serializa las fechas de negocio con offset peruano antes de enviarlas a la API/modelo.
export function jsonSeguro(value: unknown): unknown {
  if (value instanceof Date) {
    const local = new Date(+value - 5 * 3600000).toISOString().slice(0, 19);
    return local + '-05:00';
  }
  if (Array.isArray(value)) return value.map(jsonSeguro);
  if (value && typeof value === 'object')
    return Object.fromEntries(
      Object.entries(value).map(([k, v]) => [k, jsonSeguro(v)]),
    );
  return value;
}
