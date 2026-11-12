export type Nivel = 'BAJO' | 'MEDIO' | 'ALTO';
export type Contexto = { revisados: number[]; valoracionesRevisadas: number[]; cancelacion: number[]; noContacto: number[]; insatisfaccion: number[] };
export const contextoVacio = (): Contexto => ({ revisados: [], valoracionesRevisadas: [], cancelacion: [], noContacto: [], insatisfaccion: [] });
export const inactividad = (segundos: number): Nivel => segundos >= 604800 ? 'ALTO' : segundos >= 259200 ? 'MEDIO' : 'BAJO';
export const incidencia = (segundos: number): Nivel => segundos > 345600 ? 'ALTO' : segundos > 172800 ? 'MEDIO' : 'BAJO';
export const vigente = (fecha: Date, corte: Date) => fecha <= corte && +corte - +fecha <= 604800000;
export type Senal = { codigo: string; nivel: Nivel; fuente: string; id: number; fecha: Date };
export function clasificar(senales: Senal[], suficiente: boolean) {
  const peso = { BAJO: 0, MEDIO: 1, ALTO: 2 };
  const mayor = senales.reduce<Nivel>((n, s) => peso[s.nivel] > peso[n] ? s.nivel : n, 'BAJO');
  const clasificada = mayor === 'ALTO' || suficiente;
  return { estado: clasificada ? 'CLASIFICADA' : 'PENDIENTE', nivel: clasificada ? mayor : null,
    mayorObservado: senales.length ? mayor : null, senales };
}
export function cumplimiento(actividades: { rutaId: number; estado: string; planificada: Date; completada: Date | null }[], rutaId: number | null, inicio: Date, corte: Date) {
  const tareas = actividades.filter(a => a.rutaId === rutaId && a.estado !== 'CANCELADA' && a.planificada >= inicio && a.planificada <= corte);
  const completas = tareas.filter(a => a.estado === 'COMPLETADA' && a.completada && a.completada <= corte).length;
  return { planificadas: tareas.length, completadas: completas, porcentaje: tareas.length ? 100 * completas / tareas.length : null };
}
export type Intento = { id: number; grupoId: number | null; grupo: string | null; alcance: string | null; escala: string | null; dificultad: string | null; fecha: Date; aciertos: number; total: number };
export function mejoras(intentos: Intento[]) {
  const grupos = new Map<number, Intento[]>();
  for (const i of intentos) if (i.grupoId !== null) grupos.set(i.grupoId, [...(grupos.get(i.grupoId) ?? []), i]);
  return [...grupos].map(([grupoId, filas]) => {
    filas.sort((a, b) => +a.fecha - +b.fecha || a.id - b.id);
    const primero = filas[0]!, ultimo = filas.at(-1)!;
    const comparable = filas.length > 1 && ultimo.fecha > primero.fecha;
    return { grupoId, grupo: primero.grupo, alcance: primero.alcance, escala: primero.escala, dificultad: primero.dificultad,
      inicialId: primero.id, posteriorId: comparable ? ultimo.id : null,
      inicialPct: 100 * primero.aciertos / primero.total,
      posteriorPct: comparable ? 100 * ultimo.aciertos / ultimo.total : null,
      mejoraPP: comparable ? 100 * (ultimo.aciertos / ultimo.total - primero.aciertos / primero.total) : null };
  });
}
