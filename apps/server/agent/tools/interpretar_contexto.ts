import {defineTool} from 'eve/tools';
import {z} from 'zod';
import {guardarContexto,jsonSeguro} from '../../lib/diagnostico.ts';
import {identidadHerramienta} from '../../lib/panel-auth.ts';
const ids=z.array(z.number().int().positive()).max(200);
export default defineTool({description:'Registra interpretación de evidencias ya consultadas, ligadas a su huella. No modifica SQL ni concede autorizaciones.',inputSchema:z.object({huella:z.string().length(64),revisados:ids,valoracionesRevisadas:ids,cancelacion:ids,noContacto:ids,insatisfaccion:ids}),async execute({huella,...contexto},ctx){const {id,estudianteId}=identidadHerramienta(ctx.session.auth.current);return jsonSeguro(await guardarContexto(id,estudianteId,huella,contexto));}});
