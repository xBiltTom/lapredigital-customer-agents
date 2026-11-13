import { defineChannel, GET } from 'eve/channels';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
const root = process.env.WEB_DIST_DIR ?? '/workspace/apps/web/.dist';
export default defineChannel({
  routes: [
    GET('/', async () => {
      try {
        return new Response(
          await readFile(path.join(root, 'index.html'), 'utf8'),
          {
            headers: {
              'content-type': 'text/html; charset=utf-8',
              'cache-control': 'no-cache',
            },
          },
        );
      } catch {
        return new Response(
          'Panel no compilado: ejecuta npm run build:web dentro de Docker.',
          { status: 503 },
        );
      }
    }),
    GET('/assets/:file', async (_request, { params }) => {
      if (!/^[a-zA-Z0-9._-]+\.(js|css|svg)$/.test(params.file))
        return new Response('No encontrado', { status: 404 });
      try {
        const mime = params.file.endsWith('.css')
          ? 'text/css'
          : params.file.endsWith('.svg')
            ? 'image/svg+xml'
            : 'text/javascript';
        return new Response(
          await readFile(path.join(root, 'assets', params.file), 'utf8'),
          {
            headers: {
              'content-type': mime + '; charset=utf-8',
              'cache-control': 'public,max-age=31536000,immutable',
            },
          },
        );
      } catch {
        return new Response('No encontrado', { status: 404 });
      }
    }),
  ],
});
