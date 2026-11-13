import { autenticarDueno } from './auth.ts';
export async function dueno(request:Request) {
  const auth=await autenticarDueno(request);
  return auth?{auth,id:Number(auth.attributes?.personalInternoId)}:null;
}
export function identidadHerramienta(auth:{authenticator?:string;attributes?:Readonly<Record<string,string|readonly string[]>>}|null) {
  if(auth?.attributes?.modo==='participante')throw new Error('Herramienta reservada al dueño; en el portal usa operar_plataforma con accion ESTUDIANTE.');
  const id=Number(auth?.attributes?.personalInternoId),estudianteId=Number(auth?.attributes?.estudianteId);
  if(auth?.authenticator!=='dueno-local'||!Number.isSafeInteger(id)||id<1||!Number.isSafeInteger(estudianteId)||estudianteId<1) throw new Error('Selecciona un estudiante en el panel autenticado.');
  return {id,estudianteId};
}
