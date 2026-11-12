import assert from 'node:assert/strict';
import test from 'node:test';
import { loadConfig } from '../lib/config.ts';

test('acepta solo la configuración local soportada', () => {
  assert.deepEqual(loadConfig({ TZ: 'America/Lima', AI_PROVIDER: 'chatgpt' }), {
    TZ: 'America/Lima',
    AI_PROVIDER: 'chatgpt',
  });
});

test('identifica una variable requerida ausente sin revelar otros valores', () => {
  assert.throws(
    () => loadConfig({ TZ: 'America/Lima', SQLSERVER_PASSWORD: 'clave-secreta' }),
    (error) => error.message.includes('AI_PROVIDER') && !error.message.includes('clave-secreta'),
  );
});

test('rechaza proveedor y zona horaria no soportados', () => {
  assert.throws(() => loadConfig({ TZ: 'UTC', AI_PROVIDER: 'minimax' }), /TZ, AI_PROVIDER/);
});
