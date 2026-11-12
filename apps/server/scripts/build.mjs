import { cp, mkdir, rm } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const app = fileURLToPath(new URL('../', import.meta.url));
const packaged = path.join(app, '.eve/packaged');
await mkdir(packaged, { recursive: true });
// Fuente mínima para Eve. No copiar .env, credenciales ni el estado de sesiones.
// Eliminar fuentes retiradas evita que una tool borrada sobreviva al siguiente build.
for (const name of ['agent', 'lib', 'package.json', 'tsconfig.json']) {
  await rm(path.join(packaged, name), { recursive: true, force: true });
  await cp(path.join(app, name), path.join(packaged, name), { recursive: true });
}
// El staging de Eve y .output quedan en el mismo volumen Docker: rename no cruza FS.
const result = spawnSync('eve', ['build'], { cwd: packaged, stdio: 'inherit' });
if (result.error) throw result.error;
process.exitCode = result.status ?? 1;
