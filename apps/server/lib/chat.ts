import {emptySessionView,foldEvents,conversation,deliveries,reply,calls} from 'eve/events';
import type {SessionReader} from 'eve/sessions';

// La dirección la construye el servidor; el navegador no elige sesiones ajenas.
export const direccionChat=(duenoId:number,estudianteId:number)=>`dueno:${duenoId}:alumno:${estudianteId}:chat:principal`;

export async function historialChat(session:SessionReader) {
 let view=emptySessionView();
 for await(const event of session.stream({follow:false,signal:AbortSignal.timeout(15000)}))view=foldEvents(view,[event]);
 const mensajes:{rol:'user'|'agent';texto:string;herramientas?:string[];sesionId?:string}[]=[];
 for(const turno of conversation(view)) {
  for(const delivery of deliveries(view,{turnId:turno.turnId})) {
   const texto=(delivery.parts??[]).filter(p=>p.kind==='text').map(p=>p.text).join('\n');
   if(texto)mensajes.push({rol:'user',texto});
  }
  const texto=reply(view,turno.turnId).filter(p=>p.kind==='text'&&typeof p.value==='string').map(p=>p.value).join('\n\n');
  if(texto)mensajes.push({rol:'agent',texto,herramientas:[...new Set(calls(view,{turnId:turno.turnId,kind:'tool'}).map(c=>c.name))],sesionId:session.id});
  else if(turno.error)mensajes.push({rol:'agent',texto:`No se completó la consulta: ${turno.error.message}`,sesionId:session.id});
 }
 return {mensajes,sesionId:session.id};
}
