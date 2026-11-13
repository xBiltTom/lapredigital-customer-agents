USE [LaPreDigital_Customers];
-- Permisos de administración local. Ejecutar con administrador, sin alterar el esquema.
-- Las decisiones de etapa, pagos y acceso permanecen fuera de estos formularios.
GRANT SELECT, INSERT, UPDATE ON dbo.Contacto TO lapredigital_app;
GRANT SELECT, INSERT ON dbo.Apoderado TO lapredigital_app;
GRANT SELECT, INSERT ON dbo.Estudiante TO lapredigital_app;
GRANT UPDATE ON dbo.Estudiante (Codigo, ApoderadoId, Parentesco, UniversidadObjetivo, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras) TO lapredigital_app;
GRANT SELECT ON dbo.Curso TO lapredigital_app;
GRANT SELECT ON dbo.Tema TO lapredigital_app;
GRANT SELECT ON dbo.ContenidoUNT TO lapredigital_app;
GRANT SELECT, INSERT, UPDATE ON dbo.RecursoAcademico TO lapredigital_app;
GRANT SELECT, INSERT ON dbo.RutaEstudio TO lapredigital_app;
GRANT UPDATE ON dbo.RutaEstudio (Vigente) TO lapredigital_app;
GRANT SELECT, INSERT ON dbo.ActividadRuta TO lapredigital_app;
GRANT SELECT, INSERT, UPDATE ON dbo.RevisionRuta TO lapredigital_app;
GRANT SELECT, INSERT, UPDATE ON dbo.CasoAtencion TO lapredigital_app;
GRANT SELECT, INSERT ON dbo.EventoCaso TO lapredigital_app;
GRANT SELECT ON dbo.PlanServicio TO lapredigital_app;
GRANT SELECT ON dbo.ModalidadPlan TO lapredigital_app;
GRANT SELECT, INSERT ON dbo.PoliticaRiesgo TO lapredigital_app;
GRANT SELECT, INSERT, UPDATE ON dbo.AtencionMensaje TO lapredigital_app;
