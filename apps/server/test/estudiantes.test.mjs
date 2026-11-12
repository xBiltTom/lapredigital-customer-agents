import assert from 'node:assert/strict';
import test from 'node:test';
import {
  normalizarPagina,
  TAMANO_PAGINA_MAX,
  TAMANO_PAGINA_PREDETERMINADO,
} from '../lib/database/estudiantes.ts';

test('usa la primera página y el tamaño predeterminado', () => {
  assert.deepEqual(normalizarPagina(), {
    pagina: 1,
    tamano: TAMANO_PAGINA_PREDETERMINADO,
    offset: 0,
  });
});

test('calcula el desplazamiento de una página válida', () => {
  assert.deepEqual(normalizarPagina({ pagina: 3, tamano: 10 }), {
    pagina: 3,
    tamano: 10,
    offset: 20,
  });
});

test('rechaza páginas y tamaños fuera de rango', () => {
  assert.throws(() => normalizarPagina({ pagina: 0 }), /página/);
  assert.throws(() => normalizarPagina({ pagina: 1.5 }), /página/);
  assert.throws(() => normalizarPagina({ tamano: 0 }), /tamaño/);
  assert.throws(() => normalizarPagina({ tamano: TAMANO_PAGINA_MAX + 1 }), /tamaño/);
});
