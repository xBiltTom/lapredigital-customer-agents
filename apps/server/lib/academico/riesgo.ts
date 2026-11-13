import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import {
  clasificar,
  inactividad,
  incidencia,
  contextoVacio,
  type Contexto,
  type ParametrosRiesgo,
  type Senal,
} from "./reglas.ts";

export type MensajeRiesgo = {
  id: number;
  fecha: Date;
  contenido: string;
  intencion: string | null;
};
export type ValoracionRiesgo = {
  id: number;
  fecha: Date;
  estrellas: number;
  comentario: string | null;
  aspecto: string;
};
export type CasoRiesgo = {
  id: number;
  tipo: string;
  ambito: string;
  estado: string;
  apertura: Date;
};
export type DificultadRiesgo = { id: number; fecha: Date; estado: string };
export type UsoRiesgo = { id: number; fecha: Date };
export const directorioContextos = `.eve/contextos/${process.env.SQLSERVER_DATABASE}`;

// La ficha y el dashboard verifican exactamente la misma huella y política narrativa.
export async function leerContextoNarrativo(
  estudianteId: number,
  mensajes: MensajeRiesgo[],
  valoraciones: ValoracionRiesgo[],
  politica: ParametrosRiesgo,
) {
  // La huella invalida interpretaciones si cambiaron mensajes o valoraciones.
  const huella = createHash("sha256")
    .update(JSON.stringify({ mensajes, valoraciones }))
    .digest("hex");
  let contexto = contextoVacio();
  try {
    const saved = JSON.parse(
      await readFile(`${directorioContextos}/${estudianteId}.json`, "utf8"),
    );
    if (saved.huella === huella) {
      contexto = saved.contexto;
      const anteriorMax = saved.maxEstrellas ?? 2;
      if (politica.MaxEstrellasInsatisfaccion > anteriorMax) {
        // Reinterpretar solo estrellas recién incluidas; conservar peticiones de no contacto.
        contexto.valoracionesRevisadas = contexto.valoracionesRevisadas.filter(
          (id) =>
            !valoraciones.some(
              (v) =>
                v.id === id &&
                v.estrellas > anteriorMax &&
                v.estrellas <= politica.MaxEstrellasInsatisfaccion,
            ),
        );
      }
    }
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
  }
  return { huella, contexto };
}

// Una sola implementación del riesgo operativo, tanto individual como por lotes.
export function calcularRiesgo({
  corte,
  politica,
  uso,
  casos,
  dificultades,
  mensajes,
  valoraciones,
  contexto,
}: {
  corte: Date;
  politica: ParametrosRiesgo;
  uso: UsoRiesgo | null;
  casos: CasoRiesgo[];
  dificultades: DificultadRiesgo[];
  mensajes: MensajeRiesgo[];
  valoraciones: ValoracionRiesgo[];
  contexto: Contexto;
}) {
  // Reglas puras: clasificar con evidencias; no convertir falta de datos en riesgo bajo.
  const senales: Senal[] = [];
  if (uso)
    senales.push({
      codigo:
        inactividad((+corte - +uso.fecha) / 1000, politica) === "BAJO"
          ? "ACTIVIDAD_RECIENTE"
          : "INACTIVIDAD",
      nivel: inactividad((+corte - +uso.fecha) / 1000, politica),
      fuente: "EventoUso",
      id: uso.id,
      fecha: uso.fecha,
    });
  for (const c of casos)
    if (
      c.tipo === "INCIDENCIA" &&
      c.ambito !== "PAGO" &&
      c.estado !== "RESUELTA" &&
      incidencia((+corte - +c.apertura) / 1000, politica) !== "BAJO"
    )
      senales.push({
        codigo: "INCIDENCIA_ABIERTA",
        nivel: incidencia((+corte - +c.apertura) / 1000, politica),
        fuente: "CasoAtencion",
        id: c.id,
        fecha: c.apertura,
      });
  for (const d of dificultades)
    if (d.estado !== "SUPERADA")
      senales.push({
        codigo: "DIFICULTAD_ACADEMICA",
        nivel: "MEDIO",
        fuente: "DificultadAcademica",
        id: d.id,
        fecha: d.fecha,
      });
  for (const m of mensajes)
    if (
      ["CANCELAR", "NO_RENOVAR"].includes(m.intencion ?? "") ||
      contexto.cancelacion.includes(m.id)
    )
      senales.push({
        codigo: "INTENCION_CANCELAR",
        nivel: "ALTO",
        fuente: "Mensaje",
        id: m.id,
        fecha: m.fecha,
      });
  for (const v of valoraciones)
    if (
      v.estrellas <= politica.MaxEstrellasInsatisfaccion &&
      contexto.insatisfaccion.includes(v.id)
    )
      senales.push({
        codigo: "INSATISFACCION",
        nivel: "ALTO",
        fuente: "Valoracion",
        id: v.id,
        fecha: v.fecha,
      });
  const narrativaPendiente =
    mensajes.some((m) => !contexto.revisados.includes(m.id)) ||
    valoraciones.some(
      (v) =>
        v.estrellas <= politica.MaxEstrellasInsatisfaccion &&
        !contexto.valoracionesRevisadas.includes(v.id),
    );
  const riesgo = clasificar(senales, !!uso && !narrativaPendiente);
  return { riesgo, narrativaPendiente };
}
