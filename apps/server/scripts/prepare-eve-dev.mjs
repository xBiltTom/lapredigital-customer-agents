import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';

// Eve rc.10: las reentregas internas del World local omiten la credencial
// que sí añade el host de desarrollo. Conservar la validación del receptor.
const require = createRequire(import.meta.url);
const root = dirname(require.resolve('eve/package.json'));
const file = join(root, 'dist/src/compiled/@workflow/world-local/index.js');
const marker = '/* lapredigital-eve-dev-delivery */';
const source = readFileSync(file, 'utf8');
if (!source.includes(marker)) {
  const version = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8')).version;
  const before = 'f={...S,"content-type":`application/json`';
  if (version !== '1.0.0-rc.10' || source.split(before).length !== 2) {
    throw new Error('Revisar compatibilidad del ajuste local de Eve antes de arrancar.');
  }
  const after = 'f={...S,...(process.env.EVE_DEV_WORKFLOW_TRANSPORT_SECRET?{"x-eve-dev-workflow-delivery":process.env.EVE_DEV_WORKFLOW_TRANSPORT_SECRET}:{}),'+marker+'"content-type":`application/json`';
  writeFileSync(file, source.replace(before, after));
}
