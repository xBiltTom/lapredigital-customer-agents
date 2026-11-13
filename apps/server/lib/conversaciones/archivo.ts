import { appendFile, mkdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import type { Session, SessionReader } from 'eve/sessions';
import { historialChat } from './historial.ts';

// Índice propio, separado del vínculo temporal de Eve. Vive en su volumen privado.
export const carpetaHistorial = () =>
  path.resolve(process.env.CHAT_HISTORY_DIR ?? '.eve/historial-chats');
const archivo = () => path.join(carpetaHistorial(), 'sesiones.ndjson');
type Referencia = { direccion: string; sesionId: string };
const direccionValida =
  /^dueno:[1-9]\d*:(?:global|alumno:[1-9]\d*:chat:principal)$/;
export async function referenciasChat(): Promise<Referencia[]> {
  let texto: string;
  try {
    texto = await readFile(archivo(), 'utf8');
  } catch (e) {
    if ((e as NodeJS.ErrnoException).code === 'ENOENT') return [];
    throw e;
  }
  return texto
    .split('\n')
    .filter(Boolean)
    .map((linea) => JSON.parse(linea))
    .filter(
      (r: Referencia) =>
        direccionValida.test(r.direccion) &&
        /^wrun_[A-Z0-9]+$/.test(r.sesionId),
    );
}
export async function registrarSesionChat(direccion: string, sesionId: string) {
  if (!direccionValida.test(direccion) || !/^wrun_[A-Z0-9]+$/.test(sesionId))
    throw new Error('Referencia de conversación inválida');
  if (
    (await referenciasChat()).some(
      (r) => r.direccion === direccion && r.sesionId === sesionId,
    )
  )
    return;
  await mkdir(carpetaHistorial(), { recursive: true, mode: 0o700 });
  await appendFile(archivo(), JSON.stringify({ direccion, sesionId }) + '\n', {
    mode: 0o600,
  });
}
// attachSession permite leer también sesiones finalizadas, sin reanudarlas ni invocar al modelo.
export async function historialDireccion(
  direccion: string,
  activa: SessionReader | undefined | null,
  attach: (id: string) => Session,
) {
  if (activa) await registrarSesionChat(direccion, activa.id);
  const ids = [
    ...new Set(
      (await referenciasChat())
        .filter((r) => r.direccion === direccion)
        .map((r) => r.sesionId),
    ),
  ];
  const conversaciones = await Promise.all(
    ids.map((id) => historialChat(activa?.id === id ? activa : attach(id))),
  );
  return {
    mensajes: conversaciones.flatMap((c) => c.mensajes),
    sesionId: activa?.id ?? null,
  };
}
