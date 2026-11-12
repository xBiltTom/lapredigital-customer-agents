import {defineTool} from 'eve/tools';
import {z} from 'zod';
import {proponer,tipos} from '../../lib/propuestas.ts';
import {identidadHerramienta} from '../../lib/panel-auth.ts';
export default defineTool({description:'Registra PROPUESTA pendiente de aprobación humana. Nunca aprueba, ejecuta ni envía. Revalida reglas y evita duplicados.',inputSchema:z.object({tipo:z.enum(tipos),recomendacion:z.string().min(10).max(1500)}),async execute({tipo,recomendacion},ctx){const {id,estudianteId}=identidadHerramienta(ctx.session.auth.current);return proponer(id,estudianteId,tipo,recomendacion);}});
