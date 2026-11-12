import {defineTool} from 'eve/tools';
import {z} from 'zod';
import {diagnostico,jsonSeguro} from '../../lib/diagnostico.ts';
import {identidadHerramienta} from '../../lib/panel-auth.ts';
export default defineTool({description:'Consulta datos, progreso, riesgo y evidencias del alumno seleccionado por el servidor. No recibe otro ID.',inputSchema:z.object({}),async execute(_,ctx){const {id,estudianteId}=identidadHerramienta(ctx.session.auth.current);return jsonSeguro(await diagnostico(id,estudianteId));}});
