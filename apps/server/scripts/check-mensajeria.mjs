// Prueba focalizada de atención manual; escribe exclusivamente en MvpTest.
import assert from 'node:assert/strict';
import {getPrisma} from '../lib/database/prisma.ts';
import {responderManual,leerHilo} from '../lib/servicios/mensajeria.ts';
import {bandeja} from '../lib/servicios/plataforma.ts';
import {closePool} from '../lib/database/pool.ts';
assert.equal(process.env.SQLSERVER_DATABASE,'LaPreDigital_Customers_MvpTest');
const p=getPrisma();
try{
 const e=await p.estudiante.findUniqueOrThrow({where:{Codigo:'C003'}});const h={EstudianteId:e.EstudianteId,ContactoId:e.ContactoId,Rol:'ESTUDIANTE'};
 await p.mensajeCanalLocal.create({data:{...h,Canal:'MENSAJERIA',Direccion:'ENTRANTE',Contenido:'Pregunta para atención manual de prueba'}});
 const m=await responderManual(1,h,'Respuesta manual de prueba para la bandeja.');assert.equal(m.FechaEntrega,null);
 const principal=await leerHilo(h);assert.ok(principal.items.some(x=>x.MensajeLocalId===m.MensajeLocalId));
 const otro=await leerHilo({...h,Rol:'APODERADO'});assert.equal(otro.items.length,0);
 const portal=await bandeja(e.EstudianteId,'ESTUDIANTE','MENSAJERIA',true);const visible=portal.find(x=>x.MensajeLocalId===m.MensajeLocalId);assert.ok(visible?.FechaEntrega);
 console.log('OK: respuesta manual visible en la bandeja del participante; entrega solo al leer portal; roles separados. Solo MvpTest.');
}finally{await p.$disconnect();await closePool();}
