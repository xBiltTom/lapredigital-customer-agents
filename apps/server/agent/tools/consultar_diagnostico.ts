import {defineTool} from 'eve/tools';
import {z} from 'zod';
import {diagnostico,jsonSeguro} from '../../lib/diagnostico.ts';
import {identidadHerramienta} from '../../lib/panel-auth.ts';
export default defineTool({description:'Solo dueño en dashboard o acompañamiento individual: consulta datos, progreso, riesgo y evidencias del alumno fijado por el servidor. No recibe otro ID. En el portal del participante no está disponible: usa operar_plataforma con accion ESTUDIANTE.',inputSchema:z.object({}),async execute(_,ctx){const {id,estudianteId}=identidadHerramienta(ctx.session.auth.current);return jsonSeguro(await diagnostico(id,estudianteId));}});
