import { defineTool } from "eve/tools";
import { z } from "zod";
import { consultarBase } from "../../lib/servicios/consultas.ts";
import { jsonSeguro } from "../../lib/academico/diagnostico.ts";
import {
  herramientaPorModo,
  exigirHerramienta,
} from "../../lib/seguridad/alcance-herramientas.ts";
export const herramienta = defineTool({
  description:
    "Detalle del alumno de esta conversación: PAGOS, SERVICIO, ACTIVIDADES, EVALUACIONES y VALORACIONES, con filtros y páginas. Para «último pago» usa PAGOS, tipo COBRO, estado CONFIRMADO, orden RECIENTE y limite 1. ACTIVIDADES y SERVICIO permiten fechas futuras. Para resumen académico usa consultar_rendimiento; para casos gestionar_caso. Solo lectura; sin SQL libre.",
  inputSchema: z.object({
    recurso: z.enum([
      "PAGOS",
      "SERVICIO",
      "ACTIVIDADES",
      "EVALUACIONES",
      "VALORACIONES",
    ]),
    estudianteId: z.number().int().positive().max(2147483647).optional(),
    estado: z.string().max(30).optional(),
    tipo: z.string().max(100).optional(),
    buscar: z.string().trim().max(150).optional(),
    desde: z.iso.date().optional(),
    hasta: z.iso.date().optional(),
    orden: z.enum(["RECIENTE", "ANTIGUO", "IMPORTE_MAYOR"]).default("RECIENTE"),
    limite: z.number().int().min(1).max(50).default(10),
    pagina: z.number().int().min(1).max(10000).default(1),
  }),
  async execute(b, ctx) {
    exigirHerramienta(ctx.session.auth.current, "registros");
    return jsonSeguro(await consultarBase(ctx.session.auth.current, b));
  },
});
export default herramientaPorModo("registros", herramienta);
