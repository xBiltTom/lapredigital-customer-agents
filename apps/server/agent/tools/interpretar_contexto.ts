import { defineTool } from "eve/tools";
import { z } from "zod";
import {
  guardarContexto,
  jsonSeguro,
} from "../../lib/academico/diagnostico.ts";
import {
  herramientaPorModo,
  exigirHerramienta,
  autorizarAlumno,
} from "../../lib/seguridad/alcance-herramientas.ts";
import { proyectarRiesgo } from "../../lib/academico/rendimiento.ts";
const ids = z.array(z.number().int().positive()).max(200);
export const herramienta = defineTool({
  description:
    "Registra interpretación de evidencias ya consultadas, ligadas a su huella. No modifica SQL ni concede autorizaciones.",
  inputSchema: z.object({
    estudianteId: z.number().int().positive().optional(),
    huella: z.string().length(64),
    revisados: ids,
    valoracionesRevisadas: ids,
    cancelacion: ids,
    noContacto: ids,
    insatisfaccion: ids,
  }),
  async execute({ huella, estudianteId: solicitado, ...contexto }, ctx) {
    const auth = ctx.session.auth.current;
    exigirHerramienta(auth, "dueno");
    const { owner, estudianteId } = await autorizarAlumno(auth, solicitado);
    return jsonSeguro(
      proyectarRiesgo(
        await guardarContexto(owner, estudianteId, huella, contexto),
      ),
    );
  },
});
export default herramientaPorModo("dueno", herramienta);
