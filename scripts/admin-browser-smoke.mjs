// Navegación real de las vistas administrativas, sin enviar mensajes al modelo ni escribir datos.
import { chromium } from '@playwright/test';
import { readFile, mkdir } from 'node:fs/promises';
import assert from 'node:assert/strict';
const env = Object.fromEntries(
  (await readFile('.env', 'utf8'))
    .split('\n')
    .filter((l) => l.includes('='))
    .map((l) => l.split(/=(.*)/s).slice(0, 2)),
);
const browser = await chromium.launch({
  headless: true,
  args: ['--no-sandbox'],
});
try {
  const page = await browser.newPage({
      viewport: { width: 1440, height: 1000 },
    }),
    errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  await page.goto('http://127.0.0.1:5173/#token=' + env.OWNER_ACCESS_TOKEN);
  await page.locator('.workspace-nav').waitFor();
  for (const name of [
    'Estudiantes',
    'Apoderados',
    'Cursos y temario',
    'Recursos',
    'Rutas de estudio',
    'Consultas e incidencias',
    'Planes y servicios',
  ]) {
    await page
      .locator('.workspace-nav button')
      .filter({ hasText: name })
      .first()
      .click();
    await page.getByRole('heading', { name, exact: true }).waitFor();
    await page.getByText('Cargando registros…').waitFor({ state: 'hidden' });
    assert.equal(
      await page.locator('.admin-error').count(),
      0,
      name + ' sin errores API',
    );
    if (name === 'Estudiantes') {
      await page
        .getByRole('button', { name: 'Editar', exact: true })
        .first()
        .click();
      await page.getByRole('dialog').waitFor();
      assert.ok(await page.getByLabel('Nombre completo').inputValue());
      await page.getByRole('button', { name: 'Cancelar', exact: true }).click();
    }
    if (name === 'Cursos y temario') {
      await page.locator('button.admin-card').first().click();
      await page
        .getByRole('heading', { name: 'Contenido del curso' })
        .waitFor();
    }
  }
  await mkdir('tmp', { recursive: true });
  await page.screenshot({ path: 'tmp/admin-servicios.png', fullPage: true });
  await page
    .locator('.workspace-nav button')
    .filter({ hasText: 'Agente IA' })
    .click();
  await page
    .getByRole('heading', { name: 'Centro de acompañamiento' })
    .waitFor();
  await page
    .locator('.workspace-nav button')
    .filter({ hasText: 'Dashboard' })
    .click();
  await page
    .locator('.dashboard')
    .waitFor()
    .catch(() =>
      page
        .getByRole('heading', { name: /Resumen|Dashboard|panorama/i })
        .first()
        .waitFor(),
    );
  assert.deepEqual(errors, []);
  console.log(
    'OK navegador: siete vistas, formulario, temario, Agente IA y Dashboard separados; sin errores React.',
  );
} finally {
  await browser.close();
}
