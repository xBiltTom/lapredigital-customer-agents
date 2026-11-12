import sql from 'mssql';
import {getPool} from './database/pool.ts';
import {obtenerFichaEstudiante} from './database/estudiantes.ts';
import {obtenerDuenoActivo} from './database/identidad.ts';

// Vistas de negocio: las proyecciones y relaciones son código del servidor.
// El modelo elige recurso/filtros, nunca SQL ni columnas o tablas arbitrarias.
const recursos={
 PAGOS:`SELECT p.PagoId id,s.EstudianteId estudianteId,p.Tipo tipo,p.Estado estado,p.ImportePEN importePEN,p.Moneda moneda,p.Canal canal,COALESCE(p.FechaConfirmacion,p.FechaOperacion) fecha,p.FechaOperacion fechaOperacion,p.FechaConfirmacion confirmacion,p.PagoOriginalId pagoOriginalId,p.PagadorContactoId pagadorContactoId,pl.Nombre descripcion,ps.Inicio inicioPeriodo,ps.Fin finPeriodo FROM dbo.Pago p JOIN dbo.PeriodoServicio ps ON ps.PeriodoServicioId=p.PeriodoServicioId JOIN dbo.Suscripcion s ON s.SuscripcionId=ps.SuscripcionId JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId=ps.ModalidadPlanId JOIN dbo.PlanServicio pl ON pl.PlanServicioId=mp.PlanServicioId`,
 SERVICIO:`SELECT ps.PeriodoServicioId id,s.EstudianteId estudianteId,ps.Tipo tipo,ps.EstadoAcceso estado,ps.ImporteExigiblePEN importePEN,ps.Inicio fecha,ps.Fin fin,ps.BecaPorcentaje becaPorcentaje,ps.PrecioAcordadoPEN precioAcordadoPEN,pl.Nombre descripcion,s.RenovacionAutomatica renovacionAutomatica,s.Estado estadoSuscripcion,s.SuscripcionId suscripcionId FROM dbo.PeriodoServicio ps JOIN dbo.Suscripcion s ON s.SuscripcionId=ps.SuscripcionId JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId=ps.ModalidadPlanId JOIN dbo.PlanServicio pl ON pl.PlanServicioId=mp.PlanServicioId`,
 ACTIVIDADES:`SELECT a.ActividadRutaId id,r.EstudianteId estudianteId,a.Estado estado,rc.Tipo tipo,rc.Titulo descripcion,a.FechaPlanificada fecha,a.FechaLimite limite,a.FechaCompletada completada,r.VersionNumero versionRuta,r.Vigente rutaVigente FROM dbo.ActividadRuta a JOIN dbo.RutaEstudio r ON r.RutaEstudioId=a.RutaEstudioId JOIN dbo.RecursoAcademico rc ON rc.RecursoAcademicoId=a.RecursoAcademicoId`,
 EVALUACIONES:`SELECT i.IntentoEvaluacionId id,i.EstudianteId estudianteId,e.Tipo tipo,e.Nombre descripcion,i.FechaFin fecha,i.Aciertos aciertos,i.TotalPreguntas totalPreguntas,CONVERT(DECIMAL(6,2),100.0*i.Aciertos/i.TotalPreguntas) porcentaje,g.Codigo grupoComparabilidad,g.Alcance alcance,g.Escala escala,g.Dificultad dificultad FROM dbo.IntentoEvaluacion i JOIN dbo.Evaluacion e ON e.EvaluacionId=i.EvaluacionId LEFT JOIN dbo.GrupoComparabilidad g ON g.GrupoComparabilidadId=e.GrupoComparabilidadId`,
 INCIDENCIAS:`SELECT CasoAtencionId id,EstudianteId estudianteId,Tipo tipo,Estado estado,Descripcion descripcion,FechaAperturaOriginal fecha,Ambito ambito,FechaLimite limite,FechaResolucionDefinitiva resolucionFecha,Resolucion resolucion FROM dbo.CasoAtencion`,
 VALORACIONES:`SELECT v.ValoracionId id,s.EstudianteId estudianteId,a.Nombre tipo,COALESCE(v.Comentario,N'Sin comentario') descripcion,v.FechaRespuesta fecha,v.Estrellas estrellas FROM dbo.Valoracion v JOIN dbo.SolicitudValoracion s ON s.SolicitudValoracionId=v.SolicitudValoracionId JOIN dbo.AspectoValoracion a ON a.AspectoValoracionId=s.AspectoValoracionId WHERE v.Valida=1`,
};
export type RecursoConsulta=keyof typeof recursos;
export type FiltrosConsulta={recurso:RecursoConsulta;estudianteId?:number;estado?:string;tipo?:string;buscar?:string;desde?:string;hasta?:string;orden:'RECIENTE'|'ANTIGUO'|'IMPORTE_MAYOR';limite:number;pagina:number};
export async function consultarBase(auth:{authenticator?:string;attributes?:Readonly<Record<string,string|readonly string[]>>}|null,b:FiltrosConsulta){
 const a=auth?.attributes,owner=Number(a?.personalInternoId);
 if(auth?.authenticator!=='dueno-local'||!await obtenerDuenoActivo(owner))throw new Error('Identidad activa requerida');
 const global=a?.modo==='global',participante=a?.modo==='participante';
 const e=global?b.estudianteId:Number(a?.estudianteId);
 if(!global&&(!e||(b.estudianteId!==undefined&&b.estudianteId!==e)))throw new Error('Solo puedes consultar al estudiante de esta sesión');
 if(e){const ficha=await obtenerFichaEstudiante({personalInternoId:owner},e);if(!ficha)throw new Error('Estudiante inexistente');if(participante&&a?.rol==='APODERADO'&&!ficha.prestaciones.some(p=>p.codigo==='REPORTES_APODERADO'))throw new Error('El plan no concede acceso al apoderado');}
 const columnas:Record<RecursoConsulta,readonly string[]>={PAGOS:['estado','tipo'],SERVICIO:['estado','tipo'],ACTIVIDADES:['estado','tipo'],EVALUACIONES:['tipo'],INCIDENCIAS:['estado','tipo'],VALORACIONES:['tipo']};
 if(b.estado&&!columnas[b.recurso].includes('estado'))throw new Error('Este recurso no tiene filtro estado');
 if(b.orden==='IMPORTE_MAYOR'&&!['PAGOS','SERVICIO'].includes(b.recurso))throw new Error('Orden por importe solo disponible para pagos/servicio');
 const filtros=['(@e IS NULL OR estudianteId=@e)','fecha<=GETDATE()'];
 if(b.estado)filtros.push('estado=@estado');if(b.tipo)filtros.push('tipo=@tipo');if(b.buscar)filtros.push("descripcion LIKE @buscar ESCAPE '~'");if(b.desde)filtros.push('fecha>=@desde');if(b.hasta)filtros.push('fecha<DATEADD(DAY,1,@hasta)');
 // Los valores y fechas siempre viajan parametrizados; los identificadores vienen del mapa cerrado.
 const query=`WITH datos AS (${recursos[b.recurso]}) SELECT *,COUNT(*) OVER() totalCoincidencias FROM datos WHERE ${filtros.join(' AND ')} ORDER BY ${b.orden==='IMPORTE_MAYOR'?'importePEN DESC,fecha DESC':b.orden==='ANTIGUO'?'fecha ASC':'fecha DESC'},id DESC OFFSET @offset ROWS FETCH NEXT @limite ROWS ONLY;`;
 const r=await (await getPool()).request().input('e',sql.Int,e??null).input('estado',sql.VarChar(30),b.estado??null).input('tipo',sql.VarChar(100),b.tipo??null).input('buscar',sql.NVarChar(300),b.buscar?'%'+b.buscar.replace(/[~%_\[]/g,'~$&')+'%':null).input('desde',sql.Date,b.desde??null).input('hasta',sql.Date,b.hasta??null).input('offset',sql.Int,(b.pagina-1)*b.limite).input('limite',sql.Int,b.limite).query(query);
 return {recurso:b.recurso,estudianteId:e??null,pagina:b.pagina,limite:b.limite,registros:r.recordset,criterios:b,interpretacion:b.recurso==='PAGOS'?'Último pago recibido: filtrar tipo COBRO, estado CONFIRMADO y orden RECIENTE. El importe es el cobro bruto para la suscripción del estudiante, no identifica quién pagó. REEMBOLSO/REVERSION/DISPUTA son operaciones separadas; no son nuevos cobros. No confundir importe exigible del servicio con dinero cobrado. Ausencia de cobros no demuestra deuda; comprobar beca y vigencia.':undefined};
}
