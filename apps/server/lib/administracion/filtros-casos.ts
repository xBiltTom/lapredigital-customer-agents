import { z } from "zod";

const filtrosCasoSchema = z.object({
  tipo: z.enum(["CONSULTA", "INCIDENCIA"]).optional(),
  ambito: z.enum(["SERVICIO", "ACCESO", "PAGO"]).optional(),
  estado: z.enum(["ABIERTA", "EN_ATENCION", "REABIERTA", "RESUELTA"]).optional(),
});

export function construirFiltroCasos(buscar: string, filtros: unknown = {}) {
  const f = filtrosCasoSchema.parse(filtros);
  const termino = buscar.trim();
  return {
    ...(termino
      ? {
          OR: [
            { Descripcion: { contains: termino } },
            { Resolucion: { contains: termino } },
          ],
        }
      : {}),
    ...(f.tipo ? { Tipo: f.tipo } : {}),
    ...(f.ambito ? { Ambito: f.ambito } : {}),
    ...(f.estado ? { Estado: f.estado } : {}),
  };
}
