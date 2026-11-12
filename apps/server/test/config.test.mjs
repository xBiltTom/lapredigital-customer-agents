import assert from 'node:assert/strict';
import test from 'node:test';
import { loadConfig, loadSqlConfig } from '../lib/config.ts';

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

test('exige usuario SQL propio sin revelar la contraseña', () => {
  const env = {
    SQLSERVER_HOST: 'host.docker.internal', SQLSERVER_PORT: '1433',
    SQLSERVER_DATABASE: 'LaPreDigital_Customers', SQLSERVER_USER: 'sa',
    SQLSERVER_PASSWORD: 'clave-secreta', SQLSERVER_ENCRYPT: 'true',
    SQLSERVER_TRUST_SERVER_CERTIFICATE: 'true',
  };
  assert.throws(
    () => loadSqlConfig(env),
    (error) => error.message.includes('SQLSERVER_USER') && !error.message.includes('clave-secreta'),
  );
  assert.equal(loadSqlConfig({ ...env, SQLSERVER_USER: 'lapredigital_app' }).SQLSERVER_PORT, 1433);
});
