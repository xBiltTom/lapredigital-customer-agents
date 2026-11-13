import { defineChannel, GET, POST } from 'eve/channels';
import { z } from 'zod';
import { dueno } from '../../lib/seguridad/identidad.ts';
import {
  politicaActual,
  historialPoliticas,
  publicarPolitica,
} from '../../lib/servicios/politicas.ts';
const json = (v: unknown, status = 200) =>
  Response.json(v, { status, headers: { 'cache-control': 'no-store' } });
const error = (e: unknown) =>
  json(
    {
      error:
        e instanceof z.ZodError
          ? e.issues.map((i) => i.message).join('. ')
          : e instanceof Error
            ? e.message
            : 'Operación fallida',
    },
    409,
  );
export default defineChannel({
  routes: [
    GET('/api/reglas', async (r) => {
      if (!(await dueno(r))) return json({ error: 'Acceso requerido' }, 401);
      try {
        const [actual, historial] = await Promise.all([
          politicaActual(),
          historialPoliticas(),
        ]);
        return json({ actual, historial });
      } catch (e) {
        return error(e);
      }
    }),
    POST('/api/reglas', async (r) => {
      const owner = await dueno(r);
      if (!owner) return json({ error: 'Acceso requerido' }, 401);
      try {
        return json(await publicarPolitica(owner.id, await r.json()), 201);
      } catch (e) {
        return error(e);
      }
    }),
  ],
});
