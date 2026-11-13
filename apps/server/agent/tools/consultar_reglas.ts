import { defineTool } from 'eve/tools';
import { z } from 'zod';
import {
  politicaActual,
  politicaVersion,
} from '../../lib/servicios/politicas.ts';
import { obtenerDuenoActivo } from '../../lib/database/identidad.ts';
export default defineTool({
  description:
    'Solo dueño: consulta la versión actual o una versión histórica y sus parámetros de riesgo de abandono de CUSTOMERS. No modifica reglas; las publica el dueño en la aplicación.',
  inputSchema: z.object({ version: z.string().min(1).max(20).optional() }),
  async execute({ version }, ctx) {
    const auth = ctx.session.auth.current,
      id = Number(auth?.attributes?.personalInternoId);
    if (
      auth?.authenticator !== 'dueno-local' ||
      auth.attributes?.modo === 'participante' ||
      !Number.isSafeInteger(id) ||
      !(await obtenerDuenoActivo(id))
    )
      throw new Error('Herramienta exclusiva del dueño');
    return version ? politicaVersion(version) : politicaActual();
  },
});
