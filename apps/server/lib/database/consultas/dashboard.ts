import { CONSULTAR_INDICADORES_MES } from './indicadores.ts';

// Un solo viaje a SQL: resumen visible y evidencias mínimas del riesgo para todos.
// El mismo corte alimenta cumplimiento, señales y los cuatro KPI.
export const CONSULTAR_DASHBOARD = `
SET NOCOUNT ON;
IF NOT EXISTS (
  SELECT 1 FROM dbo.PersonalInterno
  WHERE PersonalInternoId=@owner AND Rol=N'DUEÑO' AND Activo=1
) THROW 51926,N'Acceso del dueño activo requerido',1;

DECLARE @c DATETIME2(0)=GETDATE(), @inicio DATETIME2(0), @totalTemas INT;
SET @inicio=DATEFROMPARTS(YEAR(@c),MONTH(@c),1);
SELECT @totalTemas=COUNT(*) FROM dbo.ContenidoUNT;
SELECT @c corte;

SELECT TOP(1) InactividadMediaHoras,InactividadAltaHoras,IncidenciaMediaHoras,
  IncidenciaAltaHoras,VigenciaDias,MaxEstrellasInsatisfaccion
FROM dbo.PoliticaRiesgo ORDER BY Numero DESC;

;WITH Servicio AS (
  SELECT DISTINCT s.EstudianteId
  FROM dbo.Suscripcion s JOIN dbo.PeriodoServicio p ON p.SuscripcionId=s.SuscripcionId
  WHERE s.Estado='VIGENTE' AND p.Inicio<=@c AND p.Fin>@c
    AND p.EstadoAcceso IN ('HABILITADO','CON_INCIDENCIA')
), Temario AS (
  SELECT p.EstudianteId,COUNT(*) completados
  FROM dbo.ProgresoTemaUNT p JOIN dbo.ContenidoUNT c ON c.ContenidoId=p.ContenidoId
  WHERE p.Estado='COMPLETADA' GROUP BY p.EstudianteId
), Cumplimiento AS (
  SELECT r.EstudianteId,COUNT(*) planificadas,
    SUM(CASE WHEN a.Estado='COMPLETADA' AND a.FechaCompletada<=@c THEN 1 ELSE 0 END) completadas
  FROM dbo.RutaEstudio r JOIN dbo.ActividadRuta a ON a.RutaEstudioId=r.RutaEstudioId
  WHERE r.Vigente=1 AND a.Estado<>'CANCELADA'
    AND a.FechaPlanificada>=DATEADD(DAY,-30,@c) AND a.FechaPlanificada<=@c
  GROUP BY r.EstudianteId
)
SELECT e.EstudianteId id,e.Codigo codigo,c.NombreCompleto nombre,e.EtapaActual etapa,
  CONVERT(BIT,CASE WHEN e.EtapaActual='CUSTOMER' AND s.EstudianteId IS NOT NULL THEN 1 ELSE 0 END) servicioActivo,
  COALESCE(t.completados,0) completados,@totalTemas total,
  COALESCE(a.planificadas,0) planificadas,COALESCE(a.completadas,0) completadas,
  u.EventoUsoId usoId,u.FechaEvento usoFecha
FROM dbo.Estudiante e JOIN dbo.Contacto c ON c.ContactoId=e.ContactoId
LEFT JOIN Servicio s ON s.EstudianteId=e.EstudianteId
LEFT JOIN Temario t ON t.EstudianteId=e.EstudianteId
LEFT JOIN Cumplimiento a ON a.EstudianteId=e.EstudianteId
OUTER APPLY (
  SELECT TOP(1) EventoUsoId,FechaEvento FROM dbo.EventoUso
  WHERE EstudianteId=e.EstudianteId AND FechaEvento<=@c
  ORDER BY FechaEvento DESC,EventoUsoId DESC
) u
ORDER BY e.Codigo;

SELECT EstudianteId estudianteId,CasoAtencionId id,Tipo tipo,Ambito ambito,
  Estado estado,FechaAperturaOriginal apertura
FROM dbo.CasoAtencion WHERE FechaAperturaOriginal<=@c AND Estado<>'RESUELTA';

SELECT EstudianteId estudianteId,DificultadAcademicaId id,FechaIdentificacion fecha,Estado estado
FROM dbo.DificultadAcademica WHERE FechaIdentificacion<=@c AND Estado<>'SUPERADA';

-- Mantener proyección y orden de las narrativas iguales a diagnóstico individual:
-- la huella persistida depende de sus campos y secuencia, sin estudianteId.
SELECT c.EstudianteId estudianteId,m.MensajeId id,m.FechaRecepcion fecha,
  m.Contenido contenido,m.IntencionExpresa intencion
FROM dbo.Mensaje m JOIN dbo.Conversacion c ON c.ConversacionId=m.ConversacionId
WHERE m.Direccion='ENTRANTE' AND m.FechaRecepcion<=@c
ORDER BY c.EstudianteId,m.FechaRecepcion,m.MensajeId;

SELECT s.EstudianteId estudianteId,v.ValoracionId id,v.FechaRespuesta fecha,
  v.Estrellas estrellas,v.Comentario comentario,a.Nombre aspecto
FROM dbo.Valoracion v
JOIN dbo.SolicitudValoracion s ON s.SolicitudValoracionId=v.SolicitudValoracionId
JOIN dbo.AspectoValoracion a ON a.AspectoValoracionId=s.AspectoValoracionId
WHERE v.Valida=1 AND v.FechaRespuesta<=@c
ORDER BY s.EstudianteId,v.ValoracionId;

SELECT * FROM dbo.ConsultaDueno ORDER BY ConsultaId DESC;

${CONSULTAR_INDICADORES_MES}
`;
