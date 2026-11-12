USE [LaPreDigital_Customers];
GRANT SELECT ON dbo.RutaEstudio TO lapredigital_app;
GRANT SELECT ON dbo.ActividadRuta TO lapredigital_app;
GRANT SELECT ON dbo.RecursoAcademico TO lapredigital_app;
GRANT SELECT ON dbo.IntentoEvaluacion TO lapredigital_app;
GRANT SELECT ON dbo.Evaluacion TO lapredigital_app;
GRANT SELECT ON dbo.GrupoComparabilidad TO lapredigital_app;
GRANT SELECT ON dbo.EventoUso TO lapredigital_app;
GRANT SELECT ON dbo.CasoAtencion TO lapredigital_app;
GRANT SELECT ON dbo.DificultadAcademica TO lapredigital_app;
GRANT SELECT ON dbo.RevisionRuta TO lapredigital_app;
GRANT SELECT ON dbo.Mensaje TO lapredigital_app;
GRANT SELECT ON dbo.Conversacion TO lapredigital_app;
GRANT SELECT ON dbo.Valoracion TO lapredigital_app;
GRANT SELECT ON dbo.SolicitudValoracion TO lapredigital_app;
GRANT SELECT ON dbo.AspectoValoracion TO lapredigital_app;
GRANT SELECT ON dbo.AutorizacionContacto TO lapredigital_app;
GRANT SELECT, INSERT ON dbo.EvaluacionRiesgo TO lapredigital_app;
GRANT SELECT, INSERT ON dbo.SenalRiesgo TO lapredigital_app;
GRANT SELECT, INSERT, UPDATE ON dbo.Intervencion TO lapredigital_app;
GRANT SELECT, INSERT ON dbo.EventoIntervencion TO lapredigital_app;
GRANT SELECT, INSERT, UPDATE ON dbo.ProgresoTemaUNT TO lapredigital_app;
GRANT SELECT ON dbo.TemarioUNT TO lapredigital_app;
GRANT SELECT ON dbo.ContenidoUNT TO lapredigital_app;
GRANT SELECT, INSERT, UPDATE ON dbo.MensajeCanalLocal TO lapredigital_app;
GRANT SELECT, INSERT, UPDATE ON dbo.ConsultaDueno TO lapredigital_app;
GRANT INSERT ON dbo.EventoUso TO lapredigital_app;
-- Lectura del ledger para las consultas autenticadas del agente; sin escrituras de pagos.
GRANT SELECT (PagoId,PeriodoServicioId,PagadorContactoId,Tipo,Estado,ImportePEN,Moneda,Canal,FechaOperacion,FechaConfirmacion,PagoOriginalId) ON dbo.Pago TO lapredigital_app;

-- Cohorte mensual de propuestas para C-6.1; lectura sin aplicar cambios de plan.
GRANT SELECT (FechaPresentacion,Estado,FechaRespuesta) ON dbo.PropuestaCambioPlan TO lapredigital_app;
