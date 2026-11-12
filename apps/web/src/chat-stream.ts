export type EventoChat={tipo:'inicio'|'texto'|'herramientas'|'fin'|'error';texto?:string;sesionId?:string;herramientas?:string[];error?:string};

export async function leerRespuesta(response:Response,onEvent:(event:EventoChat)=>void){
 if(!response.ok){const data=await response.json();throw new Error(data.error??`Error HTTP ${response.status}`);}
 if(!response.body)throw new Error('No se recibió la respuesta del agente.');
 const reader=response.body.getReader(),decoder=new TextDecoder();let buffer='',terminado=false;
 function linea(value:string){if(!value.trim())return;const event:EventoChat=JSON.parse(value);if(event.tipo==='error')throw new Error(event.error??'La respuesta se interrumpió.');if(event.tipo==='fin')terminado=true;onEvent(event);}
 try{
  for(;;){const {value,done}=await reader.read();buffer+=decoder.decode(value,{stream:!done});let corte;while((corte=buffer.indexOf('\n'))!==-1){linea(buffer.slice(0,corte));buffer=buffer.slice(corte+1);}if(done)break;}
  linea(buffer);if(!terminado)throw new Error('La conexión se interrumpió. El historial se recuperará al volver a esta ficha.');
 }finally{await reader.cancel().catch(()=>{});reader.releaseLock();}
}
