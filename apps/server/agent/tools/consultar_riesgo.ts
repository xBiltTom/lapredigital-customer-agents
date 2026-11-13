import { defineTool } from "eve/tools";
import { z } from "zod";
import {
  herramientaPorModo,
  exigirHerramienta,
  autorizarAlumno,
} from "../../lib/seguridad/alcance-herramientas.ts";
import { diagnostico, jsonSeguro } from "../../lib/academico/diagnostico.ts";
import { proyectarRiesgo } from "../../lib/academico/rendimiento.ts";

export const herramienta = defineTool({
  description:
    "Solo dueño: diagnóstico interno del riesgo de abandono, señales, reglas vigentes, evidencias y seguimiento previo. En global indica estudianteId; en individual se fija por sesión. Si narrativaPendiente, usa interpretar_contexto con la huella/IDs recibidos. Para preparación y notas usa consultar_rendimiento.",
  inputSchema: z.object({
    estudianteId: z.number().int().positive().optional(),
  }),
  async execute({ estudianteId }, ctx) {
    exigirHerramienta(ctx.session.auth.current, "dueno");
    const actor = await autorizarAlumno(ctx.session.auth.current, estudianteId);
    return jsonSeguro(
      proyectarRiesgo(await diagnostico(actor.owner, actor.estudianteId)),
    );
  },
});
export default herramientaPorModo("dueno", herramienta);
