import assert from 'node:assert/strict';
import test from 'node:test';
import { construirFiltroCasos } from '../lib/administracion/filtros-casos.ts';

test('combina búsqueda y filtros para tipo, ámbito y estado', () => {
  assert.deepEqual(
    construirFiltroCasos('  acceso  ', {
      tipo: 'INCIDENCIA',
      ambito: 'ACCESO',
      estado: 'REABIERTA',
    }),
    {
      OR: [
        { Descripcion: { contains: 'acceso' } },
        { Resolucion: { contains: 'acceso' } },
      ],
      Tipo: 'INCIDENCIA',
      Ambito: 'ACCESO',
      Estado: 'REABIERTA',
    },
  );
});

test('permite buscar casos económicos históricos y omitir filtros', () => {
  assert.deepEqual(construirFiltroCasos('', { ambito: 'PAGO' }), {
    Ambito: 'PAGO',
  });
  assert.deepEqual(construirFiltroCasos('   '), {});
});

test('rechaza filtros fuera del catálogo de casos', () => {
  assert.throws(() => construirFiltroCasos('', { estado: 'PENDIENTE' }));
  assert.throws(() => construirFiltroCasos('', { tipo: 'RECLAMO' }));
});
