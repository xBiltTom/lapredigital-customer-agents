// Flujo de reportes y resolución: escrituras exclusivamente en MvpTest.
import assert from 'node:assert/strict';
import { getPrisma } from '../lib/database/prisma.ts';
import { closePool } from '../lib/database/pool.ts';
import {
  tramitarReporte,
  detalleCaso,
  comunicarResolucion,
} from '../lib/servicios/casos.ts';
import { atenderCaso } from '../lib/administracion/academico.ts';
assert.equal(process.env.SQLSERVER_DATABASE, 'LaPreDigital_Customers_MvpTest');
const p = getPrisma();
try {
  const alumno = await p.estudiante.findUniqueOrThrow({
    where: { Codigo: 'C001' },
  });
  const tutor = await p.estudiante.findUniqueOrThrow({
    where: { Codigo: 'C005' },
    include: { apoderado: true },
  });
  async function mensaje(e, c, rol) {
    return p.mensajeCanalLocal.create({
      data: {
        EstudianteId: e,
        ContactoId: c,
        Rol: rol,
        Canal: 'MENSAJERIA',
        Direccion: 'ENTRANTE',
        Contenido: 'No puedo abrir un material de mi preparación',
      },
    });
  }
  const m = await mensaje(alumno.EstudianteId, alumno.ContactoId, 'ESTUDIANTE');
  const reporte = {
    estudianteId: alumno.EstudianteId,
    contactoId: alumno.ContactoId,
    rol: 'ESTUDIANTE',
    mensajeId: m.MensajeLocalId,
    decision: 'REGISTRAR',
    descripcion: 'Fallo al abrir material académico',
    ambito: 'ACCESO',
  };
  const r = await tramitarReporte(reporte);
  assert.ok(r.casoId);
  assert.equal((await tramitarReporte(reporte)).casoId, r.casoId);
  const seguimiento=await mensaje(alumno.EstudianteId,alumno.ContactoId,'ESTUDIANTE');
  assert.equal((await tramitarReporte({...reporte,mensajeId:seguimiento.MensajeLocalId,casoId:r.casoId})).casoId,r.casoId);
  await assert.rejects(
    tramitarReporte({ ...reporte, estudianteId: tutor.EstudianteId }),
  );
  const g = await mensaje(
    tutor.EstudianteId,
    tutor.apoderado.ContactoId,
    'APODERADO',
  );
  const pregunta = {
    estudianteId: tutor.EstudianteId,
    contactoId: tutor.apoderado.ContactoId,
    rol: 'APODERADO',
    mensajeId: g.MensajeLocalId,
    decision: 'DERIVAR',
    descripcion:
      'El apoderado solicita revisión del dueño antes de registrar el fallo',
    ambito: 'ACCESO',
  };
  const q = await tramitarReporte(pregunta);
  assert.ok(q.consultaId);
  assert.equal((await tramitarReporte(pregunta)).consultaId, q.consultaId);
  assert.equal(
    (await tramitarReporte({ ...pregunta, decision: 'REGISTRAR' }))
      .pendienteDueno,
    true,
  );
  const registrado = await tramitarReporte({
    ...pregunta,
    decision: 'REGISTRAR',
    respuestaDueno: true,
  });
  assert.ok(registrado.casoId);
  const detalle = await detalleCaso(registrado.casoId);
  assert.equal(detalle.origenes[0].Rol, 'APODERADO');
  const apertura = detalle.caso.FechaAperturaOriginal.toISOString();
  await atenderCaso(1, registrado.casoId, {
    Estado: 'EN_ATENCION',
    EstadoAnterior: 'ABIERTA',
    Detalle: 'Se revisa el recurso y los permisos',
  });
  await atenderCaso(1, registrado.casoId, {
    Estado: 'RESUELTA',
    EstadoAnterior: 'EN_ATENCION',
    Detalle: 'Se corrigió el enlace y se verificó el acceso al material',
  });
  await assert.rejects(
    atenderCaso(1, registrado.casoId, {
      Estado: 'EN_ATENCION',
      EstadoAnterior: 'ABIERTA',
      Detalle: 'Acción de una ventana obsoleta',
    }),
    /cambió/,
  );
  const salida = await comunicarResolucion(
    1,
    registrado.casoId,
    g.MensajeLocalId,
  );
  assert.equal(salida.ContactoId, tutor.apoderado.ContactoId);
  assert.equal(salida.FechaEntrega, null);
  await assert.rejects(
    comunicarResolucion(1, registrado.casoId, m.MensajeLocalId),
  );
  await atenderCaso(1, registrado.casoId, {
    Estado: 'REABIERTA',
    EstadoAnterior: 'RESUELTA',
    Detalle: 'El apoderado informa que el problema persiste',
  });
  const final = await detalleCaso(registrado.casoId);
  assert.equal(final.caso.FechaAperturaOriginal.toISOString(), apertura);
  assert.equal(final.caso.FechaResolucionDefinitiva, null);
  assert.equal(final.eventos.length, 4);
  console.log(
    'OK: reporte estudiante/apoderado, deduplicación, derivación y decisión, origen, resolución, comunicación correcta y reapertura. Solo MvpTest.',
  );
} finally {
  await p.$disconnect();
  await closePool();
}
