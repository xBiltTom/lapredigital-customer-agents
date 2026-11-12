import sql from 'mssql';
import { createHash } from 'node:crypto';
import { getPool } from './database/pool.ts';
import { diagnostico } from './diagnostico.ts';
import {inactividad,incidencia,vigente,type Senal} from './domain.ts';

export const tipos = ['SEGUIMIENTO','RECOMENDACION_RUTA','DERIVACION_HUMANA'] as const;
export type Tipo = typeof tipos[number];
async function bloquear(tx:sql.Transaction, estudianteId:number) {
  await new sql.Request(tx).input('recurso',sql.NVarChar(100),`lapredigital:mvp:${estudianteId}`).query(`
    SET XACT_ABORT ON;
    DECLARE @rc INT; EXEC @rc=sys.sp_getapplock @Resource=@recurso,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
    IF @rc<0 THROW 51940,N'No se pudo bloquear la operación. Reintentar.',1;`);
}
async function validarServicio(tx:sql.Transaction,e:number,p:number,tipo:string) {
  const r=await new sql.Request(tx).input('e',sql.Int,e).input('p',sql.Int,p).input('tipo',sql.VarChar(25),tipo).query(`
    SELECT TOP(1) e.EstudianteId FROM dbo.Estudiante e WITH(HOLDLOCK)
    JOIN dbo.Suscripcion s WITH(HOLDLOCK) ON s.EstudianteId=e.EstudianteId AND s.Estado='VIGENTE'
    JOIN dbo.PeriodoServicio ps WITH(HOLDLOCK) ON ps.SuscripcionId=s.SuscripcionId
    JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId=ps.ModalidadPlanId
    WHERE e.EstudianteId=@e AND e.EtapaActual='CUSTOMER' AND ps.Inicio<=GETDATE() AND ps.Fin>GETDATE()
    AND ps.EstadoAcceso IN('HABILITADO','CON_INCIDENCIA')
    AND EXISTS(SELECT 1 FROM dbo.PersonalInterno WITH(HOLDLOCK) WHERE PersonalInternoId=@p AND Rol=N'DUEÑO' AND Activo=1)
    AND (@tipo<>'SEGUIMIENTO' OR (
      EXISTS(SELECT 1 FROM dbo.PlanPrestacion pp JOIN dbo.Prestacion pr ON pr.PrestacionId=pp.PrestacionId WHERE pp.PlanServicioId=mp.PlanServicioId AND pr.Codigo='SEGUIMIENTO_IA')
      AND EXISTS(SELECT 1 FROM dbo.AutorizacionContacto WITH(HOLDLOCK) WHERE ContactoId=e.ContactoId AND Finalidad='ACADEMICA' AND Autorizado=1 AND FechaDecision<=GETDATE())
    ));`);
  if(!r.recordset.length) throw new Error('Cambió el servicio, plan, autorización o identidad activa.');
}
async function validarSenal(tx:sql.Transaction, estudianteId:number, s:Senal) {
  const fuentes:Record<string,string>={
    EventoUso:'SELECT EstudianteId FROM dbo.EventoUso WITH (HOLDLOCK) WHERE EventoUsoId=@id AND FechaEvento=@fecha',
    CasoAtencion:"SELECT EstudianteId FROM dbo.CasoAtencion WITH (HOLDLOCK) WHERE CasoAtencionId=@id AND FechaAperturaOriginal=@fecha AND Estado<>'RESUELTA' AND Tipo='INCIDENCIA' AND Ambito<>'PAGO'",
    DificultadAcademica:"SELECT EstudianteId FROM dbo.DificultadAcademica WITH (HOLDLOCK) WHERE DificultadAcademicaId=@id AND FechaIdentificacion=@fecha AND Estado<>'SUPERADA'",
    Mensaje:'SELECT c.EstudianteId FROM dbo.Mensaje m WITH (HOLDLOCK) JOIN dbo.Conversacion c ON c.ConversacionId=m.ConversacionId WHERE m.MensajeId=@id AND m.FechaRecepcion=@fecha',
    Valoracion:'SELECT sv.EstudianteId FROM dbo.Valoracion v WITH (HOLDLOCK) JOIN dbo.SolicitudValoracion sv ON sv.SolicitudValoracionId=v.SolicitudValoracionId WHERE v.ValoracionId=@id AND v.FechaRespuesta=@fecha AND v.Valida=1 AND v.Estrellas<=2',
  };
  const query=fuentes[s.fuente];if(!query) throw new Error('Fuente no permitida.');
  const r=await new sql.Request(tx).input('id',sql.Int,s.id).input('fecha',sql.DateTime2(0),s.fecha).query(query);
  if(r.recordset.length!==1||r.recordset[0].EstudianteId!==estudianteId) throw new Error('La evidencia cambió o pertenece a otro estudiante.');
}
async function validarEvaluacion(tx:sql.Transaction,estudianteId:number,evaluacionId:number|null,huella:string,corte:Date) {
  if(evaluacionId===null)return;
  const evalR=await new sql.Request(tx).input('id',sql.Int,evaluacionId).input('e',sql.Int,estudianteId)
    .query('SELECT FechaEvaluacion,Estado,Nivel,Motivo,Origen FROM dbo.EvaluacionRiesgo WITH(HOLDLOCK) WHERE EvaluacionRiesgoId=@id AND EstudianteId=@e');
  const evaluacion=evalR.recordset[0];if(!evaluacion)throw new Error('La evaluación ya no pertenece al estudiante.');
  if(evaluacion.Estado==='CLASIFICADA'&&!vigente(evaluacion.FechaEvaluacion,corte))throw new Error('La evaluación venció. Rechaza la propuesta anterior y solicita una reevaluación.');
  if(evaluacion.Origen==='IA_ACADEMICO') {
    let motivo;try{motivo=JSON.parse(evaluacion.Motivo);}catch{throw new Error('La evaluación no tiene contexto verificable.');}
    if(motivo.huella!==huella)throw new Error('Cambió el contenido de las evidencias. Requiere una propuesta nueva.');
  }
  const r=await new sql.Request(tx).input('id',sql.Int,evaluacionId).query(`SELECT Codigo codigo,Nivel nivel,FechaObservacion fecha,
    CASE WHEN EventoUsoId IS NOT NULL THEN 'EventoUso' WHEN CasoAtencionId IS NOT NULL THEN 'CasoAtencion' WHEN DificultadAcademicaId IS NOT NULL THEN 'DificultadAcademica' WHEN MensajeId IS NOT NULL THEN 'Mensaje' ELSE 'Valoracion' END fuente,
    COALESCE(EventoUsoId,CasoAtencionId,DificultadAcademicaId,MensajeId,ValoracionId) id FROM dbo.SenalRiesgo WITH(HOLDLOCK) WHERE EvaluacionRiesgoId=@id`);
  const senales=r.recordset as Senal[];
  for(const s of senales){
    await validarSenal(tx,estudianteId,s);
    const segundos=(+evaluacion.FechaEvaluacion-+s.fecha)/1000;
    const esperado=s.fuente==='EventoUso'?inactividad(segundos):s.fuente==='CasoAtencion'?incidencia(segundos):s.fuente==='DificultadAcademica'?'MEDIO':'ALTO';
    if(segundos<0||s.nivel!==esperado)throw new Error('Señal contradictoria o posterior al corte de evaluación.');
  }
  const peso={BAJO:0,MEDIO:1,ALTO:2};
  const mayor=senales.reduce((n,s)=>peso[s.nivel]>peso[n]?s.nivel:n,'BAJO' as Senal['nivel']);
  if(evaluacion.Estado==='CLASIFICADA'&&(!senales.length||evaluacion.Nivel!==mayor))throw new Error('La evaluación no coincide con sus señales.');
}

export async function proponer(personalInternoId:number, estudianteId:number, tipo:Tipo, recomendacion:string) {
  const d=await diagnostico(personalInternoId,estudianteId);
  if(!d.ficha.servicioActual||d.ficha.estudiante.etapaActual!=='CUSTOMER') throw new Error('Se requiere servicio CUSTOMER vigente.');
  if(tipo==='SEGUIMIENTO'&&!d.seguimiento.permitido) throw new Error(d.seguimiento.causas.join('; '));
  const key=createHash('sha256').update(JSON.stringify({tipo,nivel:d.riesgo.nivel,fuentes:d.riesgo.senales.map(s=>[s.fuente,s.id,s.nivel])})).digest('hex').slice(0,32);
  const pool=await getPool();const tx=new sql.Transaction(pool);await tx.begin();
  try {
    await bloquear(tx,estudianteId);
    await validarServicio(tx,estudianteId,personalInternoId,tipo);
    const previa=await new sql.Request(tx).input('e',sql.Int,estudianteId).input('tipo',sql.VarChar(25),tipo).input('key',sql.NVarChar(100),`MVP:${key}`).query(`
      SELECT TOP(1) i.IntervencionId id FROM dbo.Intervencion i WITH(UPDLOCK,HOLDLOCK)
      WHERE i.EstudianteId=@e AND i.Tipo=@tipo AND
        (i.Estado IN ('PROPUESTA','PROGRAMADA','EN_CURSO') OR (i.Estado<>'CANCELADA' AND EXISTS(SELECT 1 FROM dbo.EventoIntervencion ev WHERE ev.IntervencionId=i.IntervencionId AND ev.Detalle=@key)))
      ORDER BY i.IntervencionId DESC;`);
    if(previa.recordset[0]) {await tx.commit();return {id:previa.recordset[0].id as number,reutilizada:true};}
    for(const s of d.riesgo.senales) await validarSenal(tx,estudianteId,s);
    const e=await new sql.Request(tx).input('e',sql.Int,estudianteId).input('estado',sql.VarChar(12),d.riesgo.estado).input('nivel',sql.VarChar(5),d.riesgo.nivel)
      .input('motivo',sql.NVarChar(1000),JSON.stringify({corte:d.corte,huella:d.huella,version:d.versionReglas})).input('corte',sql.DateTime2(0),d.corte)
      .query(`INSERT dbo.EvaluacionRiesgo(EstudianteId,FechaEvaluacion,Estado,Nivel,VersionReglas,Motivo,Origen)
        VALUES(@e,@corte,@estado,@nivel,'INFORME_7.1',@motivo,'IA_ACADEMICO'); SELECT CONVERT(INT,SCOPE_IDENTITY()) id;`);
    const evaluacionId=e.recordset[0].id as number;
    for(const s of d.riesgo.senales) {
      const columnas:Record<string,string>={EventoUso:'EventoUsoId',CasoAtencion:'CasoAtencionId',DificultadAcademica:'DificultadAcademicaId',Mensaje:'MensajeId',Valoracion:'ValoracionId'};
      await new sql.Request(tx).input('ev',sql.Int,evaluacionId).input('codigo',sql.VarChar(30),s.codigo).input('nivel',sql.VarChar(5),s.nivel).input('fecha',sql.DateTime2(0),s.fecha)
        .input('id',sql.Int,s.id).input('detalle',sql.NVarChar(800),`${s.codigo}: ${s.fuente} #${s.id}; corte ${d.corte.toISOString()}`)
        .query(`INSERT dbo.SenalRiesgo(EvaluacionRiesgoId,Codigo,Nivel,FechaObservacion,Detalle,${columnas[s.fuente]}) VALUES(@ev,@codigo,@nivel,@fecha,@detalle,@id)`);
    }
    const i=await new sql.Request(tx).input('e',sql.Int,estudianteId).input('ev',sql.Int,evaluacionId).input('tipo',sql.VarChar(25),tipo).input('r',sql.NVarChar(1500),recomendacion)
      .query(`INSERT dbo.Intervencion(EstudianteId,EvaluacionRiesgoId,Tipo,Motivo,Recomendacion,FechaCreacion,RequiereAprobacion,Estado)
        VALUES(@e,@ev,@tipo,N'Propuesta MVP con evidencias; requiere aprobación del dueño',@r,GETDATE(),1,'PROPUESTA'); SELECT CONVERT(INT,SCOPE_IDENTITY()) id;`);
    const id=i.recordset[0].id as number;
    await new sql.Request(tx).input('id',sql.Int,id).input('key',sql.NVarChar(1000),`MVP:${key}`).query("INSERT dbo.EventoIntervencion(IntervencionId,FechaEvento,Estado,Detalle) VALUES(@id,GETDATE(),'PROPUESTA',@key)");
    await tx.commit();return {id,reutilizada:false};
  }catch(error){await tx.rollback().catch(()=>{});throw error;}
}

export async function decidir(personalInternoId:number, estudianteId:number, id:number, accion:'aprobar'|'rechazar'|'simular') {
  const d=await diagnostico(personalInternoId,estudianteId);
  const actual=d.acciones.find(i=>i.id===id);if(!actual) throw new Error('Intervención ajena o inexistente.');
  if(accion!=='rechazar'&&actual.tipo==='SEGUIMIENTO'&&!d.seguimiento.permitido) throw new Error(d.seguimiento.causas.join('; '));
  if(accion!=='rechazar'&&!d.ficha.servicioActual) throw new Error('El servicio ya no está vigente.');
  const tx=new sql.Transaction(await getPool());await tx.begin();
  try {
    await bloquear(tx,estudianteId);
    const locked=await new sql.Request(tx).input('id',sql.Int,id).input('e',sql.Int,estudianteId)
      .query('SELECT Estado,AprobadoPorId,RequiereAprobacion FROM dbo.Intervencion WITH(UPDLOCK,HOLDLOCK) WHERE IntervencionId=@id AND EstudianteId=@e');
    const row=locked.recordset[0];if(!row) throw new Error('Intervención no disponible.');
    if(['COMPLETADA','CANCELADA'].includes(row.Estado)){await tx.commit();return {id,estado:row.Estado,reutilizada:true};}
    if(accion!=='rechazar') await validarServicio(tx,estudianteId,personalInternoId,actual.tipo);
    if(accion!=='rechazar') await validarEvaluacion(tx,estudianteId,actual.evaluacionId,d.huella,d.corte);
    if(accion==='aprobar'&&row.Estado==='PROGRAMADA'&&row.AprobadoPorId){await tx.commit();return {id,estado:row.Estado,reutilizada:true};}
    if(accion==='aprobar'&&row.Estado!=='PROPUESTA') throw new Error('Solo se aprueban propuestas pendientes.');
    if(accion==='simular'&&(!row.AprobadoPorId||!['PROGRAMADA','EN_CURSO'].includes(row.Estado))) throw new Error('El dueño debe aprobar antes de simular.');
    const estado=accion==='aprobar'?'PROGRAMADA':accion==='rechazar'?'CANCELADA':'COMPLETADA';
    const detalle=accion==='simular'?'SIMULACION LOCAL: propuesta revisada. No se envió ni entregó ningún mensaje. No acredita C-4.':accion==='aprobar'?'Aprobada por el dueño; pendiente de simulación.':'Rechazada por el dueño.';
    await new sql.Request(tx).input('id',sql.Int,id).input('p',sql.Int,personalInternoId).input('estado',sql.VarChar(15),estado).input('detalle',sql.NVarChar(1500),detalle)
      .query(`UPDATE dbo.Intervencion SET Estado=@estado,
        AprobadoPorId=CASE WHEN @estado='PROGRAMADA' THEN @p ELSE AprobadoPorId END,
        FechaAprobacion=CASE WHEN @estado='PROGRAMADA' THEN GETDATE() ELSE FechaAprobacion END,
        FechaCompletada=CASE WHEN @estado='COMPLETADA' THEN GETDATE() ELSE NULL END,
        MensajeSeguimientoId=CASE WHEN @estado='COMPLETADA' THEN NULL ELSE MensajeSeguimientoId END,
        Resultado=@detalle WHERE IntervencionId=@id;
        INSERT dbo.EventoIntervencion(IntervencionId,FechaEvento,Estado,Detalle) VALUES(@id,GETDATE(),@estado,@detalle);`);
    await tx.commit();return {id,estado,simulacion:accion==='simular'};
  }catch(error){await tx.rollback().catch(()=>{});throw error;}
}
