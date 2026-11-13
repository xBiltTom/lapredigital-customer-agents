import assert from 'node:assert/strict';
import test from 'node:test';
import {inactividad,incidencia,vigente,clasificar,cumplimiento,mejoras} from '../lib/academico/reglas.ts';
const corte=new Date('2026-11-12T12:00:00-05:00');
test('umbrales horarios exactos y vigencia de siete días',()=>{
  for(const [s,n] of [[259199,'BAJO'],[259200,'MEDIO'],[604799,'MEDIO'],[604800,'ALTO']]) assert.equal(inactividad(s),n);
  for(const [s,n] of [[172800,'BAJO'],[172801,'MEDIO'],[345600,'MEDIO'],[345601,'ALTO']]) assert.equal(incidencia(s),n);
  assert.equal(vigente(new Date(+corte-604800000),corte),true);
  assert.equal(vigente(new Date(+corte-604801000),corte),false);
  assert.equal(vigente(new Date(+corte+1000),corte),false);
});
test('ausencia de datos queda pendiente y una evidencia alta prevalece',()=>{
  assert.equal(clasificar([],false).nivel,null);
  assert.equal(clasificar([{nivel:'MEDIO'}],false).estado,'PENDIENTE');
  assert.equal(clasificar([{nivel:'MEDIO'},{nivel:'ALTO'}],false).nivel,'ALTO');
});
test('cumplimiento no mezcla rutas, canceladas ni actividades futuras',()=>{
  const actividad={rutaId:1,estado:'COMPLETADA',planificada:new Date(+corte-1000),completada:corte};
  const r=cumplimiento([actividad,{...actividad,rutaId:2},{...actividad,estado:'CANCELADA'},{...actividad,planificada:new Date(+corte+1000)}],1,new Date(+corte-3000),corte);
  assert.equal(r.planificadas,1);assert.equal(r.porcentaje,100);
  assert.equal(cumplimiento([],null,corte,corte).porcentaje,null);
});
test('mejora expresa puntos porcentuales y exige grupo y secuencia temporal',()=>{
  const i={id:1,grupoId:1,grupo:'ALG',fecha:new Date(+corte-1000),aciertos:8,total:20};
  assert.ok(Math.abs(mejoras([i,{...i,id:2,fecha:corte,aciertos:11}])[0].mejoraPP-15)<1e-9);
  assert.equal(mejoras([i,{...i,id:2,grupoId:2,fecha:corte}])[0].mejoraPP,null);
  assert.equal(mejoras([{...i,grupoId:null}]).length,0);
});

test('los parámetros publicados conservan límites exactos y cambian el resultado',()=>{
 const custom={InactividadMediaHoras:96,InactividadAltaHoras:192,IncidenciaMediaHoras:60,IncidenciaAltaHoras:120,VigenciaDias:14,MaxEstrellasInsatisfaccion:3};
 assert.equal(inactividad(80*3600,custom),'BAJO');
 assert.equal(inactividad(96*3600,custom),'MEDIO');
 assert.equal(inactividad(192*3600,custom),'ALTO');
 assert.equal(incidencia(60*3600,custom),'BAJO');
 assert.equal(incidencia(60*3600+1,custom),'MEDIO');
 assert.equal(incidencia(120*3600,custom),'MEDIO');
 assert.equal(incidencia(120*3600+1,custom),'ALTO');
 const corte=new Date('2026-11-13T12:00:00Z');
 assert.equal(vigente(new Date(+corte-14*86400000),corte,14),true);
 assert.equal(vigente(new Date(+corte-14*86400000-1),corte,14),false);
});
