import { defineTool } from "eve/tools";
import { z } from "zod";
import {
  herramientaPorModo,
  autorizarAlumno,
} from "../../lib/seguridad/alcance-herramientas.ts";
import { diagnostico, jsonSeguro } from "../../lib/academico/diagnostico.ts";
import { proyectarRendimiento } from "../../lib/academico/rendimiento.ts";

export const herramienta = defineTool({
  description:
    "Responde «mi rendimiento», «cómo voy» o el avance de un alumno: resultados recientes, mejora comparable en pp, cumplimiento con ventana, ruta, dificultades y actividad. Sin evaluaciones no significa falta de acceso; sin pareja comparable muestra los resultados individuales. El participante no recibe riesgo ni notas internas. Para registros adicionales usa consultar_registros.",
  inputSchema: z.object({
    estudianteId: z.number().int().positive().optional(),
  }),
  async execute({ estudianteId }, ctx) {
    const actor = await autorizarAlumno(ctx.session.auth.current, estudianteId);
    return jsonSeguro(
      proyectarRendimiento(
        await diagnostico(actor.owner, actor.estudianteId),
        String(actor.a.rol),
      ),
    );
  },
});
export default herramientaPorModo("lectura", herramienta);
