import { defineChannel, GET, POST } from 'eve/channels';
import { z } from 'zod';
import { dueno } from '../../lib/seguridad/identidad.ts';
import {
  listarHilos,
  leerHilo,
  responderManual,
} from '../../lib/servicios/mensajeria.ts';
const id = z.coerce.number().int().positive().max(2147483647);
const hilo = z.object({
  e: id,
  c: id,
  rol: z.enum(['ESTUDIANTE', 'APODERADO']),
});
const json = (data: unknown, status = 200) =>
  Response.json(data, { status, headers: { 'cache-control': 'no-store' } });
const error = (e: unknown) =>
  json(
    {
      error:
        e instanceof z.ZodError
          ? 'Datos inválidos'
          : e instanceof Error
            ? e.message
            : 'No se pudo completar la operación',
    },
    409,
  );
function parametros(params: Record<string, string>) {
  const h = hilo.parse(params);
  return { EstudianteId: h.e, ContactoId: h.c, Rol: h.rol };
}
export default defineChannel({
  routes: [
    GET('/api/mensajeria', async (r) => {
      if (!(await dueno(r))) return json({ error: 'Acceso requerido' }, 401);
      try {
        return json(await listarHilos());
      } catch (e) {
        return error(e);
      }
    }),
    GET('/api/mensajeria/:e/:c/:rol', async (r, { params }) => {
      if (!(await dueno(r))) return json({ error: 'Acceso requerido' }, 401);
      try {
        const antes = new URL(r.url).searchParams.get('antes');
        return json(
          await leerHilo(
            parametros(params),
            antes ? id.parse(antes) : undefined,
          ),
        );
      } catch (e) {
        return error(e);
      }
    }),
    POST('/api/mensajeria/:e/:c/:rol', async (r, { params }) => {
      const owner = await dueno(r);
      if (!owner) return json({ error: 'Acceso requerido' }, 401);
      try {
        const b = z
          .object({ texto: z.string().trim().min(1).max(2000) })
          .parse(await r.json());
        return json(
          await responderManual(owner.id, parametros(params), b.texto),
          201,
        );
      } catch (e) {
        return error(e);
      }
    }),
  ],
});
