// Recuperación local de referencias antiguas de Eve rc.10. No imprime mensajes ni credenciales.
// Lee metadatos del runtime; nunca interpreta direcciones escritas dentro de un mensaje.
import { readdir, readFile } from 'node:fs/promises';
import { zstdDecompressSync } from 'node:zlib';
import path from 'node:path';
import { registrarSesionChat } from '../lib/conversaciones/archivo.ts';
const runs = path.resolve('.eve/.workflow-data/runs');
let total = 0;
for (const file of (await readdir(runs)).sort()) {
  const run = JSON.parse(await readFile(path.join(runs, file), 'utf8'));
  if (
    run.attributes?.['$eve.type'] !== 'session' ||
    run.input?.__type !== 'Uint8Array'
  )
    continue;
  let bytes = Buffer.from(run.input.data, 'base64');
  if (bytes.subarray(0, 4).toString() === 'zstd')
    bytes = zstdDecompressSync(bytes.subarray(4));
  if (bytes.subarray(0, 4).toString() !== 'devl')
    throw new Error(
      'Formato de Eve distinto; revisar recuperación antes de continuar.',
    );
  const values = JSON.parse(bytes.subarray(4).toString());
  const input = values[values[0][0]],
    context = values[input.serializedContext];
  const token = values[context?.['eve.continuationToken']];
  if (typeof token !== 'string') continue;
  const match =
    /^panel:(dueno:[1-9]\d*:(?:global|alumno:[1-9]\d*(?::chat:principal)?))$/.exec(
      token,
    );
  if (!match) continue;
  const direccion =
    match[1].includes(':alumno:') && !match[1].endsWith(':chat:principal')
      ? match[1] + ':chat:principal'
      : match[1];
  await registrarSesionChat(direccion, run.runId);
  total++;
}
console.log(
  `Referencias recuperadas: ${total}. Sin modificar sesiones ni mensajes.`,
);
