import { defineTool } from 'eve/tools';
import { z } from 'zod';
import {
  guardarContexto,
  jsonSeguro,
} from '../../lib/academico/diagnostico.ts';
import { identidadHerramienta } from '../../lib/seguridad/identidad.ts';
const ids = z.array(z.number().int().positive()).max(200);
export default defineTool({
  description:
    'Registra interpretación de evidencias ya consultadas, ligadas a su huella. No modifica SQL ni concede autorizaciones.',
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
    const { id, estudianteId } =
      auth?.attributes?.modo === 'global' && solicitado
        ? {
            id: Number(auth.attributes.personalInternoId),
            estudianteId: solicitado,
          }
        : identidadHerramienta(auth);
    return jsonSeguro(
      await guardarContexto(id, estudianteId, huella, contexto),
    );
  },
});
