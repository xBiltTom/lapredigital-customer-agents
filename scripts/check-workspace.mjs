import assert from 'node:assert/strict';
import { access, readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
assert.equal(
  Number(process.versions.node.split('.')[0]),
  24,
  'El proyecto requiere Node 24. Ejecuta ./scripts/dev npm run check.',
);
const required = [
  'README.md', 'package.json', '.nvmrc', '.env.example', '.gitignore',
  'database/README.md', 'database/01_crear_customers.sql',
  'database/02_poblar_customers.sql', 'database/03_pruebas_customers.sql',
  'database/04_consultas_customers.sql',
  'docs/reference/documento_InteligenciaNegocios.pdf',
  'docs/database/REVISION_CUSTOMERS.md', 'apps/README.md',
  'packages/README.md', 'infra/README.md',
  'compose.yaml', 'infra/docker/Node.Dockerfile', 'scripts/dev', '.dockerignore',
  'package-lock.json', 'apps/server/package.json', 'apps/server/tsconfig.json',
  'apps/server/README.md', 'apps/server/agent/agent.ts',
  'apps/server/agent/instructions.md', 'apps/server/agent/channels/eve.ts',
  'apps/server/lib/auth.ts', 'infra/sql/app-read-permissions.sql',
  'scripts/provision-sql-app', 'scripts/chat-local',
  'apps/web/package.json', 'apps/web/src/App.tsx', 'apps/web/README.md',
  'compose.packaged.yaml', 'scripts/start', 'scripts/open-panel',
];
for (const name of required) await access(path.join(root, name));
const pkg = JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8'));
assert.equal(pkg.private, true, 'El workspace debe ser privado en npm.');
assert.equal((await readFile(path.join(root, '.nvmrc'), 'utf8')).trim(), '24');
assert.deepEqual(pkg.workspaces, ['apps/*', 'packages/*']);
assert.equal((await readFile(path.join(root, 'docs/reference/documento_InteligenciaNegocios.pdf'))).subarray(0, 5).toString(), '%PDF-');

async function markdownFiles(dir) {
  const result = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    if (['.git', 'node_modules', '.eve', '.output', 'dist', '.dist', 'coverage'].includes(entry.name)) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) result.push(...await markdownFiles(full));
    else if (entry.name.endsWith('.md')) result.push(full);
  }
  return result;
}
let checkedLinks = 0;
for (const file of await markdownFiles(root)) {
  const body = await readFile(file, 'utf8');
  for (const match of body.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)) {
    const target = match[1].split('#')[0];
    if (!target || /^[a-z][a-z0-9+.-]*:/i.test(target)) continue;
    const full = path.resolve(path.dirname(file), decodeURIComponent(target));
    assert.ok(full.startsWith(root), `Enlace fuera del repositorio en ${file}: ${target}`);
    await access(full);
    checkedLinks += 1;
  }
}
console.log(`Workspace valido: ${required.length} rutas requeridas y ${checkedLinks} enlaces locales.`);
console.log('Esta comprobacion no ejecuta SQL ni valida el funcionamiento del agente.');
