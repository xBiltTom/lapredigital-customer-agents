// Integración focalizada; nunca publica reglas de prueba en la base académica.
import assert from 'node:assert/strict';
import { getPrisma } from '../lib/database/prisma.ts';
import { closePool } from '../lib/database/pool.ts';
import {
  politicaActual,
  politicaVersion,
  publicarPolitica,
} from '../lib/servicios/politicas.ts';
import { reglasInforme } from '../lib/academico/reglas.ts';
import { diagnostico } from '../lib/academico/diagnostico.ts';
import { proponer, decidir } from '../lib/academico/intervenciones.ts';
assert.equal(process.env.SQLSERVER_DATABASE, 'LaPreDigital_Customers_MvpTest');
const p = getPrisma();
try {
  const inicial = await politicaActual();
  assert.equal(inicial.VersionReglas, 'INFORME_7.1');
  const antes = await diagnostico(1, 8);
  assert.equal(
    antes.riesgo.senales.find((s) => s.fuente === 'EventoUso').nivel,
    'MEDIO',
  );
  assert.equal(antes.evaluacionGuardada.vigente, false);
  const nueva = await publicarPolitica(1, {
    ...reglasInforme,
    InactividadMediaHoras: 120,
    InactividadAltaHoras: 240,
    VigenciaDias: 14,
    MaxEstrellasInsatisfaccion: 3,
    versionBase: inicial.VersionReglas,
    Motivo: 'Verificar política alternativa en la base aislada',
  });
  const despues = await diagnostico(1, 8);
  assert.equal(despues.versionReglas, nueva.VersionReglas);
  assert.equal(
    despues.riesgo.senales.find((s) => s.fuente === 'EventoUso').nivel,
    'BAJO',
  );
  assert.equal(despues.evaluacionGuardada.vigente, false);
  assert.equal(despues.evaluacionGuardada.versionReglas, inicial.VersionReglas);
  assert.deepEqual(await politicaVersion(inicial.VersionReglas), inicial);
  await assert.rejects(
    publicarPolitica(1, {
      ...reglasInforme,
      versionBase: inicial.VersionReglas,
      Motivo: 'Formulario obsoleto',
    }),
    /Recarga/,
  );
  await assert.rejects(
    publicarPolitica(1, {
      ...reglasInforme,
      InactividadMediaHoras: 500,
      versionBase: nueva.VersionReglas,
      Motivo: 'Umbrales invertidos',
    }),
  );
  const propuesta = await proponer(
    1,
    8,
    'DERIVACION_HUMANA',
    'Revisión de prueba con política versionada.',
  );
  const rows =
    await p.$queryRaw`SELECT e.VersionReglas FROM dbo.EvaluacionRiesgo e JOIN dbo.Intervencion i ON i.EvaluacionRiesgoId=e.EvaluacionRiesgoId WHERE i.IntervencionId=${propuesta.id}`;
  assert.equal(rows[0].VersionReglas, nueva.VersionReglas);
  const tercera = await publicarPolitica(1, {
    ...reglasInforme,
    MaxEstrellasInsatisfaccion: 1,
    versionBase: nueva.VersionReglas,
    Motivo: 'Verificar reevaluación de propuestas y evidencias históricas',
  });
  await assert.rejects(
    decidir(1, 8, propuesta.id, 'aprobar'),
    /política cambió/,
  );
  // El trigger utiliza la política de la evaluación, no la configuración actual.
  const [valor] =
    await p.$queryRaw`SELECT TOP(1) v.ValoracionId,v.FechaRespuesta,s.EstudianteId FROM dbo.Valoracion v JOIN dbo.SolicitudValoracion s ON s.SolicitudValoracionId=v.SolicitudValoracionId WHERE v.Valida=1 AND v.Estrellas=2`;
  assert.ok(valor);
  async function senal(version) {
    return p.$transaction(async (tx) => {
      const [ev] =
        await tx.$queryRaw`INSERT dbo.EvaluacionRiesgo(EstudianteId,FechaEvaluacion,Estado,Nivel,VersionReglas,Motivo,Origen) OUTPUT INSERTED.EvaluacionRiesgoId id VALUES(${valor.EstudianteId},GETDATE(),'CLASIFICADA','ALTO',${version},N'Prueba histórica del umbral de estrellas','SISTEMA')`;
      await tx.$executeRaw`INSERT dbo.SenalRiesgo(EvaluacionRiesgoId,Codigo,Nivel,FechaObservacion,ValoracionId,Detalle) VALUES(${ev.id},'INSATISFACCION','ALTO',${valor.FechaRespuesta},${valor.ValoracionId},N'Insatisfacción contextual de prueba')`;
    });
  }
  await senal(nueva.VersionReglas);
  await assert.rejects(
    senal(tercera.VersionReglas),
    /La valoracion no es evidencia valida/,
  );
  console.log(
    'OK: publicación, cambio real de diagnóstico, vigencia histórica, formulario obsoleto, límites, propuestas y trigger por versión. Solo MvpTest.',
  );
} finally {
  await p.$disconnect();
  await closePool();
}
