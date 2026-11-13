import { CALCULAR_INDICADORES_MES } from '../database/consultas/indicadores.ts';
import { getPool } from '../database/pool.ts';
import { obtenerDuenoActivo } from '../database/identidad.ts';

// Usa un único corte para los cuatro KPI y aplica los semáforos del informe.
export async function indicadoresCustomers(owner: number) {
  if (!(await obtenerDuenoActivo(owner)))
    throw new Error('Acceso del dueño activo requerido');
  const result = await (await getPool())
    .request()
    .query(CALCULAR_INDICADORES_MES);
  const sets = result.recordsets as unknown as Record<
    string,
    number | Date
  >[][];
  return presentarIndicadores(sets);
}

// El dashboard reutiliza presentación/fórmulas con los resultados del mismo lote SQL.
export function presentarIndicadores(sets: Record<string, number | Date>[][]) {
  const definiciones = [
    {
      codigo: 'C-2.1',
      nombre: 'Satisfacción general',
      unidad: 'estrellas',
      base: 'calificaciones válidas',
      formula:
        'Suma de estrellas válidas / calificaciones válidas respondidas en el mes',
      fuentes: ['Valoracion'],
      minimo: 3.5,
      objetivo: 4.25,
    },
    {
      codigo: 'C-2.2',
      nombre: 'Respuesta a valoraciones',
      unidad: '%',
      base: 'solicitudes emitidas',
      formula:
        'Solicitudes emitidas en el mes con respuesta al corte / solicitudes emitidas en el mes × 100',
      fuentes: ['SolicitudValoracion', 'Valoracion'],
      minimo: 20,
      objetivo: 40,
    },
    {
      codigo: 'C-2.3',
      nombre: 'Resolución de incidencias',
      unidad: '%',
      base: 'incidencias del mes',
      formula:
        'Incidencias de servicio/acceso abiertas en el mes y resueltas al corte / incidencias de servicio/acceso abiertas en el mes × 100',
      fuentes: ['CasoAtencion'],
      minimo: 70,
      objetivo: 90,
    },
    {
      codigo: 'C-6.1',
      nombre: 'Aceptación de cambios de plan',
      unidad: '%',
      base: 'propuestas presentadas',
      formula:
        'Propuestas presentadas en el mes y aceptadas al corte / propuestas presentadas en el mes × 100. APLICADA también acredita aceptación; aceptación no equivale a aplicación.',
      fuentes: ['PropuestaCambioPlan'],
      minimo: 20,
      objetivo: 40,
    },
  ];
  return {
    fase: 'CUSTOMERS',
    periodo: 'MES_EN_CURSO',
    inicio: sets[0]![0]!.inicio,
    corte: sets[0]![0]!.corte,
    provisional: true,
    nota: 'Avance del mes hasta el corte en hora peruana. Datos operativos actuales; no es un cierre mensual congelado. Sin denominador: no aplicable.',
    indicadores: definiciones.map((d, i) => {
      const row = sets[i + 1]![0]!;
      const numerador = Number(row.numerador),
        denominador = Number(row.denominador);
      const valor = denominador
        ? (numerador / denominador) * (d.unidad === '%' ? 100 : 1)
        : null;
      return {
        ...d,
        numerador,
        denominador,
        valor,
        semaforo:
          valor === null
            ? 'SIN_DATOS'
            : valor < d.minimo
              ? 'REQUIERE_ATENCION'
              : valor < d.objetivo
                ? 'EN_SEGUIMIENTO'
                : 'FAVORABLE',
      };
    }),
  };
}
