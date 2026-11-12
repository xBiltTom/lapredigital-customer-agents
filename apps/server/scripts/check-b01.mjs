import assert from 'node:assert/strict';
import { getPool, closePool } from '../lib/database/pool.ts';
import { loadOwnerConfig } from '../lib/config.ts';
import { obtenerDuenoActivo } from '../lib/database/identidad.ts';
import { listarEstudiantes, obtenerFichaEstudiante } from '../lib/database/estudiantes.ts';

try {
  const { OWNER_PERSONAL_ID } = loadOwnerConfig();
  const dueno = await obtenerDuenoActivo(OWNER_PERSONAL_ID);
  assert.ok(dueno, 'El dueño configurado debe estar activo.');
  const listado = await listarEstudiantes(dueno);
  const pool = await getPool();
  const { recordset } = await pool.request().query(`
    SELECT e.EstudianteId, e.Codigo, ap.ContactoId AS ApoderadoContactoId
    FROM dbo.Estudiante e LEFT JOIN dbo.Apoderado ap ON ap.ApoderadoId=e.ApoderadoId`);
  assert.equal(listado.total, recordset.length, 'El dueño debe poder listar todos los alumnos.');
  const ana = recordset.find(r => r.Codigo === 'C001');
  const carla = recordset.find(r => r.Codigo === 'C003');
  assert.ok(await obtenerFichaEstudiante(dueno, ana.EstudianteId));
  assert.equal(await obtenerFichaEstudiante({ contactoId: ana.ApoderadoContactoId }, ana.EstudianteId), null,
    'Vínculo con Ana sin REPORTES_APODERADO no debe habilitar acceso.');
  assert.ok(await obtenerFichaEstudiante({ contactoId: carla.ApoderadoContactoId }, carla.EstudianteId));
  assert.equal((await listarEstudiantes({ personalInternoId: 2147483647 })).total, 0,
    'Un personal inexistente no obtiene privilegios de dueño.');
  const soporte = await pool.request().query("SELECT TOP(1) PersonalInternoId FROM dbo.PersonalInterno WHERE Rol='SOPORTE'");
  assert.ok(soporte.recordset.length);
  assert.equal(await obtenerDuenoActivo(soporte.recordset[0].PersonalInternoId), null);
  assert.equal((await listarEstudiantes({ personalInternoId: soporte.recordset[0].PersonalInternoId })).total, 0);
  const permisos = await pool.request().query(`SELECT
    HAS_PERMS_BY_NAME(N'dbo.PersonalInterno', N'OBJECT', N'INSERT') AS Insertar,
    HAS_PERMS_BY_NAME(N'dbo.PersonalInterno', N'OBJECT', N'UPDATE') AS Actualizar,
    HAS_PERMS_BY_NAME(N'dbo.PersonalInterno', N'OBJECT', N'DELETE') AS Borrar`);
  assert.deepEqual(permisos.recordset[0], { Insertar: 0, Actualizar: 0, Borrar: 0 });
  console.log('B01: dueño activo ve los alumnos; soporte/inexistente sin acceso; apoderado requiere prestación vigente.');
} catch (error) {
  console.error(error instanceof Error ? error.message : 'No se pudo verificar B01.');
  process.exitCode = 1;
} finally { await closePool(); }
