import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {registrarSesionChat,referenciasChat,historialDireccion} from '../lib/conversaciones/archivo.ts';

test('el historial conserva sesiones cerradas, deduplica referencias y separa dueño/estudiante/global',async()=>{
 const previous=process.env.CHAT_HISTORY_DIR;
 const dir=await mkdtemp(path.join(tmpdir(),'lapredigital-historial-'));
 process.env.CHAT_HISTORY_DIR=dir;
 try{
  const address='dueno:1:alumno:3:chat:principal';
  await registrarSesionChat(address,'wrun_ARCHIVADA');
  await registrarSesionChat(address,'wrun_ARCHIVADA');
  await registrarSesionChat('dueno:1:global','wrun_GLOBAL');
  await registrarSesionChat('dueno:2:alumno:3:chat:principal','wrun_OTRODUENO');
  assert.equal((await referenciasChat()).length,3);
  const leidas=[];
  const attach=id=>({id,async *stream(options){assert.equal(options.follow,false);leidas.push(id);}});
  await historialDireccion(address,null,attach);
  assert.deepEqual(leidas,['wrun_ARCHIVADA']);
  leidas.length=0;
  await historialDireccion(address,attach('wrun_NUEVA'),attach);
  assert.deepEqual(leidas.sort(),['wrun_ARCHIVADA','wrun_NUEVA']);
  await assert.rejects(registrarSesionChat('../otra-carpeta','wrun_INVALIDA'));
 }finally{
  if(previous===undefined)delete process.env.CHAT_HISTORY_DIR;else process.env.CHAT_HISTORY_DIR=previous;
  await rm(dir,{recursive:true,force:true});
 }
});
