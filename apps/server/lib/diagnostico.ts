import sql from 'mssql';
import { createHash, randomUUID } from 'node:crypto';
import { mkdir, readFile, writeFile, rename } from 'node:fs/promises';
import { getPool } from './database/pool.ts';
import { obtenerFichaEstudiante } from './database/estudiantes.ts';
import { clasificar, inactividad, incidencia, vigente, cumplimiento, mejoras, contextoVacio, type Contexto, type Senal, type Intento } from './domain.ts';

type Ruta = { id: number; version: number; vigente: boolean };
type Actividad = { id: number; rutaId: number; titulo: string; estado: string; planificada: Date; limite: Date; completada: Date | null };
type Mensaje = { id: number; fecha: Date; contenido: string; intencion: string | null };
type Valoracion = { id: number; fecha: Date; estrellas: number; comentario: string | null; aspecto: string };
type Caso = { id: number; tipo: string; ambito: string; estado: string; apertura: Date; descripcion: string };
type Dificultad = { id: number; fecha: Date; estado: string; descripcion: string };
type Permiso = { canal: string; autorizado: boolean; fecha: Date; evidencia: string };
type Accion = { id: number; tipo: string; estado: string; recomendacion: string; resultado: string | null; fecha: Date; evaluacionId: number | null; requiereAprobacion: boolean };
type Revision = { id: number; rutaId: number; motivo: string; estado: string; recomendacion: string | null; resultado: string | null };
type Evaluacion = { id: number; fecha: Date; estado: string; nivel: string | null };
const directorio = `.eve/contextos/${process.env.SQLSERVER_DATABASE}`;

export async function diagnostico(personalInternoId: number, estudianteId: number) {
  const ficha = await obtenerFichaEstudiante({ personalInternoId }, estudianteId);
  if (!ficha) throw new Error('Estudiante no disponible para esta identidad.');
  const pool = await getPool();
  const result = await pool.request().input('id', sql.Int, estudianteId).query(`
    DECLARE @c DATETIME2(0)=GETDATE(); SELECT @c AS corte;
    SELECT RutaEstudioId id, VersionNumero version, Vigente vigente FROM dbo.RutaEstudio WHERE EstudianteId=@id;
    SELECT a.ActividadRutaId id,a.RutaEstudioId rutaId,rc.Titulo titulo,a.Estado estado,a.FechaPlanificada planificada,a.FechaLimite limite,a.FechaCompletada completada
    FROM dbo.ActividadRuta a JOIN dbo.RutaEstudio r ON r.RutaEstudioId=a.RutaEstudioId JOIN dbo.RecursoAcademico rc ON rc.RecursoAcademicoId=a.RecursoAcademicoId WHERE r.EstudianteId=@id ORDER BY r.VersionNumero,a.Orden;
    SELECT i.IntentoEvaluacionId id,e.GrupoComparabilidadId grupoId,g.Codigo grupo,g.Alcance alcance,g.Escala escala,g.Dificultad dificultad,i.FechaFin fecha,i.Aciertos aciertos,i.TotalPreguntas total
    FROM dbo.IntentoEvaluacion i JOIN dbo.Evaluacion e ON e.EvaluacionId=i.EvaluacionId LEFT JOIN dbo.GrupoComparabilidad g ON g.GrupoComparabilidadId=e.GrupoComparabilidadId WHERE i.EstudianteId=@id AND i.FechaFin<=@c;
    SELECT TOP(1) EventoUsoId id,FechaEvento fecha FROM dbo.EventoUso WHERE EstudianteId=@id AND FechaEvento<=@c ORDER BY FechaEvento DESC,EventoUsoId DESC;
    SELECT COUNT(CASE WHEN FechaEvento>=DATEADD(DAY,-7,@c) THEN 1 END) recientes,COUNT(CASE WHEN FechaEvento<DATEADD(DAY,-7,@c) THEN 1 END) anteriores FROM dbo.EventoUso WHERE EstudianteId=@id AND FechaEvento>=DATEADD(DAY,-14,@c) AND FechaEvento<=@c;
    SELECT CasoAtencionId id,Tipo tipo,Ambito ambito,Estado estado,FechaAperturaOriginal apertura,Descripcion descripcion FROM dbo.CasoAtencion WHERE EstudianteId=@id AND FechaAperturaOriginal<=@c;
    SELECT DificultadAcademicaId id,FechaIdentificacion fecha,Estado estado,Descripcion descripcion FROM dbo.DificultadAcademica WHERE EstudianteId=@id AND FechaIdentificacion<=@c;
    SELECT m.MensajeId id,m.FechaRecepcion fecha,m.Contenido contenido,m.IntencionExpresa intencion FROM dbo.Mensaje m JOIN dbo.Conversacion c ON c.ConversacionId=m.ConversacionId WHERE c.EstudianteId=@id AND m.Direccion='ENTRANTE' AND m.FechaRecepcion<=@c ORDER BY m.FechaRecepcion,m.MensajeId;
    SELECT v.ValoracionId id,v.FechaRespuesta fecha,v.Estrellas estrellas,v.Comentario comentario,a.Nombre aspecto FROM dbo.Valoracion v JOIN dbo.SolicitudValoracion s ON s.SolicitudValoracionId=v.SolicitudValoracionId JOIN dbo.AspectoValoracion a ON a.AspectoValoracionId=s.AspectoValoracionId WHERE s.EstudianteId=@id AND v.Valida=1 AND v.FechaRespuesta<=@c;
    SELECT a.Canal canal,a.Autorizado autorizado,a.FechaDecision fecha,a.Evidencia evidencia FROM dbo.AutorizacionContacto a JOIN dbo.Estudiante e ON e.ContactoId=a.ContactoId WHERE e.EstudianteId=@id AND a.Finalidad='ACADEMICA' AND a.FechaDecision<=@c;
    SELECT IntervencionId id,Tipo tipo,Estado estado,Recomendacion recomendacion,Resultado resultado,FechaCreacion fecha,EvaluacionRiesgoId evaluacionId,RequiereAprobacion requiereAprobacion FROM dbo.Intervencion WHERE EstudianteId=@id ORDER BY FechaCreacion DESC,IntervencionId DESC;
    SELECT rv.RevisionRutaId id,rv.RutaEstudioId rutaId,rv.Motivo motivo,rv.Estado estado,rv.Recomendacion recomendacion,rv.Resultado resultado FROM dbo.RevisionRuta rv JOIN dbo.RutaEstudio r ON r.RutaEstudioId=rv.RutaEstudioId WHERE r.EstudianteId=@id;
    SELECT TOP(1) EvaluacionRiesgoId id,FechaEvaluacion fecha,Estado estado,Nivel nivel FROM dbo.EvaluacionRiesgo WHERE EstudianteId=@id AND FechaEvaluacion<=@c ORDER BY FechaEvaluacion DESC,EvaluacionRiesgoId DESC;
  `);
  const [tiempo,rutas,actividades,intentos,uso,frecuencia,casos,dificultades,mensajes,valoraciones,permisos,acciones,revisiones,evaluaciones] = result.recordsets as unknown as [
    { corte: Date }[],Ruta[],Actividad[],Intento[],{id:number;fecha:Date}[],{recientes:number;anteriores:number}[],Caso[],Dificultad[],Mensaje[],Valoracion[],Permiso[],Accion[],Revision[],Evaluacion[]];
  const corte=tiempo[0]!.corte, inicio=new Date(+corte-30*86400000);
  const huella=createHash('sha256').update(JSON.stringify({mensajes,valoraciones})).digest('hex');
  let contexto=contextoVacio();
  try { const saved=JSON.parse(await readFile(`${directorio}/${estudianteId}.json`,'utf8')); if(saved.huella===huella) contexto=saved.contexto; } catch (error) { if((error as NodeJS.ErrnoException).code!=='ENOENT') throw error; }
  const senales: Senal[]=[];
  if(uso[0]) senales.push({codigo:inactividad((+corte-+uso[0].fecha)/1000)==='BAJO'?'ACTIVIDAD_RECIENTE':'INACTIVIDAD',nivel:inactividad((+corte-+uso[0].fecha)/1000),fuente:'EventoUso',id:uso[0].id,fecha:uso[0].fecha});
  for(const c of casos) if(c.tipo==='INCIDENCIA'&&c.ambito!=='PAGO'&&c.estado!=='RESUELTA'&&incidencia((+corte-+c.apertura)/1000)!=='BAJO') senales.push({codigo:'INCIDENCIA_ABIERTA',nivel:incidencia((+corte-+c.apertura)/1000),fuente:'CasoAtencion',id:c.id,fecha:c.apertura});
  for(const d of dificultades) if(d.estado!=='SUPERADA') senales.push({codigo:'DIFICULTAD_ACADEMICA',nivel:'MEDIO',fuente:'DificultadAcademica',id:d.id,fecha:d.fecha});
  for(const m of mensajes) if(['CANCELAR','NO_RENOVAR'].includes(m.intencion??'')||contexto.cancelacion.includes(m.id)) senales.push({codigo:'INTENCION_CANCELAR',nivel:'ALTO',fuente:'Mensaje',id:m.id,fecha:m.fecha});
  for(const v of valoraciones) if(v.estrellas<=2&&contexto.insatisfaccion.includes(v.id)) senales.push({codigo:'INSATISFACCION',nivel:'ALTO',fuente:'Valoracion',id:v.id,fecha:v.fecha});
  const narrativaPendiente=mensajes.some(m=>!contexto.revisados.includes(m.id))||valoraciones.some(v=>v.estrellas<=2&&!contexto.valoracionesRevisadas.includes(v.id));
  const riesgo=clasificar(senales,!!uso[0]&&!narrativaPendiente);
  const ruta=rutas.find(r=>r.vigente)??null;
  const causas:string[]=[];
  if(!ficha.servicioActual||ficha.estudiante.etapaActual!=='CUSTOMER') causas.push('Sin servicio CUSTOMER vigente');
  if(!ficha.prestaciones.some(p=>p.codigo==='SEGUIMIENTO_IA')) causas.push('Plan sin seguimiento IA');
  if(contexto.noContacto.length) causas.push('Petición de no contacto proactivo');
  if(narrativaPendiente) causas.push('Revisar conversaciones y valoraciones antes del seguimiento');
  if(!['MEDIO','ALTO'].includes(riesgo.nivel??'')) causas.push('Riesgo sin clasificación media o alta');
  const canales=permisos.filter(p=>p.autorizado).map(p=>p.canal);
  if(!canales.length) causas.push('Sin canal académico autorizado');
  const calificaciones=valoraciones.filter(v=>v.fecha>=inicio);
  const ultima=evaluaciones[0]??null;
  const temario=(await pool.request().input('e',sql.Int,estudianteId).query(`SELECT c.ContenidoId id,c.Curso curso,c.Tema tema,c.Subtemas subtemas,COALESCE(p.Estado,'PENDIENTE') estado,p.Origen origen FROM dbo.ContenidoUNT c LEFT JOIN dbo.ProgresoTemaUNT p ON p.ContenidoId=c.ContenidoId AND p.EstudianteId=@e ORDER BY c.ContenidoId`)).recordset;
  return {temario,estudianteId,corte,inicio,versionReglas:'INFORME_7.1',huella,ficha,ruta,rutas,actividades,intentos,
    cumplimiento:cumplimiento(actividades,ruta?.id??null,inicio,corte),mejoras:mejoras(intentos),uso:uso[0]??null,
    frecuencia:frecuencia[0]!,casos,dificultades,revisiones,mensajes,valoraciones,permisos,acciones,
    satisfaccion:calificaciones.length?calificaciones.reduce((s,v)=>s+v.estrellas,0)/calificaciones.length:null,
    riesgo,narrativaPendiente,contexto,seguimiento:{permitido:causas.length===0,causas,canales},
    evaluacionGuardada:ultima?{...ultima,vigente:ultima.estado==='CLASIFICADA'&&vigente(ultima.fecha,corte)}:null};
}

export async function guardarContexto(personalInternoId:number, estudianteId:number, huella:string, contexto:Contexto) {
  const d=await diagnostico(personalInternoId,estudianteId);
  if(d.huella!==huella) throw new Error('La evidencia cambió. Consultar de nuevo antes de interpretar.');
  for(const ids of [contexto.revisados,contexto.cancelacion,contexto.noContacto]) if(ids.some(id=>!d.mensajes.some(m=>m.id===id))) throw new Error('Mensaje ajeno o inexistente.');
  if(contexto.insatisfaccion.some(id=>!d.valoraciones.some(v=>v.id===id&&v.estrellas<=2))) throw new Error('Valoración inválida para insatisfacción.');
  if(contexto.valoracionesRevisadas.some(id=>!d.valoraciones.some(v=>v.id===id))) throw new Error('Valoración ajena o inexistente.');
  await mkdir(directorio,{recursive:true,mode:0o700});
  const temp=`${directorio}/${estudianteId}.${randomUUID()}.tmp`;
  await writeFile(temp,JSON.stringify({huella,contexto}),{mode:0o600});
  await rename(temp,`${directorio}/${estudianteId}.json`);
  return diagnostico(personalInternoId,estudianteId);
}

export function jsonSeguro(value:unknown):unknown {
  if(value instanceof Date) { const local=new Date(+value-5*3600000).toISOString().slice(0,19); return local+'-05:00'; }
  if(Array.isArray(value)) return value.map(jsonSeguro);
  if(value&&typeof value==='object') return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,jsonSeguro(v)]));
  return value;
}
