import assert from 'node:assert/strict';
import test from 'node:test';
import { crearAutenticadorDueno } from '../lib/seguridad/auth.ts';

const token = 'token-de-prueba-sin-valor-real-000000';
const config = { OWNER_PERSONAL_ID: 7, OWNER_ACCESS_TOKEN: token };
const request = (authorization, origin, body = {}) => new Request('http://localhost:3000/eve/v1/session', {
  method: 'POST', headers: { ...(authorization && { authorization }), ...(origin && { origin }) },
  body: JSON.stringify(body),
});

test('sin token o con token incorrecto no consulta SQL ni autentica', async () => {
  const auth = crearAutenticadorDueno(config, async () => { assert.fail('No debe consultar SQL'); });
  assert.equal(await auth(request()), null);
  assert.equal(await auth(request('Bearer incorrecto')), null);
  assert.equal(await auth(request(`Bearer ${token.slice(0, -1)}X`)), null);
});

test('el dueño verificado proviene del servidor y no del cuerpo de la petición', async () => {
  const auth = crearAutenticadorDueno(config, async (id) => {
    assert.equal(id, 7);
    return { personalInternoId: id };
  });
  const result = await auth(request(`Bearer ${token}`, 'http://localhost:5173', { contactoId: 99, personalInternoId: 99 }));
  assert.equal(result.principalId, 'personal:7');
  assert.equal(result.attributes.personalInternoId, '7');
  assert.equal(result.allowAgentInfo, true);
});

test('dueño inactivo y origen externo no reciben acceso', async () => {
  const auth = crearAutenticadorDueno(config, async () => null);
  assert.equal(await auth(request(`Bearer ${token}`)), null);
  const externo = crearAutenticadorDueno(config, async () => { assert.fail('Origen externo no debe consultar SQL'); });
  assert.equal(await externo(request(`Bearer ${token}`, 'https://ejemplo.com')), null);
  assert.equal(await externo(request(`Bearer ${token}`, 'null')), null);
});
