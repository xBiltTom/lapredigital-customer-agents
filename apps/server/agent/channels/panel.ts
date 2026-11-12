import {defineChannel,GET,POST} from 'eve/channels';
import {z} from 'zod';
import {dueno} from '../../lib/panel-auth.ts';
import {listarEstudiantes} from '../../lib/database/estudiantes.ts';
import {diagnostico,jsonSeguro} from '../../lib/diagnostico.ts';
import {proponer,decidir,tipos} from '../../lib/propuestas.ts';
import {direccionChat,historialChat} from '../../lib/chat.ts';

const idSchema=z.coerce.number().int().positive().max(2147483647);
const json=(data:unknown,status=200)=>Response.json(jsonSeguro(data),{status,headers:{'cache-control':'no-store'}});
const error=(e:unknown)=>json({error:e instanceof z.ZodError?'Entrada inválida.':e instanceof Error?e.message.slice(0,300):'Operación fallida.'},e instanceof z.ZodError?400:409);
export default defineChannel({routes:[
  GET('/api/status',async request=>{
    const owner=await dueno(request);if(!owner)return json({error:'Acceso del dueño requerido.'},401);
    try{const r=await fetch('http://127.0.0.1:3000/eve/v1/info',{headers:{authorization:request.headers.get('authorization')!}});const info=await r.json();return json({ok:true,modelo:info.agent?.model?.endpoint?.state??'unavailable',duenoId:owner.id});}catch(e){return error(e);}
  }),
  GET('/api/estudiantes',async request=>{
    const owner=await dueno(request);if(!owner)return json({error:'Acceso requerido.'},401);
    try{return json(await listarEstudiantes({personalInternoId:owner.id},{tamano:50}));}catch(e){return error(e);}
  }),
  GET('/api/estudiantes/:id',async(request,{params})=>{
    const owner=await dueno(request);if(!owner)return json({error:'Acceso requerido.'},401);
    try{return json(await diagnostico(owner.id,idSchema.parse(params.id)));}catch(e){return error(e);}
  }),
  POST('/api/estudiantes/:id/propuestas',async(request,{params})=>{
    const owner=await dueno(request);if(!owner)return json({error:'Acceso requerido.'},401);
    try{const b=z.object({tipo:z.enum(tipos),recomendacion:z.string().min(10).max(1500)}).parse(await request.json());return json(await proponer(owner.id,idSchema.parse(params.id),b.tipo,b.recomendacion));}catch(e){return error(e);}
  }),
  POST('/api/estudiantes/:id/intervenciones/:intervencionId',async(request,{params})=>{
    const owner=await dueno(request);if(!owner)return json({error:'Acceso requerido.'},401);
    try{const b=z.object({accion:z.enum(['aprobar','rechazar','simular'])}).parse(await request.json());return json(await decidir(owner.id,idSchema.parse(params.id),idSchema.parse(params.intervencionId),b.accion));}catch(e){return error(e);}
  }),
  GET('/api/estudiantes/:id/chat',async(request,{params,resolveSession})=>{
    const owner=await dueno(request);if(!owner)return json({error:'Acceso requerido.'},401);
    try{
      const id=idSchema.parse(params.id);await diagnostico(owner.id,id);
      const session=await resolveSession(direccionChat(owner.id,id));
      return json(session?await historialChat(session):{mensajes:[],sesionId:null});
    }catch(e){return error(e);}
  }),
  GET('/api/dashboard/chat',async(request,{resolveSession})=>{
    const owner=await dueno(request);if(!owner)return json({error:'Acceso requerido.'},401);
    try{const session=await resolveSession(`dueno:${owner.id}:global`);return json(session?await historialChat(session):{mensajes:[]});}catch(e){return error(e);}
  }),
  POST('/api/chat',async(request,{from})=>{
    const owner=await dueno(request);if(!owner)return json({error:'Acceso requerido.'},401);
    try{
      const b=z.object({estudianteId:idSchema.optional(),global:z.boolean().optional(),mensaje:z.string().trim().min(1).max(2000)}).parse(await request.json());
      if(!b.global&&!b.estudianteId)throw new Error('Selecciona estudiante');
      if(!b.global)await diagnostico(owner.id,b.estudianteId!);
      const info=await fetch('http://127.0.0.1:3000/eve/v1/info',{headers:{authorization:request.headers.get('authorization')!}}).then(r=>r.json());
      if(info.agent?.model?.endpoint?.state!=='ready')return json({error:'Modelo sin conexión. Abre scripts/chat-local y desbloquea el llavero.'},503);
      const source=from(b.global?`dueno:${owner.id}:global`:direccionChat(owner.id,b.estudianteId!));
      const delivery=await source.send(b.mensaje,{auth:{...owner.auth,attributes:{...owner.auth.attributes,estudianteId:b.global?'':String(b.estudianteId),modo:b.global?'global':'individual'}},turnPolicy:'queue'});
      if(request.headers.get('accept')?.includes('application/x-ndjson')){
        const encoder=new TextEncoder(),signal=AbortSignal.any([request.signal,AbortSignal.timeout(180000)]);
        const iterator=(async function*(){
          yield {tipo:'inicio',sesionId:delivery.sessionId};
          const partes=new Map<string,string>(),clases=new Map<string,string>(),herramientas=new Set<string>();
          try{
            for await(const event of delivery.stream({signal})){
              if(event.type==='content.delta'){
                if(event.data.kind)clases.set(event.data.partId,event.data.kind);
                if(clases.get(event.data.partId)!=='text')continue;
                partes.set(event.data.partId,(partes.get(event.data.partId)??'')+event.data.delta);
                yield {tipo:'texto',texto:[...partes.values()].join('\n\n')};
              }
              if(event.type==='content.completed'&&event.data.kind==='text'&&typeof event.data.value==='string'){
                partes.set(event.data.partId,event.data.value);
                yield {tipo:'texto',texto:[...partes.values()].join('\n\n')};
              }
              if(event.type==='call.requested'&&event.data.capability.kind==='tool'){
                herramientas.add(event.data.capability.name);
                yield {tipo:'herramientas',herramientas:[...herramientas]};
              }
            }
            const result=await delivery.result({signal});
            if(result.status!=='completed')throw new Error(result.error?.message??'El modelo requiere atención en Eve.');
            yield {tipo:'fin',texto:result.reply,sesionId:result.sessionId,herramientas:[...herramientas]};
          }catch(e){yield {tipo:'error',error:e instanceof Error?e.message.slice(0,300):'Se interrumpió la respuesta.'};}
        })();
        return new Response(new ReadableStream<Uint8Array>({
          async pull(controller){const next=await iterator.next();if(next.done)controller.close();else controller.enqueue(encoder.encode(JSON.stringify(next.value)+'\n'));},
          async cancel(){await iterator.return(undefined);},
        }),{headers:{'content-type':'application/x-ndjson; charset=utf-8','cache-control':'no-store, no-transform','x-accel-buffering':'no'}});
      }
      const result=await delivery.result({signal:AbortSignal.timeout(90000)});
      if(result.status!=='completed')return json({error:result.error?.message??'El modelo requiere atención en la terminal de Eve.',estado:result.status},503);
      const herramientas:string[]=[];
      for await(const event of delivery.stream({signal:AbortSignal.timeout(10000)}))if(event.type==='call.requested'&&event.data.capability.kind==='tool')herramientas.push(event.data.capability.name);
      return json({respuesta:result.reply,sesionId:result.sessionId,herramientas:[...new Set(herramientas)]});
    }catch(e){return error(e);}
  }),
]});
