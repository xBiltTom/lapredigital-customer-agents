import { timingSafeEqual } from 'node:crypto';
import { localDev } from 'eve/channels/auth';
import type { EveAuthFn } from 'eve/channels/eve';
import { loadOwnerConfig } from './config.ts';
import { obtenerDuenoActivo } from './database/identidad.ts';

export function crearAutenticadorDueno(
  config: ReturnType<typeof loadOwnerConfig>,
  buscarDueno = obtenerDuenoActivo,
): EveAuthFn {
  return async (request) => {
    const origin = request.headers.get('origin');
    if (origin) {
      try {
        const url = new URL(origin);
        if (url.protocol !== 'http:' || !['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)) return null;
      } catch { return null; }
    }
    const authorization = request.headers.get('authorization');
    if (!authorization?.startsWith('Bearer ')) return null;
    const candidate = Buffer.from(authorization.slice(7));
    const expected = Buffer.from(config.OWNER_ACCESS_TOKEN);
    if (candidate.length !== expected.length || !timingSafeEqual(candidate, expected)) return null;
    // El token representa solo al dueño configurado en el servidor, nunca un ID del body.
    const dueno = await buscarDueno(config.OWNER_PERSONAL_ID);
    if (!dueno) return null;
    return {
      authenticator: 'dueno-local',
      principalId: `personal:${dueno.personalInternoId}`,
      principalType: 'user',
      attributes: { rol: 'DUEÑO', personalInternoId: String(dueno.personalInternoId) },
      allowAgentInfo: true,
    };
  };
}

export const autenticarDueno: EveAuthFn = async (request) => {
  // Permite compilar sin secretos; una instancia sin configurar deniega las sesiones.
  if (!process.env.OWNER_ACCESS_TOKEN || !process.env.OWNER_PERSONAL_ID) return null;
  return crearAutenticadorDueno(loadOwnerConfig())(request);
};

const verificarTerminalLocal = localDev();
export const autenticarTerminalLocal: EveAuthFn = async (request) => {
  // Eve TUI llama por loopback dentro del contenedor. localDev verifica la conexión
  // real y solo funciona en desarrollo; un token erróneo no tiene esta alternativa.
  if (request.headers.has('authorization') || !await verificarTerminalLocal(request)) return null;
  const { OWNER_PERSONAL_ID } = loadOwnerConfig();
  const dueno = await obtenerDuenoActivo(OWNER_PERSONAL_ID);
  return dueno ? {
    authenticator: 'dueno-local', principalId: `personal:${dueno.personalInternoId}`,
    principalType: 'user', attributes: { rol: 'DUEÑO', personalInternoId: String(dueno.personalInternoId) },
    allowAgentInfo: true,
  } : null;
};
