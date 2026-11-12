import assert from 'node:assert/strict';
import { getPool, closePool } from '../lib/database/pool.ts';
import {
  listarEstudiantes,
  obtenerFichaEstudiante,
  TAMANO_PAGINA_MAX,
} from '../lib/database/estudiantes.ts';

try {
  const pool = await getPool();
  const { recordset } = await pool.request().query(`
    SELECT e.Codigo, e.EstudianteId, e.ContactoId,
           ap.ContactoId AS ApoderadoContactoId
    FROM dbo.Estudiante e
    LEFT JOIN dbo.Apoderado ap ON ap.ApoderadoId = e.ApoderadoId
    WHERE e.Codigo IN ('C001','C003','C005','C006','C011','C013')`);
  const porCodigo = new Map(recordset.map((row) => [row.Codigo, row]));
  const identidad = (codigo) => ({ contactoId: porCodigo.get(codigo).ContactoId });

  const maria = { contactoId: porCodigo.get('C003').ApoderadoContactoId };
  assert.equal(porCodigo.get('C005').ApoderadoContactoId, maria.contactoId,
    'C003 y C005 deben compartir apoderado para probar el listado sin duplicados.');

  const pagina1 = await listarEstudiantes(maria, { pagina: 1, tamano: 1 });
  const pagina2 = await listarEstudiantes(maria, { pagina: 2, tamano: 1 });
  assert.equal(pagina1.total, 2, 'El apoderado compartido debe ver exactamente dos estudiantes.');
  assert.equal(pagina1.paginas, 2);
  assert.equal(pagina1.items.length, 1);
  assert.equal(pagina2.items.length, 1);
  assert.notEqual(pagina1.items[0].estudianteId, pagina2.items[0].estudianteId);
  assert.deepEqual(
    [pagina1.items[0].codigo, pagina2.items[0].codigo].sort(),
    ['C003', 'C005'],
  );
  await assert.rejects(() => listarEstudiantes(maria, { pagina: 0 }), /página/);
  await assert.rejects(
    () => listarEstudiantes(maria, { tamano: TAMANO_PAGINA_MAX + 1 }),
    /tamaño/,
  );

  const fichaC006 = await obtenerFichaEstudiante(identidad('C006'), porCodigo.get('C006').EstudianteId);
  assert.ok(fichaC006, 'C006 debe tener ficha.');
  assert.equal(fichaC006.estudiante.etapaActual, 'CUSTOMER');
  assert.ok(fichaC006.servicioActual, 'C006 debe tener servicio vigente por beca.');
  assert.equal(fichaC006.servicioActual.becaPorcentaje, 100);
  assert.equal(fichaC006.servicioActual.importeExigiblePEN, 0);
  assert.equal(fichaC006.servicioActual.cobrosConfirmados, 0);
  assert.equal(fichaC006.historial.length, 0);
  assert.ok(fichaC006.prestaciones.length > 0);

  const fichaC011 = await obtenerFichaEstudiante(identidad('C011'), porCodigo.get('C011').EstudianteId);
  assert.ok(fichaC011, 'C011 debe tener ficha.');
  assert.ok(fichaC011.servicioActual, 'C011 debe tener servicio reactivado vigente.');
  assert.equal(fichaC011.servicioActual.tipo, 'REACTIVACION');
  assert.equal(fichaC011.servicioActual.estadoAcceso, 'HABILITADO');
  assert.equal(fichaC011.historial.length, 1, 'C011 debe conservar su episodio anterior.');
  assert.equal(fichaC011.historial[0].estadoAcceso, 'FINALIZADO');
  assert.equal(fichaC011.historial[0].estadoSuscripcion, 'FINALIZADA');
  assert.notEqual(fichaC011.historial[0].suscripcionId, fichaC011.servicioActual.suscripcionId);
  assert.equal(
    fichaC011.servicioActual.cobrosConfirmados + fichaC011.historial[0].cobrosConfirmados,
    2,
    'C011 debe conservar un cobro confirmado por episodio.',
  );

  const fichaC013 = await obtenerFichaEstudiante(identidad('C013'), porCodigo.get('C013').EstudianteId);
  assert.ok(fichaC013, 'C013 debe tener ficha aunque siga en LEAD.');
  assert.equal(fichaC013.estudiante.etapaActual, 'LEAD');
  assert.equal(fichaC013.servicioActual, null);
  assert.equal(fichaC013.historial.length, 0);
  assert.equal(fichaC013.prestaciones.length, 0);

  const fichaC003 = await obtenerFichaEstudiante(maria, porCodigo.get('C003').EstudianteId);
  assert.ok(fichaC003);
  assert.equal(fichaC003.estudiante.codigo, 'C003');
  assert.equal(fichaC003.apoderado?.nombreCompleto, 'Maria Salas Demo');
  const fichaAjena = await obtenerFichaEstudiante(maria, porCodigo.get('C001').EstudianteId);
  assert.equal(fichaAjena, null, 'La identidad del apoderado no debe acceder a un estudiante no vinculado.');

  const tablas = [
    'Estudiante', 'Contacto', 'Apoderado', 'Suscripcion', 'PeriodoServicio',
    'ModalidadPlan', 'PlanServicio', 'Prestacion', 'PlanPrestacion', 'BajaServicio',
  ];
  for (const tabla of tablas) {
    const { recordset: permisos } = await pool.request().query(`SELECT
      HAS_PERMS_BY_NAME(N'dbo.${tabla}', N'OBJECT', N'SELECT') AS Leer,
      HAS_PERMS_BY_NAME(N'dbo.${tabla}', N'OBJECT', N'INSERT') AS Insertar,
      HAS_PERMS_BY_NAME(N'dbo.${tabla}', N'OBJECT', N'UPDATE') AS Actualizar,
      HAS_PERMS_BY_NAME(N'dbo.${tabla}', N'OBJECT', N'DELETE') AS Borrar`);
    assert.equal(permisos[0].Leer, 1, `Falta SELECT de lectura en ${tabla}.`);
    assert.equal(permisos[0].Insertar, 0, `No debe haber INSERT en ${tabla}.`);
    assert.equal(permisos[0].Actualizar, 0, `No debe haber UPDATE en ${tabla}.`);
    assert.equal(permisos[0].Borrar, 0, `No debe haber DELETE en ${tabla}.`);
  }

  const { recordset: pagos } = await pool.request()
    .query('SELECT TOP (1) PeriodoServicioId, Tipo, Estado, ImportePEN FROM dbo.Pago');
  assert.ok(pagos.length <= 1);
  let columnaOculta = false;
  try {
    await pool.request().query('SELECT TOP (1) CodigoOperacion FROM dbo.Pago');
  } catch {
    columnaOculta = true;
  }
  assert.equal(columnaOculta, true, 'Pago debe exponer solo las columnas de servicio necesarias.');

  console.log('T08 correcta: listado paginado, C006 beca sin pago, C011 dos episodios, C013 LEAD y apoderado compartido sin duplicados.');
} catch (error) {
  console.error(error instanceof Error ? error.message : 'Error inesperado en la verificación de T08.');
  process.exitCode = 1;
} finally {
  await closePool();
}
