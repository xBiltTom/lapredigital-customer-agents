import { defineTool } from "eve/tools";
import { z } from "zod";
import { proponer, tipos } from "../../lib/academico/intervenciones.ts";
import {
  herramientaPorModo,
  exigirHerramienta,
  autorizarAlumno,
} from "../../lib/seguridad/alcance-herramientas.ts";
export const herramienta = defineTool({
  description:
    "Registra PROPUESTA pendiente de aprobación humana. Nunca aprueba, ejecuta ni envía. Revalida reglas y evita duplicados.",
  inputSchema: z.object({
    estudianteId: z.number().int().positive().optional(),
    tipo: z.enum(tipos),
    recomendacion: z.string().min(10).max(1500),
  }),
  async execute({ tipo, recomendacion, estudianteId: solicitado }, ctx) {
    exigirHerramienta(ctx.session.auth.current, "dueno");
    const { owner, estudianteId } = await autorizarAlumno(
      ctx.session.auth.current,
      solicitado,
    );
    return proponer(owner, estudianteId, tipo, recomendacion);
  },
});
export default herramientaPorModo("dueno", herramienta);
