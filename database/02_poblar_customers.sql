/*
LaPreDigital | Datos FICTICIOS para el MVP OLTP CUSTOMERS | Informe V7.1
REQUISITO: ejecutar primero 01_crear_customers.sql en la MISMA instancia.
El contenedor de SQL Server debe mantener la zona America/Lima; se usa GETDATE().
Ejecutar TODO este archivo en SSMS/Azure Data Studio. No requiere SQLCMD Mode.
La carga es atomica y rechaza una base con datos previos: no borra ni duplica.
Los datos se construyen respecto de @Ahora (hora de Peru) para jugar desde el primer dia.
Las vigencias usan meses calendario mediante DATEADD(MONTH,...).
Si quiere repetir exactamente una fecha, sustituya GETDATE() por
CONVERT(DATETIME2(0),'2026-11-11T10:00:00') (hora de Peru).

Los nombres, mensajes, pagos y autorizaciones son ficticios. Las direcciones
example.com son de demostracion. No hay envio de mensajes ni cobros reales.
La regla de riesgo es la del informe; las evaluaciones insertadas tienen origen
DEMO. La futura aplicacion/agente debe generarlas con evidencia actualizada.
Se incluyen eventos de negocio pasados. Los historiales sencillos registran
los cambios realizados al ejecutar la carga con su fecha real en hora de Peru.

ESCENARIOS (Codigo / Nombre / situacion al cargar)
C001 Ana     : riesgo bajo; 40% -> 55% en evaluaciones comparables (+15 pp).
C002 Bruno   : medio; 96 horas sin uso, dificultad y acompanamiento completado.
C003 Carla   : alto; 192 horas sin uso y valoracion de 2 estrellas.
C004 Diego   : alto; acceso sin resolver desde hace 120 horas; usa recientemente.
C005 Elena   : bajo; renovacion continua, Meta UNT Plus y apoderado vinculado.
C006 Fabio   : bajo; beca completa autorizada; CERO pagos.
C007 Gabriela: CUSTOMER nuevo, sin actividad ni pruebas; riesgo pendiente.
C008 Hugo    : 80 horas sin uso; evaluacion guardada hace 9 dias, ya no vigente.
C009 Ines    : alto; manifiesta no renovar y sigue con acceso hasta vencer.
C010 Jorge   : TURNED desde el vencimiento; no pertenece a la poblacion CUSTOMER.
C011 Lucia   : reactivada despues de una baja; conserva ambos episodios.
C012 Mateo   : cambio aceptado sin aplicar; incidencia reabierta, riesgo alto.
C013 Paula   : LEAD referido que completo formulario; sin pago ni acceso.
C014 Ruben   : Meta UNT semestral; referido fijado al primer pago confirmado.

Al final hay consultas de exploracion (no tablas de hechos ni DataMart).
Las evaluaciones de riesgo envejecen: las consultas usan la hora de ejecucion.
*/
-- Los indices filtrados requieren esta opcion tambien durante INSERT/UPDATE/DELETE.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
USE [LaPreDigital_Customers];
GO
SET NOCOUNT ON;
-- Misma convencion que el script de creacion: fecha y hora local de Peru.
SET XACT_ABORT ON;
DECLARE @Ahora DATETIME2(0) = GETDATE();
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.Contacto) OR EXISTS (SELECT 1 FROM dbo.PlanServicio)
       OR EXISTS (SELECT 1 FROM dbo.PersonalInterno) OR EXISTS (SELECT 1 FROM dbo.Curso)
       OR EXISTS (SELECT 1 FROM dbo.AspectoValoracion) OR EXISTS (SELECT 1 FROM dbo.Prestacion)
       OR EXISTS (SELECT 1 FROM dbo.GrupoComparabilidad)
        THROW 51100, N'La carga necesita la base recien creada y vacia. No se modificaron los datos previos.', 1;

    -- Catalogos y responsables internos. Los planes mantienen precios del informe.
    INSERT dbo.PersonalInterno (Nombre, Rol, Activo)
    VALUES (N'Dueño de demostracion', N'DUEÑO', 1);
    DECLARE @Dueno INT = CONVERT(INT, SCOPE_IDENTITY());
    -- INICIO SEMILLA POLITICA RIESGO
    INSERT dbo.PoliticaRiesgo (
        VersionReglas, Numero, InactividadMediaHoras, InactividadAltaHoras,
        IncidenciaMediaHoras, IncidenciaAltaHoras, VigenciaDias,
        MaxEstrellasInsatisfaccion, CreadaPorId, Motivo
    ) VALUES ('INFORME_7.1', 1, 72, 168, 48, 96, 7, 2, NULL,
              N'Politica inicial del informe 7.1; los cambios posteriores se publican como nuevas versiones.');
    -- FIN SEMILLA POLITICA RIESGO

    INSERT dbo.PersonalInterno (Nombre, Rol, Activo)
    VALUES (N'Soporte academico de demostracion', N'SOPORTE', 1);
    DECLARE @Soporte INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PlanServicio (Codigo, Nombre, Nivel)
    VALUES (N'RUTA_UNT', N'Ruta UNT', 1);
    DECLARE @RUTA_UNT INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PlanServicio (Codigo, Nombre, Nivel)
    VALUES (N'META_UNT', N'Meta UNT', 2);
    DECLARE @META_UNT INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PlanServicio (Codigo, Nombre, Nivel)
    VALUES (N'META_UNT_PLUS', N'Meta UNT Plus', 3);
    DECLARE @META_UNT_PLUS INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ModalidadPlan (PlanServicioId, Meses, PrecioPEN)
    VALUES (@RUTA_UNT, 1, 39.9);
    DECLARE @RutaMes INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ModalidadPlan (PlanServicioId, Meses, PrecioPEN)
    VALUES (@META_UNT, 1, 79.9);
    DECLARE @MetaMes INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ModalidadPlan (PlanServicioId, Meses, PrecioPEN)
    VALUES (@META_UNT, 6, 399.9);
    DECLARE @MetaSem INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ModalidadPlan (PlanServicioId, Meses, PrecioPEN)
    VALUES (@META_UNT_PLUS, 1, 99.9);
    DECLARE @PlusMes INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ModalidadPlan (PlanServicioId, Meses, PrecioPEN)
    VALUES (@META_UNT_PLUS, 6, 499.9);
    DECLARE @PlusSem INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Prestacion (Codigo, Descripcion)
    VALUES (N'MATERIALES', N'Materiales, ejercicios y evaluaciones');
    DECLARE @MATERIALES INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Prestacion (Codigo, Descripcion)
    VALUES (N'RUTA_ESTUDIO', N'Ruta de estudio y revision por el dueno');
    DECLARE @RUTA_ESTUDIO INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Prestacion (Codigo, Descripcion)
    VALUES (N'PERSONALIZACION_ADAPTATIVA', N'Personalizacion adaptativa del aprendizaje');
    DECLARE @PERSONALIZACION_ADAPTATIVA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Prestacion (Codigo, Descripcion)
    VALUES (N'SIMULACROS', N'Simulacros y analisis');
    DECLARE @SIMULACROS INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Prestacion (Codigo, Descripcion)
    VALUES (N'SEGUIMIENTO_IA', N'Seguimiento academico mediante IA');
    DECLARE @SEGUIMIENTO_IA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Prestacion (Codigo, Descripcion)
    VALUES (N'REPORTES_APODERADO', N'Reportes y acceso vinculado para el apoderado');
    DECLARE @REPORTES_APODERADO INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Prestacion (Codigo, Descripcion)
    VALUES (N'ALERTAS_AVANZADAS', N'Alertas avanzadas');
    DECLARE @ALERTAS_AVANZADAS INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Prestacion (Codigo, Descripcion)
    VALUES (N'ATENCION_PRIORITARIA', N'Atencion prioritaria');
    DECLARE @ATENCION_PRIORITARIA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@RUTA_UNT, @MATERIALES);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@RUTA_UNT, @RUTA_ESTUDIO);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT, @MATERIALES);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT, @RUTA_ESTUDIO);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT, @PERSONALIZACION_ADAPTATIVA);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT, @SIMULACROS);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT, @SEGUIMIENTO_IA);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT_PLUS, @MATERIALES);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT_PLUS, @RUTA_ESTUDIO);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT_PLUS, @PERSONALIZACION_ADAPTATIVA);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT_PLUS, @SIMULACROS);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT_PLUS, @SEGUIMIENTO_IA);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT_PLUS, @REPORTES_APODERADO);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT_PLUS, @ALERTAS_AVANZADAS);
    INSERT dbo.PlanPrestacion (PlanServicioId, PrestacionId)
    VALUES (@META_UNT_PLUS, @ATENCION_PRIORITARIA);
    INSERT dbo.AspectoValoracion (Nombre)
    VALUES (N'Contenidos y materiales');
    DECLARE @Contenido INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AspectoValoracion (Nombre)
    VALUES (N'Usabilidad de la plataforma');
    DECLARE @Usabilidad INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AspectoValoracion (Nombre)
    VALUES (N'Acompanamiento academico');
    DECLARE @Acompanamiento INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AspectoValoracion (Nombre)
    VALUES (N'Acceso al servicio');
    DECLARE @Acceso INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Curso (Nombre)
    VALUES (N'Matematica');
    DECLARE @Mat INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Curso (Nombre)
    VALUES (N'Razonamiento verbal');
    DECLARE @Verbal INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Curso (Nombre)
    VALUES (N'Biologia');
    DECLARE @Bio INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Tema (CursoId, Nombre)
    VALUES (@Mat, N'Ecuaciones lineales');
    DECLARE @Algebra INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Tema (CursoId, Nombre)
    VALUES (@Mat, N'Triangulos');
    DECLARE @Geometria INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Tema (CursoId, Nombre)
    VALUES (@Verbal, N'Comprension lectora');
    DECLARE @Lectura INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Tema (CursoId, Nombre)
    VALUES (@Bio, N'La celula');
    DECLARE @Celula INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RecursoAcademico (TemaId, Titulo, Tipo, Ubicacion, DuracionEstimadaMin)
    VALUES (@Algebra, N'Guia de ecuaciones', N'PDF', N'https://example.com/demo/recurso-1', 25);
    DECLARE @Rec1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RecursoAcademico (TemaId, Titulo, Tipo, Ubicacion, DuracionEstimadaMin)
    VALUES (@Algebra, N'Practica de ecuaciones', N'EJERCICIO', N'https://example.com/demo/recurso-2', 25);
    DECLARE @Rec2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RecursoAcademico (TemaId, Titulo, Tipo, Ubicacion, DuracionEstimadaMin)
    VALUES (@Algebra, N'Ecuaciones paso a paso', N'EJEMPLO_RESUELTO', N'https://example.com/demo/recurso-3', 25);
    DECLARE @Rec3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RecursoAcademico (TemaId, Titulo, Tipo, Ubicacion, DuracionEstimadaMin)
    VALUES (@Lectura, N'Estrategias de lectura', N'TEXTO', N'https://example.com/demo/recurso-4', 25);
    DECLARE @Rec4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RecursoAcademico (TemaId, Titulo, Tipo, Ubicacion, DuracionEstimadaMin)
    VALUES (@Celula, N'Estructura celular', N'VIDEO', N'https://example.com/demo/recurso-5', 25);
    DECLARE @Rec5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RecursoAcademico (TemaId, Titulo, Tipo, Ubicacion, DuracionEstimadaMin)
    VALUES (@Geometria, N'Problemas de triangulos resueltos', N'EXAMEN_DESARROLLADO', N'https://example.com/demo/recurso-6', 25);
    DECLARE @Rec6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.GrupoComparabilidad (Codigo, Alcance, Escala, Dificultad, ValidadoPorId)
    VALUES (N'ALG_EQ_BASICO', N'Ecuaciones lineales: mismas competencias y cobertura', N'Porcentaje de aciertos; 20 preguntas', N'Basica equivalente; validada por el dueno', @Dueno);
    DECLARE @GrupoA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.GrupoComparabilidad (Codigo, Alcance, Escala, Dificultad, ValidadoPorId)
    VALUES (N'GEO_INTERMEDIO', N'Geometria: triangulos', N'Porcentaje de aciertos; 20 preguntas', N'Intermedia; NO comparable con algebra basica', @Dueno);
    DECLARE @GrupoB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Evaluacion (Nombre, Tipo, GrupoComparabilidadId, TotalPreguntas)
    VALUES (N'Diagnostico de ecuaciones', N'DIAGNOSTICO', @GrupoA, 20);
    DECLARE @EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Evaluacion (Nombre, Tipo, GrupoComparabilidadId, TotalPreguntas)
    VALUES (N'Evaluacion posterior de ecuaciones', N'EVALUACION', @GrupoA, 20);
    DECLARE @EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Evaluacion (Nombre, Tipo, GrupoComparabilidadId, TotalPreguntas)
    VALUES (N'Evaluacion de geometria', N'EVALUACION', @GrupoB, 20);
    DECLARE @EvalC INT = CONVERT(INT, SCOPE_IDENTITY());

    -- Contactos: relacion familiar y responsable economico no conceden acceso al portal.
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Maria Salas Demo', N'madre@example.com', N'+51900000091', N'FORMULARIO');
    DECLARE @Madre INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@Madre, N'MADRE', DATEADD(HOUR, -2400, @Ahora), N'WHATSAPP', 1);
    DECLARE @FormMadre INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Apoderado (ContactoId)
    VALUES (@Madre);
    DECLARE @ApoMadre INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@Madre, N'EMAIL', N'REPORTES', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa mediante formulario');
    DECLARE @AuthMadre INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Pedro Rios Demo', N'padre@example.com', N'+51900000092', N'FORMULARIO');
    DECLARE @Padre INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@Padre, N'PADRE', DATEADD(HOUR, -2400, @Ahora), N'WHATSAPP', 1);
    DECLARE @FormPadre INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Apoderado (ContactoId)
    VALUES (@Padre);
    DECLARE @ApoPadre INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@Padre, N'EMAIL', N'REPORTES', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa mediante formulario');
    DECLARE @AuthPadre INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Ana Rios Demo', N'estudiante01@example.com', N'+51900000001', N'INSTAGRAM');
    DECLARE @C1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C1, N'ESTUDIANTE', DATEADD(HOUR, -2400, @Ahora), N'INSTAGRAM', 1);
    DECLARE @F1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C001', @C1, @ApoPadre, N'PADRE', N'Ingenieria de Sistemas', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 12, N'LEAD', NULL);
    DECLARE @E1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C1, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C1, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E1, NULL, N'LEAD', DATEADD(HOUR, -2400, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Bruno Vega Demo', N'estudiante02@example.com', N'+51900000002', N'INSTAGRAM');
    DECLARE @C2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C2, N'ESTUDIANTE', DATEADD(HOUR, -2400, @Ahora), N'INSTAGRAM', 1);
    DECLARE @F2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C002', @C2, NULL, NULL, N'Medicina', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 8, N'LEAD', NULL);
    DECLARE @E2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C2, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C2, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E2, NULL, N'LEAD', DATEADD(HOUR, -2400, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Carla Salas Demo', N'estudiante03@example.com', N'+51900000003', N'INSTAGRAM');
    DECLARE @C3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C3, N'ESTUDIANTE', DATEADD(HOUR, -2400, @Ahora), N'INSTAGRAM', 1);
    DECLARE @F3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C003', @C3, @ApoMadre, N'MADRE', N'Ingenieria de Sistemas', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 12, N'LEAD', NULL);
    DECLARE @E3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C3, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C3, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E3, NULL, N'LEAD', DATEADD(HOUR, -2400, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Diego Leon Demo', N'estudiante04@example.com', N'+51900000004', N'INSTAGRAM');
    DECLARE @C4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C4, N'ESTUDIANTE', DATEADD(HOUR, -2400, @Ahora), N'INSTAGRAM', 1);
    DECLARE @F4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C004', @C4, NULL, NULL, N'Medicina', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 8, N'LEAD', NULL);
    DECLARE @E4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C4, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C4, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E4, NULL, N'LEAD', DATEADD(HOUR, -2400, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Elena Salas Demo', N'estudiante05@example.com', N'+51900000005', N'INSTAGRAM');
    DECLARE @C5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C5, N'ESTUDIANTE', DATEADD(HOUR, -2400, @Ahora), N'INSTAGRAM', 1);
    DECLARE @F5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C005', @C5, @ApoMadre, N'MADRE', N'Ingenieria de Sistemas', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 12, N'LEAD', NULL);
    DECLARE @E5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C5, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C5, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E5, NULL, N'LEAD', DATEADD(HOUR, -2400, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Fabio Cruz Demo', N'estudiante06@example.com', N'+51900000006', N'INSTAGRAM');
    DECLARE @C6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C6, N'ESTUDIANTE', DATEADD(HOUR, -2400, @Ahora), N'INSTAGRAM', 1);
    DECLARE @F6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C006', @C6, NULL, NULL, N'Medicina', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 8, N'LEAD', NULL);
    DECLARE @E6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C6, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C6, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E6, NULL, N'LEAD', DATEADD(HOUR, -2400, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Gabriela Ruiz Demo', N'estudiante07@example.com', N'+51900000007', N'INSTAGRAM');
    DECLARE @C7 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C7, N'ESTUDIANTE', DATEADD(HOUR, -2400, @Ahora), N'INSTAGRAM', 1);
    DECLARE @F7 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C007', @C7, NULL, NULL, N'Ingenieria de Sistemas', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 12, N'LEAD', NULL);
    DECLARE @E7 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C7, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth7 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C7, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth7 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E7, NULL, N'LEAD', DATEADD(HOUR, -2400, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta7 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Hugo Perez Demo', N'estudiante08@example.com', N'+51900000008', N'INSTAGRAM');
    DECLARE @C8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C8, N'ESTUDIANTE', DATEADD(HOUR, -2400, @Ahora), N'INSTAGRAM', 1);
    DECLARE @F8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C008', @C8, NULL, NULL, N'Medicina', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 8, N'LEAD', NULL);
    DECLARE @E8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C8, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C8, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E8, NULL, N'LEAD', DATEADD(HOUR, -2400, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Ines Torres Demo', N'estudiante09@example.com', N'+51900000009', N'INSTAGRAM');
    DECLARE @C9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C9, N'ESTUDIANTE', DATEADD(HOUR, -2400, @Ahora), N'INSTAGRAM', 1);
    DECLARE @F9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C009', @C9, NULL, NULL, N'Ingenieria de Sistemas', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 12, N'LEAD', NULL);
    DECLARE @E9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C9, N'WHATSAPP', N'ACADEMICA', 0, DATEADD(HOUR, -2, @Ahora), N'Solicito detener mensajes proactivos; puede escribir a soporte.');
    DECLARE @Auth9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C9, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E9, NULL, N'LEAD', DATEADD(HOUR, -2400, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Jorge Diaz Demo', N'estudiante10@example.com', N'+51900000010', N'INSTAGRAM');
    DECLARE @C10 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C10, N'ESTUDIANTE', DATEADD(HOUR, -2400, @Ahora), N'INSTAGRAM', 1);
    DECLARE @F10 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C010', @C10, NULL, NULL, N'Medicina', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 8, N'LEAD', NULL);
    DECLARE @E10 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C10, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth10 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C10, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth10 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E10, NULL, N'LEAD', DATEADD(HOUR, -2400, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta10 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Lucia Castro Demo', N'estudiante11@example.com', N'+51900000011', N'INSTAGRAM');
    DECLARE @C11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C11, N'ESTUDIANTE', DATEADD(HOUR, -2400, @Ahora), N'INSTAGRAM', 1);
    DECLARE @F11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C011', @C11, NULL, NULL, N'Ingenieria de Sistemas', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 12, N'LEAD', NULL);
    DECLARE @E11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C11, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C11, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E11, NULL, N'LEAD', DATEADD(HOUR, -2400, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Mateo Flores Demo', N'estudiante12@example.com', N'+51900000012', N'INSTAGRAM');
    DECLARE @C12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C12, N'ESTUDIANTE', DATEADD(HOUR, -2400, @Ahora), N'INSTAGRAM', 1);
    DECLARE @F12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C012', @C12, NULL, NULL, N'Medicina', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 8, N'LEAD', NULL);
    DECLARE @E12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C12, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C12, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -2400, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E12, NULL, N'LEAD', DATEADD(HOUR, -2400, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Paula Silva Demo', N'estudiante13@example.com', N'+51900000013', N'REFERIDO');
    DECLARE @C13 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C13, N'ESTUDIANTE', DATEADD(HOUR, -96, @Ahora), N'REFERIDO', 1);
    DECLARE @F13 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C013', @C13, NULL, NULL, N'Ingenieria de Sistemas', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 12, N'LEAD', NULL);
    DECLARE @E13 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C13, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -96, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth13 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C13, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -96, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth13 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E13, NULL, N'LEAD', DATEADD(HOUR, -96, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta13 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Contacto (NombreCompleto, Correo, Telefono, CanalOrigen)
    VALUES (N'Ruben Paredes Demo', N'estudiante14@example.com', N'+51900000014', N'REFERIDO');
    DECLARE @C14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.FormularioContacto (ContactoId, RolDeclarado, FechaEnvio, CanalOrigen, Valido)
    VALUES (@C14, N'ESTUDIANTE', DATEADD(HOUR, -144, @Ahora), N'REFERIDO', 1);
    DECLARE @F14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Estudiante (Codigo, ContactoId, ApoderadoId, Parentesco, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial)
    VALUES (N'C014', @C14, NULL, NULL, N'Medicina', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), 8, N'LEAD', NULL);
    DECLARE @E14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C14, N'WHATSAPP', N'ACADEMICA', 1, DATEADD(HOUR, -144, @Ahora), N'Autorizacion ficticia expresa de seguimiento academico');
    DECLARE @Auth14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.AutorizacionContacto (ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia)
    VALUES (@C14, N'PLATAFORMA', N'ACADEMICA', 1, DATEADD(HOUR, -144, @Ahora), N'Autorizacion ficticia de notificaciones academicas internas');
    DECLARE @AppAuth14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo)
    VALUES (@E14, NULL, N'LEAD', DATEADD(HOUR, -144, @Ahora), N'Formulario valido recibido');
    DECLARE @Alta14 INT = CONVERT(INT, SCOPE_IDENTITY());

    -- Contratacion minima. Primero periodo pendiente, despues pago y habilitacion.
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E1, @Padre, DATEADD(HOUR, -480, @Ahora), 1, NULL, N'VIGENTE');
    DECLARE @S1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S1, @MetaMes, NULL, N'INICIAL', DATEADD(HOUR, -480, @Ahora), DATEADD(MONTH, 1, DATEADD(HOUR, -480, @Ahora)), 79.9, 0, 0, 79.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P1, @Padre, N'DEMO-P1', N'Pasarela ficticia', N'YAPE', N'COBRO', N'CONFIRMADO', 79.9, 0, 1, DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, -480, @Ahora));
    DECLARE @PagoP1 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(HOUR, -480, @Ahora) WHERE PeriodoServicioId = @P1;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E1, N'LEAD', N'PAYER', DATEADD(HOUR, -480, @Ahora), N'Pago inicial positivo confirmado', @S1);
    DECLARE @Trans15 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E1, N'PAYER', N'CUSTOMER', DATEADD(HOUR, -480, @Ahora), N'Acceso habilitado al primer periodo; no requiere renovacion', @S1);
    DECLARE @Trans16 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E1;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E2, @C2, DATEADD(HOUR, -480, @Ahora), 1, NULL, N'VIGENTE');
    DECLARE @S2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S2, @RutaMes, NULL, N'INICIAL', DATEADD(HOUR, -480, @Ahora), DATEADD(MONTH, 1, DATEADD(HOUR, -480, @Ahora)), 39.9, 0, 0, 39.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P2, @C2, N'DEMO-P2', N'Pasarela ficticia', N'TARJETA', N'COBRO', N'CONFIRMADO', 39.9, 0, 1, DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, -480, @Ahora));
    DECLARE @PagoP2 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(HOUR, -480, @Ahora) WHERE PeriodoServicioId = @P2;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E2, N'LEAD', N'PAYER', DATEADD(HOUR, -480, @Ahora), N'Pago inicial positivo confirmado', @S2);
    DECLARE @Trans17 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E2, N'PAYER', N'CUSTOMER', DATEADD(HOUR, -480, @Ahora), N'Acceso habilitado al primer periodo; no requiere renovacion', @S2);
    DECLARE @Trans18 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E2;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E3, @Madre, DATEADD(HOUR, -480, @Ahora), 1, NULL, N'VIGENTE');
    DECLARE @S3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S3, @PlusMes, NULL, N'INICIAL', DATEADD(HOUR, -480, @Ahora), DATEADD(MONTH, 1, DATEADD(HOUR, -480, @Ahora)), 99.9, 0, 0, 99.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P3, @Madre, N'DEMO-P3', N'Pasarela ficticia', N'YAPE', N'COBRO', N'CONFIRMADO', 99.9, 0, 1, DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, -480, @Ahora));
    DECLARE @PagoP3 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(HOUR, -480, @Ahora) WHERE PeriodoServicioId = @P3;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E3, N'LEAD', N'PAYER', DATEADD(HOUR, -480, @Ahora), N'Pago inicial positivo confirmado', @S3);
    DECLARE @Trans19 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E3, N'PAYER', N'CUSTOMER', DATEADD(HOUR, -480, @Ahora), N'Acceso habilitado al primer periodo; no requiere renovacion', @S3);
    DECLARE @Trans20 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E3;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E4, @C4, DATEADD(HOUR, -480, @Ahora), 1, NULL, N'VIGENTE');
    DECLARE @S4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S4, @MetaMes, NULL, N'INICIAL', DATEADD(HOUR, -480, @Ahora), DATEADD(MONTH, 1, DATEADD(HOUR, -480, @Ahora)), 79.9, 0, 0, 79.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P4, @C4, N'DEMO-P4', N'Pasarela ficticia', N'TARJETA', N'COBRO', N'CONFIRMADO', 79.9, 0, 1, DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, -480, @Ahora));
    DECLARE @PagoP4 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(HOUR, -480, @Ahora) WHERE PeriodoServicioId = @P4;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E4, N'LEAD', N'PAYER', DATEADD(HOUR, -480, @Ahora), N'Pago inicial positivo confirmado', @S4);
    DECLARE @Trans21 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E4, N'PAYER', N'CUSTOMER', DATEADD(HOUR, -480, @Ahora), N'Acceso habilitado al primer periodo; no requiere renovacion', @S4);
    DECLARE @Trans22 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E4;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E5, @Madre, DATEADD(MONTH, -1, DATEADD(HOUR, -240, @Ahora)), 1, NULL, N'VIGENTE');
    DECLARE @S5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S5, @PlusMes, NULL, N'INICIAL', DATEADD(MONTH, -1, DATEADD(HOUR, -240, @Ahora)), DATEADD(HOUR, -240, @Ahora), 99.9, 0, 0, 99.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P5, @Madre, N'DEMO-P5', N'Pasarela ficticia', N'YAPE', N'COBRO', N'CONFIRMADO', 99.9, 0, 1, DATEADD(MONTH, -1, DATEADD(HOUR, -240, @Ahora)), DATEADD(MONTH, -1, DATEADD(HOUR, -240, @Ahora)));
    DECLARE @PagoP5 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(MONTH, -1, DATEADD(HOUR, -240, @Ahora)) WHERE PeriodoServicioId = @P5;
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'FINALIZADO' WHERE PeriodoServicioId = @P5;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E5, N'LEAD', N'PAYER', DATEADD(MONTH, -1, DATEADD(HOUR, -240, @Ahora)), N'Pago inicial positivo confirmado', @S5);
    DECLARE @Trans23 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E5, N'PAYER', N'CUSTOMER', DATEADD(MONTH, -1, DATEADD(HOUR, -240, @Ahora)), N'Acceso habilitado al primer periodo; no requiere renovacion', @S5);
    DECLARE @Trans24 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E5;
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S5, @PlusMes, @P5, N'RENOVACION', DATEADD(HOUR, -240, @Ahora), DATEADD(MONTH, 1, DATEADD(HOUR, -240, @Ahora)), 99.9, 0, 0, 99.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P5Ren INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P5Ren, @Madre, N'DEMO-P5Ren', N'Pasarela ficticia', N'YAPE', N'COBRO', N'CONFIRMADO', 99.9, 0, 1, DATEADD(HOUR, -240, @Ahora), DATEADD(HOUR, -240, @Ahora));
    DECLARE @PagoP5Ren INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(HOUR, -240, @Ahora) WHERE PeriodoServicioId = @P5Ren;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E6, @C6, DATEADD(HOUR, -480, @Ahora), 0, NULL, N'VIGENTE');
    DECLARE @S6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S6, @MetaMes, NULL, N'INICIAL', DATEADD(HOUR, -480, @Ahora), DATEADD(MONTH, 1, DATEADD(HOUR, -480, @Ahora)), 79.9, 100, 0, 0, @Dueno, DATEADD(HOUR, -481, @Ahora), N'Plan y periodo aceptados; sin cuotas. Beca completa autorizada.', N'PENDIENTE');
    DECLARE @P6 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(HOUR, -480, @Ahora) WHERE PeriodoServicioId = @P6;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E6, N'LEAD', N'CUSTOMER', DATEADD(HOUR, -480, @Ahora), N'Habilitacion por beca completa autorizada', @S6);
    DECLARE @Trans25 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E6;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E7, @C7, DATEADD(HOUR, -1, @Ahora), 1, NULL, N'VIGENTE');
    DECLARE @S7 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S7, @RutaMes, NULL, N'INICIAL', DATEADD(HOUR, -1, @Ahora), DATEADD(MONTH, 1, DATEADD(HOUR, -1, @Ahora)), 39.9, 0, 0, 39.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P7 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P7, @C7, N'DEMO-P7', N'Pasarela ficticia', N'YAPE', N'COBRO', N'CONFIRMADO', 39.9, 0, 1, DATEADD(HOUR, -1, @Ahora), DATEADD(HOUR, -1, @Ahora));
    DECLARE @PagoP7 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(HOUR, -1, @Ahora) WHERE PeriodoServicioId = @P7;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E7, N'LEAD', N'PAYER', DATEADD(HOUR, -1, @Ahora), N'Pago inicial positivo confirmado', @S7);
    DECLARE @Trans26 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E7, N'PAYER', N'CUSTOMER', DATEADD(HOUR, -1, @Ahora), N'Acceso habilitado al primer periodo; no requiere renovacion', @S7);
    DECLARE @Trans27 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E7;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E8, @C8, DATEADD(HOUR, -480, @Ahora), 1, NULL, N'VIGENTE');
    DECLARE @S8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S8, @MetaMes, NULL, N'INICIAL', DATEADD(HOUR, -480, @Ahora), DATEADD(MONTH, 1, DATEADD(HOUR, -480, @Ahora)), 79.9, 0, 0, 79.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P8, @C8, N'DEMO-P8', N'Pasarela ficticia', N'TARJETA', N'COBRO', N'CONFIRMADO', 79.9, 0, 1, DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, -480, @Ahora));
    DECLARE @PagoP8 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(HOUR, -480, @Ahora) WHERE PeriodoServicioId = @P8;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E8, N'LEAD', N'PAYER', DATEADD(HOUR, -480, @Ahora), N'Pago inicial positivo confirmado', @S8);
    DECLARE @Trans28 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E8, N'PAYER', N'CUSTOMER', DATEADD(HOUR, -480, @Ahora), N'Acceso habilitado al primer periodo; no requiere renovacion', @S8);
    DECLARE @Trans29 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E8;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E9, @C9, DATEADD(HOUR, -480, @Ahora), 0, DATEADD(HOUR, -2, @Ahora), N'VIGENTE');
    DECLARE @S9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S9, @PlusMes, NULL, N'INICIAL', DATEADD(HOUR, -480, @Ahora), DATEADD(MONTH, 1, DATEADD(HOUR, -480, @Ahora)), 99.9, 0, 0, 99.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P9, @C9, N'DEMO-P9', N'Pasarela ficticia', N'YAPE', N'COBRO', N'CONFIRMADO', 99.9, 0, 1, DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, -480, @Ahora));
    DECLARE @PagoP9 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(HOUR, -480, @Ahora) WHERE PeriodoServicioId = @P9;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E9, N'LEAD', N'PAYER', DATEADD(HOUR, -480, @Ahora), N'Pago inicial positivo confirmado', @S9);
    DECLARE @Trans30 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E9, N'PAYER', N'CUSTOMER', DATEADD(HOUR, -480, @Ahora), N'Acceso habilitado al primer periodo; no requiere renovacion', @S9);
    DECLARE @Trans31 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E9;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E10, @C10, DATEADD(MONTH, -1, DATEADD(HOUR, -24, @Ahora)), 0, NULL, N'VIGENTE');
    DECLARE @S10 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S10, @RutaMes, NULL, N'INICIAL', DATEADD(MONTH, -1, DATEADD(HOUR, -24, @Ahora)), DATEADD(HOUR, -24, @Ahora), 39.9, 0, 0, 39.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P10 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P10, @C10, N'DEMO-P10', N'Pasarela ficticia', N'TARJETA', N'COBRO', N'CONFIRMADO', 39.9, 0, 1, DATEADD(MONTH, -1, DATEADD(HOUR, -24, @Ahora)), DATEADD(MONTH, -1, DATEADD(HOUR, -24, @Ahora)));
    DECLARE @PagoP10 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(MONTH, -1, DATEADD(HOUR, -24, @Ahora)) WHERE PeriodoServicioId = @P10;
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'FINALIZADO' WHERE PeriodoServicioId = @P10;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E10, N'LEAD', N'PAYER', DATEADD(MONTH, -1, DATEADD(HOUR, -24, @Ahora)), N'Pago inicial positivo confirmado', @S10);
    DECLARE @Trans32 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E10, N'PAYER', N'CUSTOMER', DATEADD(MONTH, -1, DATEADD(HOUR, -24, @Ahora)), N'Acceso habilitado al primer periodo; no requiere renovacion', @S10);
    DECLARE @Trans33 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E10;
    INSERT dbo.BajaServicio (PeriodoServicioId, FechaBaja, Tipo, MotivoComunicado, FechaMotivo, ElegibleReactivacion)
    VALUES (@P10, DATEADD(HOUR, -24, @Ahora), N'VENCIMIENTO', N'Ingreso a la universidad; ya no necesita preparacion', DATEADD(HOUR, -24, @Ahora), 0);
    DECLARE @Baja10 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E10, N'CUSTOMER', N'TURNED', DATEADD(HOUR, -24, @Ahora), N'Fin del periodo sin renovacion, sin tolerancia adicional', @S10);
    DECLARE @Trans34 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'TURNED' WHERE EstudianteId = @E10;
    UPDATE dbo.Suscripcion SET Estado = N'FINALIZADA' WHERE SuscripcionId = @S10;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E11, @C11, DATEADD(MONTH, -1, DATEADD(HOUR, -360, @Ahora)), 0, NULL, N'VIGENTE');
    DECLARE @S11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S11, @RutaMes, NULL, N'INICIAL', DATEADD(MONTH, -1, DATEADD(HOUR, -360, @Ahora)), DATEADD(HOUR, -360, @Ahora), 39.9, 0, 0, 39.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P11, @C11, N'DEMO-P11', N'Pasarela ficticia', N'YAPE', N'COBRO', N'CONFIRMADO', 39.9, 0, 1, DATEADD(MONTH, -1, DATEADD(HOUR, -360, @Ahora)), DATEADD(MONTH, -1, DATEADD(HOUR, -360, @Ahora)));
    DECLARE @PagoP11 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(MONTH, -1, DATEADD(HOUR, -360, @Ahora)) WHERE PeriodoServicioId = @P11;
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'FINALIZADO' WHERE PeriodoServicioId = @P11;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E11, N'LEAD', N'PAYER', DATEADD(MONTH, -1, DATEADD(HOUR, -360, @Ahora)), N'Pago inicial positivo confirmado', @S11);
    DECLARE @Trans35 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E11, N'PAYER', N'CUSTOMER', DATEADD(MONTH, -1, DATEADD(HOUR, -360, @Ahora)), N'Acceso habilitado al primer periodo; no requiere renovacion', @S11);
    DECLARE @Trans36 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E11;
    INSERT dbo.BajaServicio (PeriodoServicioId, FechaBaja, Tipo, MotivoComunicado, FechaMotivo, ElegibleReactivacion)
    VALUES (@P11, DATEADD(HOUR, -360, @Ahora), N'VENCIMIENTO', N'Interrumpio temporalmente por disponibilidad', DATEADD(HOUR, -360, @Ahora), 1);
    DECLARE @Baja11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E11, N'CUSTOMER', N'TURNED', DATEADD(HOUR, -360, @Ahora), N'Fin del periodo sin renovacion, sin tolerancia adicional', @S11);
    DECLARE @Trans37 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'TURNED' WHERE EstudianteId = @E11;
    UPDATE dbo.Suscripcion SET Estado = N'FINALIZADA' WHERE SuscripcionId = @S11;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, Estado)
    VALUES (@E11, @C11, DATEADD(HOUR, -48, @Ahora), 1, N'VIGENTE');
    DECLARE @S11Nueva INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S11Nueva, @RutaMes, NULL, N'REACTIVACION', DATEADD(HOUR, -48, @Ahora), DATEADD(MONTH, 1, DATEADD(HOUR, -48, @Ahora)), 39.9, 0, 0, 39.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P11Nueva INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P11Nueva, @C11, N'DEMO-P11Nueva', N'Pasarela ficticia', N'YAPE', N'COBRO', N'CONFIRMADO', 39.9, 0, 1, DATEADD(HOUR, -48, @Ahora), DATEADD(HOUR, -48, @Ahora));
    DECLARE @PagoP11Nueva INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(HOUR, -48, @Ahora) WHERE PeriodoServicioId = @P11Nueva;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E11, N'TURNED', N'PAYER', DATEADD(HOUR, -48, @Ahora), N'Nuevo pago confirmado posterior a la baja', @S11Nueva);
    DECLARE @Trans38 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E11, N'PAYER', N'CUSTOMER', DATEADD(HOUR, -48, @Ahora), N'Acceso reactivado inmediatamente', @S11Nueva);
    DECLARE @Trans39 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E11;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E12, @C12, DATEADD(HOUR, -480, @Ahora), 1, NULL, N'VIGENTE');
    DECLARE @S12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S12, @RutaMes, NULL, N'INICIAL', DATEADD(HOUR, -480, @Ahora), DATEADD(MONTH, 1, DATEADD(HOUR, -480, @Ahora)), 39.9, 0, 0, 39.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P12, @C12, N'DEMO-P12', N'Pasarela ficticia', N'TARJETA', N'COBRO', N'CONFIRMADO', 39.9, 0, 1, DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, -480, @Ahora));
    DECLARE @PagoP12 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(HOUR, -480, @Ahora) WHERE PeriodoServicioId = @P12;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E12, N'LEAD', N'PAYER', DATEADD(HOUR, -480, @Ahora), N'Pago inicial positivo confirmado', @S12);
    DECLARE @Trans40 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E12, N'PAYER', N'CUSTOMER', DATEADD(HOUR, -480, @Ahora), N'Acceso habilitado al primer periodo; no requiere renovacion', @S12);
    DECLARE @Trans41 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E12;
    INSERT dbo.Suscripcion (EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado)
    VALUES (@E14, @C14, DATEADD(HOUR, -120, @Ahora), 1, NULL, N'VIGENTE');
    DECLARE @S14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PeriodoServicio (SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, EstadoAcceso)
    VALUES (@S14, @MetaSem, NULL, N'INICIAL', DATEADD(HOUR, -120, @Ahora), DATEADD(MONTH, 6, DATEADD(HOUR, -120, @Ahora)), 399.9, 0, 0, 399.9, NULL, NULL, N'Plan y periodo aceptados; cobro por periodo completo, sin cuotas.', N'PENDIENTE');
    DECLARE @P14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Pago (PeriodoServicioId, PagadorContactoId, CodigoOperacion, Proveedor, Canal, Tipo, Estado, ImportePEN, ImpuestosPEN, ComisionPEN, FechaOperacion, FechaConfirmacion)
    VALUES (@P14, @C14, N'DEMO-P14', N'Pasarela ficticia', N'TARJETA', N'COBRO', N'CONFIRMADO', 399.9, 0, 1, DATEADD(HOUR, -120, @Ahora), DATEADD(HOUR, -120, @Ahora));
    DECLARE @PagoP14 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.PeriodoServicio SET EstadoAcceso = N'HABILITADO', FechaHabilitacion = DATEADD(HOUR, -120, @Ahora) WHERE PeriodoServicioId = @P14;
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E14, N'LEAD', N'PAYER', DATEADD(HOUR, -120, @Ahora), N'Pago inicial positivo confirmado', @S14);
    DECLARE @Trans42 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CambioEtapa (EstudianteId, EtapaOrigen, EtapaDestino, FechaCambio, Motivo, SuscripcionId)
    VALUES (@E14, N'PAYER', N'CUSTOMER', DATEADD(HOUR, -120, @Ahora), N'Acceso habilitado al primer periodo; no requiere renovacion', @S14);
    DECLARE @Trans43 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET EtapaActual = N'CUSTOMER' WHERE EstudianteId = @E14;
    UPDATE dbo.Estudiante SET DisponibilidadSemanalHoras = 14 WHERE EstudianteId = @E1;

    -- Rutas aprobadas por el dueno. Gabriela tiene ruta pero ninguna actividad planificada.
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E1, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, 2400, @Ahora), 1, @Dueno, DATEADD(HOUR, -480, @Ahora));
    DECLARE @R1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R1, @Rec1, 1, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -168, @Ahora));
    DECLARE @A1_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R1, @Rec2, 2, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -156, @Ahora));
    DECLARE @A1_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R1, @Rec3, 3, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -144, @Ahora));
    DECLARE @A1_3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R1, @Rec4, 4, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -132, @Ahora));
    DECLARE @A1_4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R1, @Rec5, 5, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'COMPLETADA', DATEADD(HOUR, -120, @Ahora));
    DECLARE @A1_5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R1, @Rec6, 6, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'EN_CURSO', NULL);
    DECLARE @A1_6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E2, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, 2400, @Ahora), 1, @Dueno, DATEADD(HOUR, -480, @Ahora));
    DECLARE @R2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R2, @Rec1, 1, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -144, @Ahora));
    DECLARE @A2_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R2, @Rec2, 2, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -138, @Ahora));
    DECLARE @A2_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R2, @Rec3, 3, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -132, @Ahora));
    DECLARE @A2_3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R2, @Rec4, 4, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'EN_CURSO', NULL);
    DECLARE @A2_4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R2, @Rec5, 5, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A2_5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R2, @Rec6, 6, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A2_6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E3, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, 2400, @Ahora), 1, @Dueno, DATEADD(HOUR, -480, @Ahora));
    DECLARE @R3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R3, @Rec1, 1, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -294, @Ahora));
    DECLARE @A3_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R3, @Rec2, 2, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'EN_CURSO', NULL);
    DECLARE @A3_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R3, @Rec3, 3, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A3_3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R3, @Rec4, 4, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A3_4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R3, @Rec5, 5, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A3_5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R3, @Rec6, 6, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A3_6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E4, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, 2400, @Ahora), 1, @Dueno, DATEADD(HOUR, -480, @Ahora));
    DECLARE @R4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R4, @Rec1, 1, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -168, @Ahora));
    DECLARE @A4_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R4, @Rec2, 2, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -156, @Ahora));
    DECLARE @A4_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R4, @Rec3, 3, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -144, @Ahora));
    DECLARE @A4_3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R4, @Rec4, 4, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'EN_CURSO', NULL);
    DECLARE @A4_4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R4, @Rec5, 5, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A4_5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R4, @Rec6, 6, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A4_6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E5, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, 2400, @Ahora), 1, @Dueno, DATEADD(HOUR, -480, @Ahora));
    DECLARE @R5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R5, @Rec1, 1, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -168, @Ahora));
    DECLARE @A5_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R5, @Rec2, 2, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -156, @Ahora));
    DECLARE @A5_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R5, @Rec3, 3, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -144, @Ahora));
    DECLARE @A5_3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R5, @Rec4, 4, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -132, @Ahora));
    DECLARE @A5_4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R5, @Rec5, 5, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'COMPLETADA', DATEADD(HOUR, -120, @Ahora));
    DECLARE @A5_5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R5, @Rec6, 6, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'EN_CURSO', NULL);
    DECLARE @A5_6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E6, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, 2400, @Ahora), 1, @Dueno, DATEADD(HOUR, -480, @Ahora));
    DECLARE @R6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R6, @Rec1, 1, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -168, @Ahora));
    DECLARE @A6_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R6, @Rec2, 2, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -156, @Ahora));
    DECLARE @A6_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R6, @Rec3, 3, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -144, @Ahora));
    DECLARE @A6_3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R6, @Rec4, 4, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -132, @Ahora));
    DECLARE @A6_4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R6, @Rec5, 5, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'COMPLETADA', DATEADD(HOUR, -120, @Ahora));
    DECLARE @A6_5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R6, @Rec6, 6, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'EN_CURSO', NULL);
    DECLARE @A6_6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E7, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -1, @Ahora), DATEADD(HOUR, 2400, @Ahora), 1, @Dueno, DATEADD(HOUR, -1, @Ahora));
    DECLARE @R7 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E8, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, 2400, @Ahora), 1, @Dueno, DATEADD(HOUR, -480, @Ahora));
    DECLARE @R8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R8, @Rec1, 1, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -124, @Ahora));
    DECLARE @A8_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R8, @Rec2, 2, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'EN_CURSO', NULL);
    DECLARE @A8_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R8, @Rec3, 3, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A8_3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R8, @Rec4, 4, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A8_4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R8, @Rec5, 5, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A8_5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R8, @Rec6, 6, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A8_6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E9, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, 2400, @Ahora), 1, @Dueno, DATEADD(HOUR, -480, @Ahora));
    DECLARE @R9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R9, @Rec1, 1, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -168, @Ahora));
    DECLARE @A9_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R9, @Rec2, 2, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'EN_CURSO', NULL);
    DECLARE @A9_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R9, @Rec3, 3, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A9_3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R9, @Rec4, 4, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A9_4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R9, @Rec5, 5, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A9_5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R9, @Rec6, 6, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A9_6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E10, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, 2400, @Ahora), 0, @Dueno, DATEADD(HOUR, -480, @Ahora));
    DECLARE @R10 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R10, @Rec1, 1, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -168, @Ahora));
    DECLARE @A10_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R10, @Rec2, 2, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -156, @Ahora));
    DECLARE @A10_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R10, @Rec3, 3, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -144, @Ahora));
    DECLARE @A10_3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R10, @Rec4, 4, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'EN_CURSO', NULL);
    DECLARE @A10_4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R10, @Rec5, 5, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A10_5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R10, @Rec6, 6, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A10_6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E11, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, 2400, @Ahora), 1, @Dueno, DATEADD(HOUR, -480, @Ahora));
    DECLARE @R11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R11, @Rec1, 1, DATEADD(HOUR, -45, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -38, @Ahora));
    DECLARE @A11_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R11, @Rec2, 2, DATEADD(HOUR, -45, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -32, @Ahora));
    DECLARE @A11_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R11, @Rec3, 3, DATEADD(HOUR, -45, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -26, @Ahora));
    DECLARE @A11_3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R11, @Rec4, 4, DATEADD(HOUR, -45, @Ahora), DATEADD(HOUR, -24, @Ahora), N'EN_CURSO', NULL);
    DECLARE @A11_4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R11, @Rec5, 5, DATEADD(HOUR, -45, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A11_5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R11, @Rec6, 6, DATEADD(HOUR, -45, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A11_6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E12, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -480, @Ahora), DATEADD(HOUR, 2400, @Ahora), 1, @Dueno, DATEADD(HOUR, -480, @Ahora));
    DECLARE @R12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R12, @Rec1, 1, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -168, @Ahora));
    DECLARE @A12_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R12, @Rec2, 2, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -156, @Ahora));
    DECLARE @A12_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R12, @Rec3, 3, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -144, @Ahora));
    DECLARE @A12_3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R12, @Rec4, 4, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, -24, @Ahora), N'EN_CURSO', NULL);
    DECLARE @A12_4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R12, @Rec5, 5, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A12_5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R12, @Rec6, 6, DATEADD(HOUR, -360, @Ahora), DATEADD(HOUR, 48, @Ahora), N'PENDIENTE', NULL);
    DECLARE @A12_6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E14, 1, N'Preparacion para admision UNT con refuerzo de ecuaciones y lectura', CONVERT(DATE, DATEADD(DAY, 100, @Ahora)), DATEADD(HOUR, -120, @Ahora), DATEADD(HOUR, 2400, @Ahora), 1, @Dueno, DATEADD(HOUR, -120, @Ahora));
    DECLARE @R14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R14, @Rec1, 1, DATEADD(HOUR, -110, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -92, @Ahora));
    DECLARE @A14_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R14, @Rec2, 2, DATEADD(HOUR, -110, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -84, @Ahora));
    DECLARE @A14_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R14, @Rec3, 3, DATEADD(HOUR, -110, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -76, @Ahora));
    DECLARE @A14_3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R14, @Rec4, 4, DATEADD(HOUR, -110, @Ahora), DATEADD(HOUR, -24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -68, @Ahora));
    DECLARE @A14_4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R14, @Rec5, 5, DATEADD(HOUR, -110, @Ahora), DATEADD(HOUR, 48, @Ahora), N'COMPLETADA', DATEADD(HOUR, -60, @Ahora));
    DECLARE @A14_5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R14, @Rec6, 6, DATEADD(HOUR, -110, @Ahora), DATEADD(HOUR, 48, @Ahora), N'EN_CURSO', NULL);
    DECLARE @A14_6 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.RutaEstudio SET Vigente = 0 WHERE RutaEstudioId = @R1;
    INSERT dbo.RutaEstudio (EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion)
    VALUES (@E1, 2, N'Ajuste de preparacion por nueva fecha del examen', CONVERT(DATE, DATEADD(DAY, 90, @Ahora)), DATEADD(HOUR, -12, @Ahora), DATEADD(HOUR, 2160, @Ahora), 1, @Dueno, DATEADD(HOUR, -12, @Ahora));
    DECLARE @R1Nueva INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R1Nueva, @Rec1, 1, DATEADD(HOUR, -12, @Ahora), DATEADD(HOUR, 24, @Ahora), N'COMPLETADA', DATEADD(HOUR, -6, @Ahora));
    DECLARE @ANueva1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.ActividadRuta (RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada)
    VALUES (@R1Nueva, @Rec2, 2, DATEADD(HOUR, -12, @Ahora), DATEADD(HOUR, 24, @Ahora), N'PENDIENTE', NULL);
    DECLARE @ANueva2 INT = CONVERT(INT, SCOPE_IDENTITY());
    UPDATE dbo.Estudiante SET FechaExamen = CONVERT(DATE, DATEADD(DAY, 90, @Ahora)) WHERE EstudianteId = @E1;
    INSERT dbo.DificultadAcademica (EstudianteId, TemaId, Descripcion, Origen, FechaIdentificacion, Estado)
    VALUES (@E2, @Algebra, N'Comunica dificultad para despejar variables y resolver ecuaciones', N'ESTUDIANTE', DATEADD(HOUR, -300, @Ahora), N'EN_SEGUIMIENTO');
    DECLARE @Dif2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.DificultadAcademica (EstudianteId, TemaId, Descripcion, Origen, FechaIdentificacion, Estado)
    VALUES (@E3, @Algebra, N'Comunica dificultad para despejar variables y resolver ecuaciones', N'ESTUDIANTE', DATEADD(HOUR, -300, @Ahora), N'EN_SEGUIMIENTO');
    DECLARE @Dif3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.DificultadAcademica (EstudianteId, TemaId, Descripcion, Origen, FechaIdentificacion, Estado)
    VALUES (@E8, @Algebra, N'Comunica dificultad para despejar variables y resolver ecuaciones', N'ESTUDIANTE', DATEADD(HOUR, -300, @Ahora), N'EN_SEGUIMIENTO');
    DECLARE @Dif8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RevisionRuta (RutaEstudioId, Motivo, FechaIdentificacion, Recomendacion, Estado, RevisadaPorId, FechaRevision, Resultado, RutaResultanteId)
    VALUES (@R1, N'CAMBIO_FECHA_EXAMEN', DATEADD(HOUR, -36, @Ahora), N'Reorganizar actividades para la nueva fecha', N'REVISADA', @Dueno, DATEADD(HOUR, -12, @Ahora), N'Dueno aprobo y publico version 2', @R1Nueva);
    DECLARE @Rev1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RevisionRuta (RutaEstudioId, Motivo, FechaIdentificacion, Recomendacion, Estado)
    VALUES (@R2, N'DIFICULTAD_ACADEMICA', DATEADD(HOUR, -300, @Ahora), N'Revisar refuerzo de ecuaciones con el dueno', N'PENDIENTE');
    DECLARE @Rev2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RevisionRuta (RutaEstudioId, Motivo, FechaIdentificacion, Recomendacion, Estado)
    VALUES (@R3, N'DIFICULTAD_ACADEMICA', DATEADD(HOUR, -300, @Ahora), N'Revisar refuerzo de ecuaciones con el dueno', N'PENDIENTE');
    DECLARE @Rev3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.RevisionRuta (RutaEstudioId, Motivo, FechaIdentificacion, Recomendacion, Estado)
    VALUES (@R8, N'DIFICULTAD_ACADEMICA', DATEADD(HOUR, -300, @Ahora), N'Revisar refuerzo de ecuaciones con el dueno', N'PENDIENTE');
    DECLARE @Rev8 INT = CONVERT(INT, SCOPE_IDENTITY());

    -- Pruebas comparables y no comparables; aciertos sin promedios precalculados.
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E1, @EvalA, DATEADD(HOUR, -401, @Ahora), DATEADD(HOUR, -400, @Ahora), 20, 8);
    DECLARE @Int1_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E1, N'EVALUACION', DATEADD(HOUR, -400, @Ahora), 1800);
    DECLARE @UPrueba1_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E1, @EvalB, DATEADD(HOUR, -241, @Ahora), DATEADD(HOUR, -240, @Ahora), 20, 11);
    DECLARE @Int1_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E1, N'EVALUACION', DATEADD(HOUR, -240, @Ahora), 1800);
    DECLARE @UPrueba1_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E2, @EvalA, DATEADD(HOUR, -401, @Ahora), DATEADD(HOUR, -400, @Ahora), 20, 8);
    DECLARE @Int2_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E2, N'EVALUACION', DATEADD(HOUR, -400, @Ahora), 1800);
    DECLARE @UPrueba2_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E2, @EvalB, DATEADD(HOUR, -241, @Ahora), DATEADD(HOUR, -240, @Ahora), 20, 11);
    DECLARE @Int2_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E2, N'EVALUACION', DATEADD(HOUR, -240, @Ahora), 1800);
    DECLARE @UPrueba2_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E3, @EvalA, DATEADD(HOUR, -401, @Ahora), DATEADD(HOUR, -400, @Ahora), 20, 12);
    DECLARE @Int3_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E3, N'EVALUACION', DATEADD(HOUR, -400, @Ahora), 1800);
    DECLARE @UPrueba3_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E3, @EvalB, DATEADD(HOUR, -241, @Ahora), DATEADD(HOUR, -240, @Ahora), 20, 7);
    DECLARE @Int3_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E3, N'EVALUACION', DATEADD(HOUR, -240, @Ahora), 1800);
    DECLARE @UPrueba3_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E4, @EvalA, DATEADD(HOUR, -401, @Ahora), DATEADD(HOUR, -400, @Ahora), 20, 8);
    DECLARE @Int4_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E4, N'EVALUACION', DATEADD(HOUR, -400, @Ahora), 1800);
    DECLARE @UPrueba4_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E4, @EvalC, DATEADD(HOUR, -241, @Ahora), DATEADD(HOUR, -240, @Ahora), 20, 11);
    DECLARE @Int4_EvalC INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E4, N'EVALUACION', DATEADD(HOUR, -240, @Ahora), 1800);
    DECLARE @UPrueba4_EvalC INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E5, @EvalA, DATEADD(HOUR, -401, @Ahora), DATEADD(HOUR, -400, @Ahora), 20, 8);
    DECLARE @Int5_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E5, N'EVALUACION', DATEADD(HOUR, -400, @Ahora), 1800);
    DECLARE @UPrueba5_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E5, @EvalB, DATEADD(HOUR, -241, @Ahora), DATEADD(HOUR, -240, @Ahora), 20, 11);
    DECLARE @Int5_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E5, N'EVALUACION', DATEADD(HOUR, -240, @Ahora), 1800);
    DECLARE @UPrueba5_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E6, @EvalA, DATEADD(HOUR, -401, @Ahora), DATEADD(HOUR, -400, @Ahora), 20, 8);
    DECLARE @Int6_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E6, N'EVALUACION', DATEADD(HOUR, -400, @Ahora), 1800);
    DECLARE @UPrueba6_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E6, @EvalB, DATEADD(HOUR, -241, @Ahora), DATEADD(HOUR, -240, @Ahora), 20, 11);
    DECLARE @Int6_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E6, N'EVALUACION', DATEADD(HOUR, -240, @Ahora), 1800);
    DECLARE @UPrueba6_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E8, @EvalA, DATEADD(HOUR, -401, @Ahora), DATEADD(HOUR, -400, @Ahora), 20, 8);
    DECLARE @Int8_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E8, N'EVALUACION', DATEADD(HOUR, -400, @Ahora), 1800);
    DECLARE @UPrueba8_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E8, @EvalB, DATEADD(HOUR, -241, @Ahora), DATEADD(HOUR, -240, @Ahora), 20, 11);
    DECLARE @Int8_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E8, N'EVALUACION', DATEADD(HOUR, -240, @Ahora), 1800);
    DECLARE @UPrueba8_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E9, @EvalA, DATEADD(HOUR, -401, @Ahora), DATEADD(HOUR, -400, @Ahora), 20, 8);
    DECLARE @Int9_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E9, N'EVALUACION', DATEADD(HOUR, -400, @Ahora), 1800);
    DECLARE @UPrueba9_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E9, @EvalB, DATEADD(HOUR, -241, @Ahora), DATEADD(HOUR, -240, @Ahora), 20, 11);
    DECLARE @Int9_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E9, N'EVALUACION', DATEADD(HOUR, -240, @Ahora), 1800);
    DECLARE @UPrueba9_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E11, @EvalA, DATEADD(HOUR, -41, @Ahora), DATEADD(HOUR, -40, @Ahora), 20, 8);
    DECLARE @Int11_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E11, N'EVALUACION', DATEADD(HOUR, -40, @Ahora), 1800);
    DECLARE @UPrueba11_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E11, @EvalB, DATEADD(HOUR, -21, @Ahora), DATEADD(HOUR, -20, @Ahora), 20, 11);
    DECLARE @Int11_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E11, N'EVALUACION', DATEADD(HOUR, -20, @Ahora), 1800);
    DECLARE @UPrueba11_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E12, @EvalA, DATEADD(HOUR, -401, @Ahora), DATEADD(HOUR, -400, @Ahora), 20, 8);
    DECLARE @Int12_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E12, N'EVALUACION', DATEADD(HOUR, -400, @Ahora), 1800);
    DECLARE @UPrueba12_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E12, @EvalB, DATEADD(HOUR, -241, @Ahora), DATEADD(HOUR, -240, @Ahora), 20, 11);
    DECLARE @Int12_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E12, N'EVALUACION', DATEADD(HOUR, -240, @Ahora), 1800);
    DECLARE @UPrueba12_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E14, @EvalA, DATEADD(HOUR, -101, @Ahora), DATEADD(HOUR, -100, @Ahora), 20, 8);
    DECLARE @Int14_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E14, N'EVALUACION', DATEADD(HOUR, -100, @Ahora), 1800);
    DECLARE @UPrueba14_EvalA INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.IntentoEvaluacion (EstudianteId, EvaluacionId, FechaInicio, FechaFin, TotalPreguntas, Aciertos)
    VALUES (@E14, @EvalB, DATEADD(HOUR, -41, @Ahora), DATEADD(HOUR, -40, @Ahora), 20, 11);
    DECLARE @Int14_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E14, N'EVALUACION', DATEADD(HOUR, -40, @Ahora), 1800);
    DECLARE @UPrueba14_EvalB INT = CONVERT(INT, SCOPE_IDENTITY());

    -- Actividad distribuida en el tiempo: ultima actividad no equivale a ultimo login.
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E1, @Rec1, N'ACCESO', DATEADD(HOUR, -400, @Ahora), 0);
    DECLARE @U1_0 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E1, @Rec1, N'ESTUDIO', DATEADD(HOUR, -30, @Ahora), 1500);
    DECLARE @U1_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E1, @Rec1, N'ESTUDIO', DATEADD(HOUR, -6, @Ahora), 1500);
    DECLARE @U1_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E2, @Rec1, N'ACCESO', DATEADD(HOUR, -400, @Ahora), 0);
    DECLARE @U2_0 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E2, @Rec1, N'ESTUDIO', DATEADD(HOUR, -120, @Ahora), 1500);
    DECLARE @U2_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E2, @Rec1, N'ESTUDIO', DATEADD(HOUR, -96, @Ahora), 1500);
    DECLARE @U2_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E3, @Rec1, N'ACCESO', DATEADD(HOUR, -400, @Ahora), 0);
    DECLARE @U3_0 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E3, @Rec1, N'ESTUDIO', DATEADD(HOUR, -216, @Ahora), 1500);
    DECLARE @U3_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E3, @Rec1, N'ESTUDIO', DATEADD(HOUR, -192, @Ahora), 1500);
    DECLARE @U3_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E4, @Rec1, N'ACCESO', DATEADD(HOUR, -400, @Ahora), 0);
    DECLARE @U4_0 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E4, @Rec1, N'ESTUDIO', DATEADD(HOUR, -36, @Ahora), 1500);
    DECLARE @U4_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E4, @Rec1, N'ESTUDIO', DATEADD(HOUR, -12, @Ahora), 1500);
    DECLARE @U4_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E5, @Rec1, N'ACCESO', DATEADD(HOUR, -400, @Ahora), 0);
    DECLARE @U5_0 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E5, @Rec1, N'ESTUDIO', DATEADD(HOUR, -34, @Ahora), 1500);
    DECLARE @U5_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E5, @Rec1, N'ESTUDIO', DATEADD(HOUR, -10, @Ahora), 1500);
    DECLARE @U5_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E6, @Rec1, N'ACCESO', DATEADD(HOUR, -400, @Ahora), 0);
    DECLARE @U6_0 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E6, @Rec1, N'ESTUDIO', DATEADD(HOUR, -44, @Ahora), 1500);
    DECLARE @U6_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E6, @Rec1, N'ESTUDIO', DATEADD(HOUR, -20, @Ahora), 1500);
    DECLARE @U6_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E8, @Rec1, N'ACCESO', DATEADD(HOUR, -400, @Ahora), 0);
    DECLARE @U8_0 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E8, @Rec1, N'ESTUDIO', DATEADD(HOUR, -104, @Ahora), 1500);
    DECLARE @U8_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E8, @Rec1, N'ESTUDIO', DATEADD(HOUR, -80, @Ahora), 1500);
    DECLARE @U8_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E9, @Rec1, N'ACCESO', DATEADD(HOUR, -400, @Ahora), 0);
    DECLARE @U9_0 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E9, @Rec1, N'ESTUDIO', DATEADD(HOUR, -29, @Ahora), 1500);
    DECLARE @U9_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E9, @Rec1, N'ESTUDIO', DATEADD(HOUR, -5, @Ahora), 1500);
    DECLARE @U9_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E10, @Rec1, N'ACCESO', DATEADD(HOUR, -400, @Ahora), 0);
    DECLARE @U10_0 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E10, @Rec1, N'ESTUDIO', DATEADD(HOUR, -74, @Ahora), 1500);
    DECLARE @U10_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E10, @Rec1, N'ESTUDIO', DATEADD(HOUR, -50, @Ahora), 1500);
    DECLARE @U10_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E11, @Rec1, N'ACCESO', DATEADD(HOUR, -40, @Ahora), 0);
    DECLARE @U11_0 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E11, @Rec1, N'ESTUDIO', DATEADD(HOUR, -32, @Ahora), 1500);
    DECLARE @U11_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E11, @Rec1, N'ESTUDIO', DATEADD(HOUR, -8, @Ahora), 1500);
    DECLARE @U11_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E12, @Rec1, N'ACCESO', DATEADD(HOUR, -400, @Ahora), 0);
    DECLARE @U12_0 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E12, @Rec1, N'ESTUDIO', DATEADD(HOUR, -42, @Ahora), 1500);
    DECLARE @U12_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E12, @Rec1, N'ESTUDIO', DATEADD(HOUR, -18, @Ahora), 1500);
    DECLARE @U12_2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E14, @Rec1, N'ACCESO', DATEADD(HOUR, -100, @Ahora), 0);
    DECLARE @U14_0 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E14, @Rec1, N'ESTUDIO', DATEADD(HOUR, -28, @Ahora), 1500);
    DECLARE @U14_1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoUso (EstudianteId, RecursoAcademicoId, Tipo, FechaEvento, DuracionSegundos)
    VALUES (@E14, @Rec1, N'ESTUDIO', DATEADD(HOUR, -4, @Ahora), 1500);
    DECLARE @U14_2 INT = CONVERT(INT, SCOPE_IDENTITY());

    -- Solicitudes respondidas y pendientes. Todos los aspectos pesan igual por calificacion.
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E1, @Contenido, DATEADD(HOUR, -30, @Ahora), N'Evaluar experiencia con el aspecto indicado despues de una interaccion');
    DECLARE @Sol1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Valoracion (SolicitudValoracionId, FechaRespuesta, Estrellas, Comentario, Valida)
    VALUES (@Sol1, DATEADD(HOUR, -20, @Ahora), 5, N'La experiencia con este aspecto es satisfactoria', 1);
    DECLARE @Val1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E2, @Contenido, DATEADD(HOUR, -30, @Ahora), N'Evaluar experiencia con el aspecto indicado despues de una interaccion');
    DECLARE @Sol2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Valoracion (SolicitudValoracionId, FechaRespuesta, Estrellas, Comentario, Valida)
    VALUES (@Sol2, DATEADD(HOUR, -20, @Ahora), 5, N'La experiencia con este aspecto es satisfactoria', 1);
    DECLARE @Val2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E3, @Usabilidad, DATEADD(HOUR, -400, @Ahora), N'Evaluar experiencia con el aspecto indicado despues de una interaccion');
    DECLARE @Sol3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Valoracion (SolicitudValoracionId, FechaRespuesta, Estrellas, Comentario, Valida)
    VALUES (@Sol3, DATEADD(HOUR, -200, @Ahora), 2, N'No logro entender los ejercicios y estoy insatisfecha con la plataforma', 1);
    DECLARE @Val3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E4, @Usabilidad, DATEADD(HOUR, -30, @Ahora), N'Evaluar experiencia con el aspecto indicado despues de una interaccion');
    DECLARE @Sol4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Valoracion (SolicitudValoracionId, FechaRespuesta, Estrellas, Comentario, Valida)
    VALUES (@Sol4, DATEADD(HOUR, -20, @Ahora), 3, N'Necesito ayuda con el acceso a algunos contenidos', 1);
    DECLARE @Val4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E5, @Contenido, DATEADD(HOUR, -30, @Ahora), N'Evaluar experiencia con el aspecto indicado despues de una interaccion');
    DECLARE @Sol5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Valoracion (SolicitudValoracionId, FechaRespuesta, Estrellas, Comentario, Valida)
    VALUES (@Sol5, DATEADD(HOUR, -20, @Ahora), 5, N'La experiencia con este aspecto es satisfactoria', 1);
    DECLARE @Val5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E6, @Contenido, DATEADD(HOUR, -30, @Ahora), N'Evaluar experiencia con el aspecto indicado despues de una interaccion');
    DECLARE @Sol6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Valoracion (SolicitudValoracionId, FechaRespuesta, Estrellas, Comentario, Valida)
    VALUES (@Sol6, DATEADD(HOUR, -20, @Ahora), 5, N'La experiencia con este aspecto es satisfactoria', 1);
    DECLARE @Val6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E7, @Contenido, DATEADD(HOUR, -1, @Ahora), N'Evaluar experiencia con el aspecto indicado despues de una interaccion');
    DECLARE @Sol7 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E8, @Contenido, DATEADD(HOUR, -400, @Ahora), N'Evaluar experiencia con el aspecto indicado despues de una interaccion');
    DECLARE @Sol8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E9, @Contenido, DATEADD(HOUR, -30, @Ahora), N'Evaluar experiencia con el aspecto indicado despues de una interaccion');
    DECLARE @Sol9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Valoracion (SolicitudValoracionId, FechaRespuesta, Estrellas, Comentario, Valida)
    VALUES (@Sol9, DATEADD(HOUR, -20, @Ahora), 5, N'La experiencia con este aspecto es satisfactoria', 1);
    DECLARE @Val9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E11, @Contenido, DATEADD(HOUR, -30, @Ahora), N'Evaluar experiencia con el aspecto indicado despues de una interaccion');
    DECLARE @Sol11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Valoracion (SolicitudValoracionId, FechaRespuesta, Estrellas, Comentario, Valida)
    VALUES (@Sol11, DATEADD(HOUR, -20, @Ahora), 5, N'La experiencia con este aspecto es satisfactoria', 1);
    DECLARE @Val11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E12, @Contenido, DATEADD(HOUR, -30, @Ahora), N'Evaluar experiencia con el aspecto indicado despues de una interaccion');
    DECLARE @Sol12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E14, @Contenido, DATEADD(HOUR, -30, @Ahora), N'Evaluar experiencia con el aspecto indicado despues de una interaccion');
    DECLARE @Sol14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Valoracion (SolicitudValoracionId, FechaRespuesta, Estrellas, Comentario, Valida)
    VALUES (@Sol14, DATEADD(HOUR, -20, @Ahora), 5, N'La experiencia con este aspecto es satisfactoria', 1);
    DECLARE @Val14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SolicitudValoracion (EstudianteId, AspectoValoracionId, FechaEmision, Motivo)
    VALUES (@E1, @Acompanamiento, DATEADD(HOUR, -18, @Ahora), N'Valorar acompanamiento posterior a la revision de ruta');
    DECLARE @SolAnaExtra INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Valoracion (SolicitudValoracionId, FechaRespuesta, Estrellas, Comentario, Valida)
    VALUES (@SolAnaExtra, DATEADD(HOUR, -15, @Ahora), 4, N'El ajuste me ayuda a organizarme', 1);
    DECLARE @ValAnaExtra INT = CONVERT(INT, SCOPE_IDENTITY());

    -- Incidencias abiertas, resueltas y reabiertas sin cambiar la apertura original.
    INSERT dbo.CasoAtencion (EstudianteId, Tipo, Ambito, Descripcion, FechaAperturaOriginal, FechaLimite, Estado, ResponsableId, FechaResolucionDefinitiva, Resolucion)
    VALUES (@E4, N'INCIDENCIA', N'ACCESO', N'No puede acceder a un contenido del plan', DATEADD(HOUR, -120, @Ahora), DATEADD(HOUR, -72, @Ahora), N'ABIERTA', @Soporte, NULL, NULL);
    DECLARE @Caso4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoCaso (CasoAtencionId, FechaEvento, Estado, Detalle, ResponsableId)
    VALUES (@Caso4, DATEADD(HOUR, -120, @Ahora), N'ABIERTA', N'Caso registrado', @Soporte);
    DECLARE @CasoAlta4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CasoAtencion (EstudianteId, Tipo, Ambito, Descripcion, FechaAperturaOriginal, FechaLimite, Estado, ResponsableId, FechaResolucionDefinitiva, Resolucion)
    VALUES (@E2, N'INCIDENCIA', N'SERVICIO', N'Solicita ayuda con materiales del curso', DATEADD(HOUR, -60, @Ahora), DATEADD(HOUR, -12, @Ahora), N'EN_ATENCION', @Soporte, NULL, NULL);
    DECLARE @Caso2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoCaso (CasoAtencionId, FechaEvento, Estado, Detalle, ResponsableId)
    VALUES (@Caso2, DATEADD(HOUR, -60, @Ahora), N'ABIERTA', N'Caso registrado', @Soporte);
    DECLARE @CasoAlta2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoCaso (CasoAtencionId, FechaEvento, Estado, Detalle, ResponsableId)
    VALUES (@Caso2, DATEADD(HOUR, -50, @Ahora), N'EN_ATENCION', N'Actualizacion de la atencion', @Soporte);
    DECLARE @CasoEstado2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CasoAtencion (EstudianteId, Tipo, Ambito, Descripcion, FechaAperturaOriginal, FechaLimite, Estado, ResponsableId, FechaResolucionDefinitiva, Resolucion)
    VALUES (@E5, N'INCIDENCIA', N'SERVICIO', N'Solicita ayuda con materiales del curso', DATEADD(HOUR, -100, @Ahora), DATEADD(HOUR, -52, @Ahora), N'RESUELTA', @Soporte, DATEADD(HOUR, -24, @Ahora), N'Se atendio y confirmo la solucion');
    DECLARE @Caso5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoCaso (CasoAtencionId, FechaEvento, Estado, Detalle, ResponsableId)
    VALUES (@Caso5, DATEADD(HOUR, -100, @Ahora), N'ABIERTA', N'Caso registrado', @Soporte);
    DECLARE @CasoAlta5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoCaso (CasoAtencionId, FechaEvento, Estado, Detalle, ResponsableId)
    VALUES (@Caso5, DATEADD(HOUR, -24, @Ahora), N'RESUELTA', N'Actualizacion de la atencion', @Soporte);
    DECLARE @CasoEstado5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CasoAtencion (EstudianteId, Tipo, Ambito, Descripcion, FechaAperturaOriginal, FechaLimite, Estado, ResponsableId, FechaResolucionDefinitiva, Resolucion)
    VALUES (@E12, N'INCIDENCIA', N'SERVICIO', N'Solicita ayuda con materiales del curso', DATEADD(HOUR, -140, @Ahora), DATEADD(HOUR, -92, @Ahora), N'REABIERTA', @Soporte, NULL, NULL);
    DECLARE @Caso12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoCaso (CasoAtencionId, FechaEvento, Estado, Detalle, ResponsableId)
    VALUES (@Caso12, DATEADD(HOUR, -140, @Ahora), N'ABIERTA', N'Caso registrado', @Soporte);
    DECLARE @CasoAlta12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoCaso (CasoAtencionId, FechaEvento, Estado, Detalle, ResponsableId)
    VALUES (@Caso12, DATEADD(HOUR, -100, @Ahora), N'RESUELTA', N'Se restablecio el recurso', @Soporte);
    DECLARE @Caso12Cierre INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoCaso (CasoAtencionId, FechaEvento, Estado, Detalle, ResponsableId)
    VALUES (@Caso12, DATEADD(HOUR, -80, @Ahora), N'REABIERTA', N'Reaparece el mismo problema; conserva fecha de apertura', @Soporte);
    DECLARE @Caso12Reabrir INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.CasoAtencion (EstudianteId, Tipo, Ambito, Descripcion, FechaAperturaOriginal, FechaLimite, Estado, ResponsableId, FechaResolucionDefinitiva, Resolucion)
    VALUES (@E6, N'CONSULTA', N'PAGO', N'Consulta sobre beca: no corresponde efectuar cobro', DATEADD(HOUR, -25, @Ahora), DATEADD(HOUR, 23, @Ahora), N'RESUELTA', @Soporte, DATEADD(HOUR, -23, @Ahora), N'Se atendio y confirmo la solucion');
    DECLARE @Caso6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoCaso (CasoAtencionId, FechaEvento, Estado, Detalle, ResponsableId)
    VALUES (@Caso6, DATEADD(HOUR, -25, @Ahora), N'ABIERTA', N'Caso registrado', @Soporte);
    DECLARE @CasoAlta6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoCaso (CasoAtencionId, FechaEvento, Estado, Detalle, ResponsableId)
    VALUES (@Caso6, DATEADD(HOUR, -23, @Ahora), N'RESUELTA', N'Actualizacion de la atencion', @Soporte);
    DECLARE @CasoEstado6 INT = CONVERT(INT, SCOPE_IDENTITY());

    -- Mensajes academicos. Ruta UNT recibe soporte humano, sin seguimiento IA contratado.
    -- Ines expresa no renovar y conserva el acceso hasta vencer.
    INSERT dbo.Conversacion (EstudianteId, ContactoId, Canal, Finalidad, FechaInicio)
    VALUES (@E1, @C1, N'WHATSAPP', N'ACADEMICA', DATEADD(HOUR, -12, @Ahora));
    DECLARE @Conv1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, Direccion, Emisor, Contenido, Estado, FechaEnvio, FechaEntrega)
    VALUES (@Conv1, N'SALIENTE', N'IA_ACADEMICO', N'Podemos revisar tus actividades pendientes y ayudarte a organizar tu preparacion. Quieres que revisemos tu dificultad?', N'ENTREGADO', DATEADD(HOUR, -12, @Ahora), DATEADD(HOUR, -12, @Ahora));
    DECLARE @Msg1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, RespuestaAMensajeId, Direccion, Emisor, Contenido, Estado, FechaRecepcion, IntencionExpresa)
    VALUES (@Conv1, @Msg1, N'ENTRANTE', N'CONTACTO', N'Gracias, si necesito apoyo con las ecuaciones.', N'RECIBIDO', DATEADD(HOUR, -11, @Ahora), N'PEDIR_APOYO');
    DECLARE @Resp1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Conversacion (EstudianteId, ContactoId, Canal, Finalidad, FechaInicio)
    VALUES (@E2, @C2, N'WHATSAPP', N'ACADEMICA', DATEADD(HOUR, -12, @Ahora));
    DECLARE @Conv2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, Direccion, Emisor, Contenido, Estado, FechaEnvio, FechaEntrega)
    VALUES (@Conv2, N'SALIENTE', N'SOPORTE', N'Podemos revisar tus actividades pendientes y ayudarte a organizar tu preparacion. Quieres que revisemos tu dificultad?', N'ENTREGADO', DATEADD(HOUR, 0, @Ahora), DATEADD(HOUR, 0, @Ahora));
    DECLARE @Msg2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, RespuestaAMensajeId, Direccion, Emisor, Contenido, Estado, FechaRecepcion, IntencionExpresa)
    VALUES (@Conv2, @Msg2, N'ENTRANTE', N'CONTACTO', N'Gracias, si necesito apoyo con las ecuaciones.', N'RECIBIDO', DATEADD(HOUR, 0, @Ahora), N'PEDIR_APOYO');
    DECLARE @Resp2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Conversacion (EstudianteId, ContactoId, Canal, Finalidad, FechaInicio)
    VALUES (@E3, @C3, N'WHATSAPP', N'ACADEMICA', DATEADD(HOUR, -12, @Ahora));
    DECLARE @Conv3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, Direccion, Emisor, Contenido, Estado, FechaEnvio, FechaEntrega)
    VALUES (@Conv3, N'SALIENTE', N'IA_ACADEMICO', N'Podemos revisar tus actividades pendientes y ayudarte a organizar tu preparacion. Quieres que revisemos tu dificultad?', N'ENTREGADO', DATEADD(HOUR, 0, @Ahora), DATEADD(HOUR, 0, @Ahora));
    DECLARE @Msg3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Conversacion (EstudianteId, ContactoId, Canal, Finalidad, FechaInicio)
    VALUES (@E4, @C4, N'WHATSAPP', N'ACADEMICA', DATEADD(HOUR, -12, @Ahora));
    DECLARE @Conv4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, Direccion, Emisor, Contenido, Estado, FechaEnvio, FechaEntrega)
    VALUES (@Conv4, N'SALIENTE', N'IA_ACADEMICO', N'Podemos revisar tus actividades pendientes y ayudarte a organizar tu preparacion. Quieres que revisemos tu dificultad?', N'ENTREGADO', DATEADD(HOUR, -12, @Ahora), DATEADD(HOUR, -12, @Ahora));
    DECLARE @Msg4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Conversacion (EstudianteId, ContactoId, Canal, Finalidad, FechaInicio)
    VALUES (@E5, @C5, N'WHATSAPP', N'ACADEMICA', DATEADD(HOUR, -12, @Ahora));
    DECLARE @Conv5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, Direccion, Emisor, Contenido, Estado, FechaEnvio, FechaEntrega)
    VALUES (@Conv5, N'SALIENTE', N'IA_ACADEMICO', N'Podemos revisar tus actividades pendientes y ayudarte a organizar tu preparacion. Quieres que revisemos tu dificultad?', N'ENTREGADO', DATEADD(HOUR, -12, @Ahora), DATEADD(HOUR, -12, @Ahora));
    DECLARE @Msg5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Conversacion (EstudianteId, ContactoId, Canal, Finalidad, FechaInicio)
    VALUES (@E8, @C8, N'WHATSAPP', N'ACADEMICA', DATEADD(HOUR, -12, @Ahora));
    DECLARE @Conv8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, Direccion, Emisor, Contenido, Estado, FechaEnvio, FechaEntrega)
    VALUES (@Conv8, N'SALIENTE', N'IA_ACADEMICO', N'Podemos revisar tus actividades pendientes y ayudarte a organizar tu preparacion. Quieres que revisemos tu dificultad?', N'ENTREGADO', DATEADD(HOUR, -12, @Ahora), DATEADD(HOUR, -12, @Ahora));
    DECLARE @Msg8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Conversacion (EstudianteId, ContactoId, Canal, Finalidad, FechaInicio)
    VALUES (@E9, @C9, N'WHATSAPP', N'ACADEMICA', DATEADD(HOUR, -12, @Ahora));
    DECLARE @Conv9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, Direccion, Emisor, Contenido, Estado, FechaEnvio, FechaEntrega)
    VALUES (@Conv9, N'SALIENTE', N'IA_ACADEMICO', N'Podemos revisar tus actividades pendientes y ayudarte a organizar tu preparacion. Quieres que revisemos tu dificultad?', N'ENTREGADO', DATEADD(HOUR, -12, @Ahora), DATEADD(HOUR, -12, @Ahora));
    DECLARE @Msg9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, RespuestaAMensajeId, Direccion, Emisor, Contenido, Estado, FechaRecepcion, IntencionExpresa)
    VALUES (@Conv9, @Msg9, N'ENTRANTE', N'CONTACTO', N'No voy a renovar al finalizar mi periodo. No me envien mas mensajes proactivos.', N'RECIBIDO', DATEADD(HOUR, -3, @Ahora), N'NO_RENOVAR');
    DECLARE @Resp9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Conversacion (EstudianteId, ContactoId, Canal, Finalidad, FechaInicio)
    VALUES (@E12, @C12, N'WHATSAPP', N'ACADEMICA', DATEADD(HOUR, -12, @Ahora));
    DECLARE @Conv12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, Direccion, Emisor, Contenido, Estado, FechaEnvio, FechaEntrega)
    VALUES (@Conv12, N'SALIENTE', N'SOPORTE', N'Podemos revisar tus actividades pendientes y ayudarte a organizar tu preparacion. Quieres que revisemos tu dificultad?', N'ENTREGADO', DATEADD(HOUR, 0, @Ahora), DATEADD(HOUR, 0, @Ahora));
    DECLARE @Msg12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Conversacion (EstudianteId, ContactoId, Canal, Finalidad, FechaInicio)
    VALUES (@E14, @C14, N'WHATSAPP', N'ACADEMICA', DATEADD(HOUR, -12, @Ahora));
    DECLARE @Conv14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, Direccion, Emisor, Contenido, Estado, FechaEnvio, FechaEntrega)
    VALUES (@Conv14, N'SALIENTE', N'IA_ACADEMICO', N'Podemos revisar tus actividades pendientes y ayudarte a organizar tu preparacion. Quieres que revisemos tu dificultad?', N'ENTREGADO', DATEADD(HOUR, -12, @Ahora), DATEADD(HOUR, -12, @Ahora));
    DECLARE @Msg14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Conversacion (EstudianteId, ContactoId, Canal, Finalidad, FechaInicio)
    VALUES (@E5, @Madre, N'EMAIL', N'REPORTES', DATEADD(HOUR, -8, @Ahora));
    DECLARE @ConvApo INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, Direccion, Emisor, Contenido, Estado, FechaEnvio, FechaEntrega)
    VALUES (@ConvApo, N'SALIENTE', N'SISTEMA', N'Su reporte de progreso esta disponible en la cuenta vinculada de Meta UNT Plus.', N'ENTREGADO', DATEADD(HOUR, -8, @Ahora), DATEADD(HOUR, -8, @Ahora));
    DECLARE @MsgApo INT = CONVERT(INT, SCOPE_IDENTITY());

    -- Clasificaciones de demostracion: Hugo tiene historial pero no evaluacion vigente.
    INSERT dbo.EvaluacionRiesgo (EstudianteId, FechaEvaluacion, Estado, Nivel, Motivo, Origen)
    VALUES (@E1, DATEADD(HOUR, 0, @Ahora), N'CLASIFICADA', N'BAJO', N'Clasificacion sustentada en las senales vinculadas; prevalece el mayor riesgo', N'DEMO');
    DECLARE @Riesgo1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SenalRiesgo (EvaluacionRiesgoId, Codigo, Nivel, FechaObservacion, Detalle, EventoUsoId)
    VALUES (@Riesgo1, N'ACTIVIDAD_RECIENTE', N'BAJO', DATEADD(HOUR, 0, @Ahora), N'Ultima actividad hace 6 horas; sin otras senales de mayor nivel conocidas', @U1_2);
    DECLARE @Senal1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EvaluacionRiesgo (EstudianteId, FechaEvaluacion, Estado, Nivel, Motivo, Origen)
    VALUES (@E2, DATEADD(HOUR, 0, @Ahora), N'CLASIFICADA', N'MEDIO', N'Clasificacion sustentada en las senales vinculadas; prevalece el mayor riesgo', N'DEMO');
    DECLARE @Riesgo2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SenalRiesgo (EvaluacionRiesgoId, Codigo, Nivel, FechaObservacion, Detalle, EventoUsoId)
    VALUES (@Riesgo2, N'INACTIVIDAD', N'MEDIO', DATEADD(HOUR, 0, @Ahora), N'Ultima actividad hace 96 horas; sin otras senales de mayor nivel conocidas', @U2_2);
    DECLARE @Senal2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EvaluacionRiesgo (EstudianteId, FechaEvaluacion, Estado, Nivel, Motivo, Origen)
    VALUES (@E3, DATEADD(HOUR, 0, @Ahora), N'CLASIFICADA', N'ALTO', N'Clasificacion sustentada en las senales vinculadas; prevalece el mayor riesgo', N'DEMO');
    DECLARE @Riesgo3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SenalRiesgo (EvaluacionRiesgoId, Codigo, Nivel, FechaObservacion, Detalle, EventoUsoId)
    VALUES (@Riesgo3, N'INACTIVIDAD', N'ALTO', DATEADD(HOUR, 0, @Ahora), N'Ultima actividad hace 192 horas; sin otras senales de mayor nivel conocidas', @U3_2);
    DECLARE @Senal3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SenalRiesgo (EvaluacionRiesgoId, Codigo, Nivel, FechaObservacion, Detalle, ValoracionId)
    VALUES (@Riesgo3, N'INSATISFACCION', N'ALTO', DATEADD(HOUR, -200, @Ahora), N'Dos estrellas con comentario que evidencia insatisfaccion', @Val3);
    DECLARE @Senal3Valor INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EvaluacionRiesgo (EstudianteId, FechaEvaluacion, Estado, Nivel, Motivo, Origen)
    VALUES (@E4, DATEADD(HOUR, 0, @Ahora), N'CLASIFICADA', N'ALTO', N'Clasificacion sustentada en las senales vinculadas; prevalece el mayor riesgo', N'DEMO');
    DECLARE @Riesgo4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SenalRiesgo (EvaluacionRiesgoId, Codigo, Nivel, FechaObservacion, Detalle, CasoAtencionId)
    VALUES (@Riesgo4, N'INCIDENCIA_ABIERTA', N'ALTO', DATEADD(HOUR, 0, @Ahora), N'Incidencia de servicio/acceso sin resolver por mas de 96 horas', @Caso4);
    DECLARE @Senal4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EvaluacionRiesgo (EstudianteId, FechaEvaluacion, Estado, Nivel, Motivo, Origen)
    VALUES (@E5, DATEADD(HOUR, 0, @Ahora), N'CLASIFICADA', N'BAJO', N'Clasificacion sustentada en las senales vinculadas; prevalece el mayor riesgo', N'DEMO');
    DECLARE @Riesgo5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SenalRiesgo (EvaluacionRiesgoId, Codigo, Nivel, FechaObservacion, Detalle, EventoUsoId)
    VALUES (@Riesgo5, N'ACTIVIDAD_RECIENTE', N'BAJO', DATEADD(HOUR, 0, @Ahora), N'Ultima actividad hace 10 horas; sin otras senales de mayor nivel conocidas', @U5_2);
    DECLARE @Senal5 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EvaluacionRiesgo (EstudianteId, FechaEvaluacion, Estado, Nivel, Motivo, Origen)
    VALUES (@E6, DATEADD(HOUR, 0, @Ahora), N'CLASIFICADA', N'BAJO', N'Clasificacion sustentada en las senales vinculadas; prevalece el mayor riesgo', N'DEMO');
    DECLARE @Riesgo6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SenalRiesgo (EvaluacionRiesgoId, Codigo, Nivel, FechaObservacion, Detalle, EventoUsoId)
    VALUES (@Riesgo6, N'ACTIVIDAD_RECIENTE', N'BAJO', DATEADD(HOUR, 0, @Ahora), N'Ultima actividad hace 20 horas; sin otras senales de mayor nivel conocidas', @U6_2);
    DECLARE @Senal6 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EvaluacionRiesgo (EstudianteId, FechaEvaluacion, Estado, Nivel, Motivo, Origen)
    VALUES (@E7, DATEADD(HOUR, 0, @Ahora), N'PENDIENTE', NULL, N'Sin actividad, evaluaciones ni interacciones suficientes; ingreso reciente', N'DEMO');
    DECLARE @Riesgo7 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EvaluacionRiesgo (EstudianteId, FechaEvaluacion, Estado, Nivel, Motivo, Origen)
    VALUES (@E8, DATEADD(HOUR, -216, @Ahora), N'CLASIFICADA', N'MEDIO', N'Evaluacion historica: dificultad declarada; actualmente necesita reevaluacion', N'DEMO');
    DECLARE @Riesgo8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SenalRiesgo (EvaluacionRiesgoId, Codigo, Nivel, FechaObservacion, Detalle, DificultadAcademicaId)
    VALUES (@Riesgo8, N'DIFICULTAD_ACADEMICA', N'MEDIO', DATEADD(HOUR, -300, @Ahora), N'Dificultad que requiere seguimiento, observada antes de evaluar', @Dif8);
    DECLARE @Senal8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EvaluacionRiesgo (EstudianteId, FechaEvaluacion, Estado, Nivel, Motivo, Origen)
    VALUES (@E9, DATEADD(HOUR, 0, @Ahora), N'CLASIFICADA', N'ALTO', N'Clasificacion sustentada en las senales vinculadas; prevalece el mayor riesgo', N'DEMO');
    DECLARE @Riesgo9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SenalRiesgo (EvaluacionRiesgoId, Codigo, Nivel, FechaObservacion, Detalle, MensajeId)
    VALUES (@Riesgo9, N'INTENCION_CANCELAR', N'ALTO', DATEADD(HOUR, -3, @Ahora), N'Intencion expresa de no renovar', @Resp9);
    DECLARE @Senal9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EvaluacionRiesgo (EstudianteId, FechaEvaluacion, Estado, Nivel, Motivo, Origen)
    VALUES (@E11, DATEADD(HOUR, 0, @Ahora), N'CLASIFICADA', N'BAJO', N'Clasificacion sustentada en las senales vinculadas; prevalece el mayor riesgo', N'DEMO');
    DECLARE @Riesgo11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SenalRiesgo (EvaluacionRiesgoId, Codigo, Nivel, FechaObservacion, Detalle, EventoUsoId)
    VALUES (@Riesgo11, N'ACTIVIDAD_RECIENTE', N'BAJO', DATEADD(HOUR, 0, @Ahora), N'Ultima actividad hace 8 horas; sin otras senales de mayor nivel conocidas', @U11_2);
    DECLARE @Senal11 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EvaluacionRiesgo (EstudianteId, FechaEvaluacion, Estado, Nivel, Motivo, Origen)
    VALUES (@E12, DATEADD(HOUR, 0, @Ahora), N'CLASIFICADA', N'ALTO', N'Clasificacion sustentada en las senales vinculadas; prevalece el mayor riesgo', N'DEMO');
    DECLARE @Riesgo12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SenalRiesgo (EvaluacionRiesgoId, Codigo, Nivel, FechaObservacion, Detalle, CasoAtencionId)
    VALUES (@Riesgo12, N'INCIDENCIA_ABIERTA', N'ALTO', DATEADD(HOUR, 0, @Ahora), N'Incidencia de servicio/acceso sin resolver por mas de 96 horas', @Caso12);
    DECLARE @Senal12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EvaluacionRiesgo (EstudianteId, FechaEvaluacion, Estado, Nivel, Motivo, Origen)
    VALUES (@E14, DATEADD(HOUR, 0, @Ahora), N'CLASIFICADA', N'BAJO', N'Clasificacion sustentada en las senales vinculadas; prevalece el mayor riesgo', N'DEMO');
    DECLARE @Riesgo14 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.SenalRiesgo (EvaluacionRiesgoId, Codigo, Nivel, FechaObservacion, Detalle, EventoUsoId)
    VALUES (@Riesgo14, N'ACTIVIDAD_RECIENTE', N'BAJO', DATEADD(HOUR, 0, @Ahora), N'Ultima actividad hace 4 horas; sin otras senales de mayor nivel conocidas', @U14_2);
    DECLARE @Senal14 INT = CONVERT(INT, SCOPE_IDENTITY());

    -- C-4: mensaje enviado no basta; tambien debe completarse la intervencion.
    INSERT dbo.Intervencion (EstudianteId, EvaluacionRiesgoId, Tipo, Motivo, Recomendacion, FechaCreacion, FechaProgramada, RequiereAprobacion, Estado, MensajeSeguimientoId, FechaCompletada, Resultado)
    VALUES (@E2, @Riesgo2, N'ACOMPANAMIENTO', N'Seguimiento por senales documentadas de abandono', N'Revisar dificultad y proponer refuerzo compatible con el plan', DATEADD(HOUR, 0, @Ahora), NULL, 0, N'COMPLETADA', @Msg2, DATEADD(HOUR, 0, @Ahora), N'Estudiante recibio orientacion sobre el material; reevaluar en una semana');
    DECLARE @Inter2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoIntervencion (IntervencionId, FechaEvento, Estado, Detalle)
    VALUES (@Inter2, DATEADD(HOUR, 0, @Ahora), N'COMPLETADA', N'Registro del estado de la accion de acompanamiento');
    DECLARE @EvInter2 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Intervencion (EstudianteId, EvaluacionRiesgoId, Tipo, Motivo, Recomendacion, FechaCreacion, FechaProgramada, RequiereAprobacion, Estado, MensajeSeguimientoId, FechaCompletada, Resultado)
    VALUES (@E3, @Riesgo3, N'ACOMPANAMIENTO', N'Seguimiento por senales documentadas de abandono', N'Revisar dificultad y proponer refuerzo compatible con el plan', DATEADD(HOUR, 0, @Ahora), NULL, 0, N'EN_CURSO', @Msg3, NULL, NULL);
    DECLARE @Inter3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoIntervencion (IntervencionId, FechaEvento, Estado, Detalle)
    VALUES (@Inter3, DATEADD(HOUR, 0, @Ahora), N'EN_CURSO', N'Registro del estado de la accion de acompanamiento');
    DECLARE @EvInter3 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Intervencion (EstudianteId, EvaluacionRiesgoId, Tipo, Motivo, Recomendacion, FechaCreacion, FechaProgramada, RequiereAprobacion, Estado, MensajeSeguimientoId, FechaCompletada, Resultado)
    VALUES (@E4, @Riesgo4, N'DERIVACION_HUMANA', N'Seguimiento por senales documentadas de abandono', N'Revisar dificultad y proponer refuerzo compatible con el plan', DATEADD(HOUR, 0, @Ahora), NULL, 1, N'PROPUESTA', NULL, NULL, NULL);
    DECLARE @Inter4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoIntervencion (IntervencionId, FechaEvento, Estado, Detalle)
    VALUES (@Inter4, DATEADD(HOUR, 0, @Ahora), N'PROPUESTA', N'Registro del estado de la accion de acompanamiento');
    DECLARE @EvInter4 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Intervencion (EstudianteId, EvaluacionRiesgoId, Tipo, Motivo, Recomendacion, FechaCreacion, FechaProgramada, RequiereAprobacion, Estado, MensajeSeguimientoId, FechaCompletada, Resultado)
    VALUES (@E8, @Riesgo8, N'ACOMPANAMIENTO', N'Seguimiento por senales documentadas de abandono', N'Revisar dificultad y proponer refuerzo compatible con el plan', DATEADD(HOUR, 0, @Ahora), DATEADD(HOUR, 4, @Ahora), 0, N'PROGRAMADA', NULL, NULL, NULL);
    DECLARE @Inter8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoIntervencion (IntervencionId, FechaEvento, Estado, Detalle)
    VALUES (@Inter8, DATEADD(HOUR, 0, @Ahora), N'PROGRAMADA', N'Registro del estado de la accion de acompanamiento');
    DECLARE @EvInter8 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Intervencion (EstudianteId, EvaluacionRiesgoId, Tipo, Motivo, Recomendacion, FechaCreacion, FechaProgramada, RequiereAprobacion, Estado, MensajeSeguimientoId, FechaCompletada, Resultado)
    VALUES (@E9, @Riesgo9, N'DERIVACION_HUMANA', N'Seguimiento por senales documentadas de abandono', N'Dueno debe revisar el reclamo; no enviar seguimiento proactivo sin autorizacion', DATEADD(HOUR, 0, @Ahora), NULL, 1, N'PROPUESTA', NULL, NULL, NULL);
    DECLARE @Inter9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoIntervencion (IntervencionId, FechaEvento, Estado, Detalle)
    VALUES (@Inter9, DATEADD(HOUR, 0, @Ahora), N'PROPUESTA', N'Registro del estado de la accion de acompanamiento');
    DECLARE @EvInter9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Intervencion (EstudianteId, EvaluacionRiesgoId, Tipo, Motivo, Recomendacion, FechaCreacion, FechaProgramada, RequiereAprobacion, Estado, MensajeSeguimientoId, FechaCompletada, Resultado)
    VALUES (@E12, @Riesgo12, N'ACOMPANAMIENTO', N'Seguimiento por senales documentadas de abandono', N'Revisar dificultad y proponer refuerzo compatible con el plan', DATEADD(HOUR, 0, @Ahora), NULL, 0, N'EN_CURSO', @Msg12, NULL, NULL);
    DECLARE @Inter12 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.EventoIntervencion (IntervencionId, FechaEvento, Estado, Detalle)
    VALUES (@Inter12, DATEADD(HOUR, 0, @Ahora), N'EN_CURSO', N'Registro del estado de la accion de acompanamiento');
    DECLARE @EvInter12 INT = CONVERT(INT, SCOPE_IDENTITY());

    -- C-6: propuesta aceptada aun no cambia el servicio ni genera descuentos.
    INSERT dbo.PropuestaCambioPlan (PeriodoActualId, ModalidadSugeridaId, Necesidad, SolicitadoPorCliente, FechaSolicitudCliente, FechaPresentacion, Estado, FechaRespuesta, Respuesta)
    VALUES (@P1, @PlusMes, N'Solicita funciones adicionales de preparacion', 0, NULL, DATEADD(HOUR, -9, @Ahora), N'PRESENTADA', NULL, NULL);
    DECLARE @Prop1 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PropuestaCambioPlan (PeriodoActualId, ModalidadSugeridaId, Necesidad, SolicitadoPorCliente, FechaSolicitudCliente, FechaPresentacion, Estado, FechaRespuesta, Respuesta)
    VALUES (@P9, @MetaMes, N'Solicita alternativa de menor costo', 1, DATEADD(HOUR, -10, @Ahora), DATEADD(HOUR, -9, @Ahora), N'RECHAZADA', DATEADD(HOUR, -6, @Ahora), N'Prefiero no renovar');
    DECLARE @Prop9 INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.PropuestaCambioPlan (PeriodoActualId, ModalidadSugeridaId, Necesidad, SolicitadoPorCliente, FechaSolicitudCliente, FechaPresentacion, Estado, FechaRespuesta, Respuesta)
    VALUES (@P12, @MetaMes, N'Solicita funciones adicionales de preparacion', 1, DATEADD(HOUR, -10, @Ahora), DATEADD(HOUR, -9, @Ahora), N'ACEPTADA', DATEADD(HOUR, -6, @Ahora), N'Acepto evaluar el cambio para el siguiente periodo; aun no se efectuo');
    DECLARE @Prop12 INT = CONVERT(INT, SCOPE_IDENTITY());

    -- C-7: un referido sin compra y otro con atribucion fijada en el primer pago.
    INSERT dbo.Conversacion (EstudianteId, ContactoId, Canal, Finalidad, FechaInicio)
    VALUES (@E5, @C5, N'WHATSAPP', N'ACADEMICA', DATEADD(HOUR, -216, @Ahora));
    DECLARE @ConvInv INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Mensaje (ConversacionId, Direccion, Emisor, Contenido, Estado, FechaEnvio, FechaEntrega)
    VALUES (@ConvInv, N'SALIENTE', N'IA_ACADEMICO', N'Si tu experiencia ha sido satisfactoria, puedes recomendar la plataforma con tu codigo ELENA-DEMO.', N'ENTREGADO', DATEADD(HOUR, -216, @Ahora), DATEADD(HOUR, -216, @Ahora));
    DECLARE @MsgInv INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.InvitacionReferido (EstudianteReferenteId, FechaInvitacion, Codigo, MensajeId)
    VALUES (@E5, DATEADD(HOUR, -216, @Ahora), N'ELENA-DEMO', @MsgInv);
    DECLARE @InvElena INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Referido (InvitacionReferidoId, EstudianteReferenteId, NombreReferido, FechaRegistroReferido, EstudianteReferidoId, FechaSeleccionReferente)
    VALUES (@InvElena, @E5, N'Paula Silva Demo', DATEADD(HOUR, -144, @Ahora), @E13, DATEADD(HOUR, -144, @Ahora));
    DECLARE @RefPaula INT = CONVERT(INT, SCOPE_IDENTITY());
    INSERT dbo.Referido (InvitacionReferidoId, EstudianteReferenteId, NombreReferido, FechaRegistroReferido, EstudianteReferidoId, FechaSeleccionReferente, PrimerPagoId, FechaFijacion)
    VALUES (@InvElena, @E5, N'Ruben Paredes Demo', DATEADD(HOUR, -168, @Ahora), @E14, DATEADD(HOUR, -168, @Ahora), @PagoP14, DATEADD(HOUR, -120, @Ahora));
    DECLARE @RefRuben INT = CONVERT(INT, SCOPE_IDENTITY());

    -- Comprobaciones de coherencia de la carga. Cualquier fallo revierte TODA la poblacion.
    IF (SELECT COUNT(*) FROM dbo.Estudiante) <> 14
        THROW 51101, N'No se cargaron los 14 estudiantes esperados.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Pago p JOIN dbo.PeriodoServicio ps ON ps.PeriodoServicioId=p.PeriodoServicioId WHERE ps.BecaPorcentaje=100)
        THROW 51102, N'Una beca completa no debe generar pagos.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Estudiante e WHERE e.EtapaActual='CUSTOMER' AND NOT EXISTS
              (SELECT 1 FROM dbo.Suscripcion s JOIN dbo.PeriodoServicio p ON p.SuscripcionId=s.SuscripcionId
               WHERE s.EstudianteId=e.EstudianteId AND s.Estado='VIGENTE'
                 AND p.EstadoAcceso IN ('HABILITADO','CON_INCIDENCIA') AND p.Inicio<=@Ahora AND p.Fin>@Ahora))
        THROW 51103, N'Existe un CUSTOMER sin servicio habilitado vigente.', 1;
    IF EXISTS (SELECT 1 FROM dbo.SenalRiesgo sr JOIN dbo.EvaluacionRiesgo er ON er.EvaluacionRiesgoId=sr.EvaluacionRiesgoId
               WHERE sr.FechaObservacion>er.FechaEvaluacion)
        THROW 51104, N'Una senal no puede observarse despues de su evaluacion.', 1;
    IF EXISTS (SELECT 1 FROM dbo.SenalRiesgo sr JOIN dbo.EvaluacionRiesgo er ON er.EvaluacionRiesgoId=sr.EvaluacionRiesgoId
               JOIN dbo.EventoUso u ON u.EventoUsoId=sr.EventoUsoId WHERE u.EstudianteId<>er.EstudianteId)
        THROW 51105, N'Una senal se vinculo al estudiante incorrecto.', 1;
    IF EXISTS (SELECT 1 FROM dbo.EvaluacionRiesgo er CROSS APPLY
               (SELECT MAX(CASE Nivel WHEN 'ALTO' THEN 3 WHEN 'MEDIO' THEN 2 ELSE 1 END) AS MaxNivel
                FROM dbo.SenalRiesgo sr WHERE sr.EvaluacionRiesgoId=er.EvaluacionRiesgoId) x
               WHERE er.Estado='CLASIFICADA' AND (x.MaxNivel IS NULL OR x.MaxNivel<>CASE er.Nivel WHEN 'ALTO' THEN 3 WHEN 'MEDIO' THEN 2 ELSE 1 END))
        THROW 51106, N'La clasificacion debe coincidir con la senal de mayor nivel.', 1;
    -- En esta demo las autorizaciones se dieron desde el primer formulario valido.
    -- Se consulta ese evento original, sin repetir su fecha en Contacto.
    IF EXISTS (SELECT 1 FROM dbo.AutorizacionContacto a
               JOIN (SELECT ContactoId, MIN(FechaEnvio) AS PrimerFormularioValido
                     FROM dbo.FormularioContacto WHERE Valido=1 GROUP BY ContactoId) f
                 ON f.ContactoId=a.ContactoId
               WHERE a.FechaDecision<f.PrimerFormularioValido)
        THROW 51107, N'Una autorizacion ficticia no debe preceder al primer formulario valido del contacto.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Mensaje m JOIN dbo.Conversacion c ON c.ConversacionId=m.ConversacionId
               JOIN dbo.Suscripcion s ON s.EstudianteId=c.EstudianteId
               JOIN dbo.PeriodoServicio p ON p.SuscripcionId=s.SuscripcionId
               JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId=p.ModalidadPlanId
               WHERE m.Emisor='IA_ACADEMICO' AND m.FechaEnvio>=p.Inicio AND m.FechaEnvio<p.Fin
                 AND NOT EXISTS (SELECT 1 FROM dbo.PlanPrestacion pp JOIN dbo.Prestacion pr ON pr.PrestacionId=pp.PrestacionId
                                 WHERE pp.PlanServicioId=mp.PlanServicioId AND pr.Codigo='SEGUIMIENTO_IA'))
        THROW 51108, N'La demo no debe prestar seguimiento IA a un plan que no lo incluye.', 1;
    COMMIT TRANSACTION;
    PRINT N'Datos ficticios cargados correctamente. Las consultas siguientes son de solo lectura.';
    SELECT @Ahora AS FechaBaseDemoPeru, COUNT(*) AS Estudiantes FROM dbo.Estudiante;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* 1. Customers operativos, plan, ultimo uso y vigencia de la evaluacion.
No sustituye un clasificador: muestra la evaluacion guardada, no recalcula riesgo.
Hugo queda SIN EVALUACION VIGENTE y Gabriela PENDIENTE, nunca BAJO por defecto. */
DECLARE @Corte DATETIME2(0)=GETDATE();
SELECT e.Codigo, c.NombreCompleto, pl.Nombre AS PlanVigente,
       ps.Inicio, ps.Fin, s.RenovacionAutomatica, u.UltimaActividad,
       er.Nivel AS UltimoRiesgoGuardado, er.FechaEvaluacion,
       CASE WHEN er.EvaluacionRiesgoId IS NULL THEN 'SIN EVALUACION'
            WHEN er.FechaEvaluacion<DATEADD(DAY,-politica.VigenciaDias,@Corte) THEN 'SIN EVALUACION VIGENTE'
            WHEN er.Estado='PENDIENTE' THEN 'PENDIENTE'
            ELSE er.Nivel END AS SituacionRiesgo
FROM dbo.Estudiante e
JOIN dbo.Contacto c ON c.ContactoId=e.ContactoId
JOIN dbo.Suscripcion s ON s.EstudianteId=e.EstudianteId AND s.Estado='VIGENTE'
JOIN dbo.PeriodoServicio ps ON ps.SuscripcionId=s.SuscripcionId
JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId=ps.ModalidadPlanId
JOIN dbo.PlanServicio pl ON pl.PlanServicioId=mp.PlanServicioId
OUTER APPLY (SELECT MAX(FechaEvento) AS UltimaActividad FROM dbo.EventoUso WHERE EstudianteId=e.EstudianteId AND FechaEvento<=@Corte) u
OUTER APPLY (SELECT TOP (1) * FROM dbo.EvaluacionRiesgo WHERE EstudianteId=e.EstudianteId AND FechaEvaluacion<=@Corte ORDER BY FechaEvaluacion DESC, EvaluacionRiesgoId DESC) er
LEFT JOIN dbo.PoliticaRiesgo politica ON politica.VersionReglas=er.VersionReglas
WHERE e.EtapaActual='CUSTOMER' AND ps.EstadoAcceso IN ('HABILITADO','CON_INCIDENCIA')
  AND ps.Inicio<=@Corte AND ps.Fin>@Corte
ORDER BY e.Codigo;
GO

/* 2. Cumplimiento individual de actividades de la ruta vigente.
Ventana de ejemplo: ultimos 30 dias hasta ahora. NULL = no aplicable (sin tareas).
El numerador usa las MISMAS actividades del denominador, completadas al corte.
La consulta muestra estado actual; para cierres mensuales se conservaran snapshots
al cargar el DataMart y se usaran eventos/versiones conocidos al cierre. */
DECLARE @Fin DATETIME2(0)=GETDATE();
DECLARE @Inicio DATETIME2(0)=DATEADD(DAY,-30,@Fin);
SELECT e.Codigo, COUNT(a.ActividadRutaId) AS Planificadas,
       SUM(CASE WHEN a.Estado='COMPLETADA' AND a.FechaCompletada<=@Fin THEN 1 ELSE 0 END) AS Completadas,
       CONVERT(DECIMAL(6,2),100.0*SUM(CASE WHEN a.Estado='COMPLETADA' AND a.FechaCompletada<=@Fin THEN 1 ELSE 0 END)/NULLIF(COUNT(a.ActividadRutaId),0)) AS CumplimientoPct
FROM dbo.Estudiante e
JOIN dbo.RutaEstudio r ON r.EstudianteId=e.EstudianteId AND r.Vigente=1
LEFT JOIN dbo.ActividadRuta a ON a.RutaEstudioId=r.RutaEstudioId AND a.Estado<>'CANCELADA'
 AND a.FechaPlanificada>=@Inicio AND a.FechaPlanificada<=@Fin
WHERE e.EtapaActual='CUSTOMER'
GROUP BY e.Codigo ORDER BY e.Codigo;
GO

/* 3. Mejora por estudiante y grupo comparable. Ana: 40 -> 55 = +15 pp.
Diego tiene una sola prueba en cada grupo: Sin datos suficientes.
La primera y ultima prueba se comparan SOLO dentro del grupo validado.
Tambien se muestran customers sin intentos comparables (cero y datos insuficientes).
Esta consulta es exploratoria, no presupone que todos los intentos sean comparables. */
;WITH Pruebas AS (
 SELECT i.EstudianteId, ev.GrupoComparabilidadId, i.IntentoEvaluacionId, i.FechaFin,
        100.0*i.Aciertos/i.TotalPreguntas AS AciertosPct,
        ROW_NUMBER() OVER (PARTITION BY i.EstudianteId,ev.GrupoComparabilidadId ORDER BY i.FechaFin,i.IntentoEvaluacionId) AS Primera,
        ROW_NUMBER() OVER (PARTITION BY i.EstudianteId,ev.GrupoComparabilidadId ORDER BY i.FechaFin DESC,i.IntentoEvaluacionId DESC) AS Ultima
 FROM dbo.IntentoEvaluacion i JOIN dbo.Evaluacion ev ON ev.EvaluacionId=i.EvaluacionId
 WHERE ev.GrupoComparabilidadId IS NOT NULL AND i.FechaFin<=GETDATE()
)
SELECT e.Codigo, g.Codigo AS GrupoComparable, COUNT(p.IntentoEvaluacionId) AS Intentos,
       CONVERT(DECIMAL(6,2),MAX(CASE WHEN Primera=1 THEN AciertosPct END)) AS InicialPct,
       CONVERT(DECIMAL(6,2),MAX(CASE WHEN Ultima=1 THEN AciertosPct END)) AS PosteriorPct,
       CASE WHEN COUNT(p.IntentoEvaluacionId)>=2 THEN CONVERT(DECIMAL(6,2),MAX(CASE WHEN Ultima=1 THEN AciertosPct END)-MAX(CASE WHEN Primera=1 THEN AciertosPct END)) END AS MejoraPuntosPorcentuales,
       CASE WHEN COUNT(p.IntentoEvaluacionId)<2 THEN N'Sin datos suficientes' ELSE N'Comparacion disponible' END AS Resultado
FROM dbo.Estudiante e
LEFT JOIN Pruebas p ON p.EstudianteId=e.EstudianteId
LEFT JOIN dbo.GrupoComparabilidad g ON g.GrupoComparabilidadId=p.GrupoComparabilidadId
WHERE e.EtapaActual='CUSTOMER'
GROUP BY e.Codigo,g.Codigo ORDER BY e.Codigo,g.Codigo;
GO

/* 4. Valoraciones: promedio por aspecto y general, igual peso por calificacion.
No se promedian los promedios de aspectos. Las solicitudes sin respuesta siguen
existiendo y permiten calcular posteriormente C-2.2. */
SELECT COALESCE(a.Nombre,N'TODOS LOS ASPECTOS') AS Aspecto,
       COUNT(*) AS Calificaciones, CONVERT(DECIMAL(4,2),AVG(CONVERT(DECIMAL(4,2),v.Estrellas))) AS PromedioEstrellas
FROM dbo.Valoracion v
JOIN dbo.SolicitudValoracion s ON s.SolicitudValoracionId=v.SolicitudValoracionId
JOIN dbo.AspectoValoracion a ON a.AspectoValoracionId=s.AspectoValoracionId
WHERE v.Valida=1
GROUP BY GROUPING SETS ((a.Nombre),());
GO

/* 5. Incidencias del servicio abiertas: usa apertura ORIGINAL aun si se reabre.
Los casos de PAGO no intervienen en este criterio de riesgo de C-3.
Comparar con DATEADD respeta umbrales exactos, sin redondear horas con DATEDIFF. */
DECLARE @AhoraCaso DATETIME2(0)=GETDATE();
DECLARE @MedioHoras INT, @AltoHoras INT;
SELECT TOP(1) @MedioHoras=IncidenciaMediaHoras,@AltoHoras=IncidenciaAltaHoras FROM dbo.PoliticaRiesgo ORDER BY Numero DESC;
SELECT e.Codigo,c.CasoAtencionId,c.Ambito,c.Estado,c.FechaAperturaOriginal,
       CASE WHEN c.FechaAperturaOriginal<DATEADD(HOUR,-@AltoHoras,@AhoraCaso) THEN 'ALTO'
            WHEN c.FechaAperturaOriginal<DATEADD(HOUR,-@MedioHoras,@AhoraCaso) THEN 'MEDIO'
            ELSE 'SIN UMBRAL DE RIESGO POR ANTIGUEDAD' END AS SenalPorIncidencia
FROM dbo.CasoAtencion c JOIN dbo.Estudiante e ON e.EstudianteId=c.EstudianteId
WHERE c.Tipo='INCIDENCIA' AND c.Ambito IN ('SERVICIO','ACCESO') AND c.Estado<>'RESUELTA'
ORDER BY c.FechaAperturaOriginal;
GO

/* 6. Seguimiento C-4: Bruno SI; Carla/Diego/Mateo aun NO.
Una intervencion completada sin mensaje enviado NO cumple C-4.1. */
SELECT e.Codigo, i.Tipo, i.Estado, m.Estado AS EstadoMensaje,
       CASE WHEN i.Estado='COMPLETADA' AND m.Direccion='SALIENTE' AND m.FechaEnvio IS NOT NULL AND m.Estado IN ('ENVIADO','ENTREGADO') THEN 1 ELSE 0 END AS CumpleSeguimientoC4
FROM dbo.Intervencion i JOIN dbo.Estudiante e ON e.EstudianteId=i.EstudianteId
LEFT JOIN dbo.Mensaje m ON m.MensajeId=i.MensajeSeguimientoId
ORDER BY e.Codigo;
GO

/* 7. Propuestas de cambio: Mateo acepto, pero no tiene PeriodoAplicadoId. */
SELECT e.Codigo,pa.Nombre AS PlanActual,ps.Nombre AS PlanSugerido,p.Estado,
       p.SolicitadoPorCliente,p.FechaRespuesta,p.PeriodoAplicadoId
FROM dbo.PropuestaCambioPlan p
JOIN dbo.PeriodoServicio actual ON actual.PeriodoServicioId=p.PeriodoActualId
JOIN dbo.Suscripcion s ON s.SuscripcionId=actual.SuscripcionId
JOIN dbo.Estudiante e ON e.EstudianteId=s.EstudianteId
JOIN dbo.ModalidadPlan ma ON ma.ModalidadPlanId=actual.ModalidadPlanId
JOIN dbo.PlanServicio pa ON pa.PlanServicioId=ma.PlanServicioId
JOIN dbo.ModalidadPlan ms ON ms.ModalidadPlanId=p.ModalidadSugeridaId
JOIN dbo.PlanServicio ps ON ps.PlanServicioId=ms.PlanServicioId
ORDER BY e.Codigo;
GO

/* 8. Relacion familiar y acceso permitido al apoderado.
Maria puede consultar Carla y Elena por Plus; Pedro esta vinculado a Ana pero
su plan Meta UNT no concede cuenta de apoderado. No se crea autenticacion aqui. */
SELECT e.Codigo, c.NombreCompleto AS Apoderado, pl.Nombre AS PlanVigente,
       CASE WHEN EXISTS (SELECT 1 FROM dbo.PlanPrestacion pp JOIN dbo.Prestacion pr ON pr.PrestacionId=pp.PrestacionId
                         WHERE pp.PlanServicioId=pl.PlanServicioId AND pr.Codigo='REPORTES_APODERADO') THEN 1 ELSE 0 END AS PermiteAccesoApoderado
FROM dbo.Estudiante e
JOIN dbo.Apoderado ap ON ap.ApoderadoId=e.ApoderadoId
JOIN dbo.Contacto c ON c.ContactoId=ap.ContactoId
JOIN dbo.Suscripcion s ON s.EstudianteId=e.EstudianteId AND s.Estado='VIGENTE'
JOIN dbo.PeriodoServicio p ON p.SuscripcionId=s.SuscripcionId
JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId=p.ModalidadPlanId
JOIN dbo.PlanServicio pl ON pl.PlanServicioId=mp.PlanServicioId
WHERE p.Inicio<=GETDATE() AND p.Fin>GETDATE() AND p.EstadoAcceso IN ('HABILITADO','CON_INCIDENCIA');
GO

/* 9. Historial de renovacion/reactivacion y beca sin pago. */
SELECT e.Codigo,s.SuscripcionId,p.PeriodoServicioId,p.Tipo,p.Inicio,p.Fin,
       p.BecaPorcentaje,p.ImporteExigiblePEN,p.EstadoAcceso,pg.CodigoOperacion,pg.NetoPEN
FROM dbo.Estudiante e JOIN dbo.Suscripcion s ON s.EstudianteId=e.EstudianteId
JOIN dbo.PeriodoServicio p ON p.SuscripcionId=s.SuscripcionId
LEFT JOIN dbo.Pago pg ON pg.PeriodoServicioId=p.PeriodoServicioId AND pg.Tipo='COBRO' AND pg.Estado='CONFIRMADO'
WHERE e.Codigo IN ('C005','C006','C010','C011')
ORDER BY e.Codigo,p.Inicio;
GO

/* 10. Referidos y conversion a LEAD mediante formulario valido. */
SELECT re.Codigo AS Referente,r.NombreReferido,ed.Codigo AS CodigoReferido,
       r.FechaRegistroReferido,f.FechaPrimerFormulario,r.FechaSeleccionReferente,r.FechaFijacion,
       CASE WHEN f.FechaPrimerFormulario IS NOT NULL THEN 1 ELSE 0 END AS PasoALead,
       CASE WHEN r.PrimerPagoId IS NOT NULL THEN 1 ELSE 0 END AS AtribucionFijada
FROM dbo.Referido r
JOIN dbo.Estudiante re ON re.EstudianteId=r.EstudianteReferenteId
LEFT JOIN dbo.Estudiante ed ON ed.EstudianteId=r.EstudianteReferidoId
OUTER APPLY (SELECT MIN(FechaEnvio) AS FechaPrimerFormulario FROM dbo.FormularioContacto
             WHERE ContactoId=ed.ContactoId AND Valido=1) f;
GO

/* 11. Historial sencillo: tabla actual + tabla normal de versiones anteriores.
Los triggers guardan la fila anterior con la fecha REAL del cambio y U/D.
No hace falta sintaxis temporal. Los INSERT iniciales no crean una copia historica.
Las filas historicas se consultan directamente con SELECT y ORDER BY. */
SELECT EstudianteId,Codigo,DisponibilidadSemanalHoras,FechaExamen
FROM dbo.Estudiante WHERE Codigo='C001';
SELECT HistorialId,EstudianteId,Codigo,DisponibilidadSemanalHoras,FechaExamen,
       FechaCambio,Operacion
FROM dbo.EstudianteHistorial WHERE Codigo='C001'
ORDER BY HistorialId;
SELECT e.Codigo,r.VersionNumero,r.Objetivo,r.Vigente
FROM dbo.RutaEstudio r JOIN dbo.Estudiante e ON e.EstudianteId=r.EstudianteId
WHERE e.Codigo='C001' ORDER BY r.VersionNumero;
GO

-- M07: catálogo del JSON y avance inicial identificado como CARGA_DEMO.
DECLARE @DocumentoUNT NVARCHAR(MAX)=N'{
  "institucion": "Universidad Nacional de Trujillo (UNT)",
  "pais": "Perú",
  "fecha_consulta": "2026-11-12",
  "edicion_prioritaria": "Admisión 2027",
  "alcance": "Temario de preparación preuniversitaria basado en los ejes oficiales de admisión UNT y un desglose de cursos habituales de academia; no es una malla de asignaturas certificada por CEPUNT.",
  "fuentes": [
    {
      "id": "guia_2027",
      "tipo": "oficial",
      "nombre": "Guía de Admisión 2027",
      "url": "https://www.admisionunt.info/docs/GUIA-2027.pdf",
      "paginas_impresas_temario": [
        27,
        28,
        29,
        30,
        31
      ],
      "pagina_impresa_distribucion_preguntas": 20
    },
    {
      "id": "ejes_2026_ii",
      "tipo": "oficial",
      "nombre": "Esquema axial y ejes fundamentales 2026-II",
      "url": "https://www.admisionunt.info/docs/EJES__2026-II.pdf",
      "paginas_pdf_temario": [
        1,
        2,
        3,
        4,
        5
      ],
      "uso": "Contraste y análisis del discurso ausente como bloque separado en 2027"
    },
    {
      "id": "portal_temas",
      "tipo": "oficial",
      "nombre": "Temas por asignaturas de la Dirección de Admisión",
      "url": "https://www.admisionunt.info/temas"
    },
    {
      "id": "cepunt_2026",
      "tipo": "oficial",
      "nombre": "Ciclo académico regular CEPUNT septiembre-diciembre 2026",
      "url": "https://cepunt.edu.pe/ciclo-academico-regular-2026/"
    }
  ],
  "areas_postulacion_2027": [
    {
      "codigo": "A",
      "nombre": "Ciencias de la Vida y de la Salud",
      "total_preguntas": 100,
      "preguntas_por_bloque": {
        "Ciencias Sociales": 6,
        "Comunicación": 26,
        "Matemática": 28,
        "Ciencias y Tecnología": 40
      }
    },
    {
      "codigo": "B",
      "nombre": "Ciencias Básicas y Tecnológicas",
      "total_preguntas": 100,
      "preguntas_por_bloque": {
        "Ciencias Sociales": 6,
        "Comunicación": 26,
        "Matemática": 34,
        "Ciencias y Tecnología": 34
      }
    },
    {
      "codigo": "C",
      "nombre": "Ciencias de la Persona",
      "total_preguntas": 100,
      "preguntas_por_bloque": {
        "Desarrollo Personal, Ciudadanía y Cívica": 10,
        "Ciencias Sociales": 15,
        "Comunicación": 18,
        "Matemática": 35,
        "Ciencias y Tecnología": 22
      }
    },
    {
      "codigo": "D",
      "nombre": "Ciencias Económicas",
      "total_preguntas": 100,
      "preguntas_por_bloque": {
        "Desarrollo Personal, Ciudadanía y Cívica": 15,
        "Ciencias Sociales": 24,
        "Comunicación": 35,
        "Matemática": 26
      }
    }
  ],
  "relacion_agrupaciones_de_examen": {
    "Ciencias Sociales": [
      "Historia",
      "Geografía",
      "Economía"
    ],
    "Comunicación": [
      "Comunicología",
      "Literatura"
    ],
    "Matemática": [
      "Matemática"
    ],
    "Ciencias y Tecnología": [
      "Biología",
      "Física",
      "Química"
    ],
    "Desarrollo Personal, Ciudadanía y Cívica": [
      "Desarrollo Personal",
      "Ciudadanía y Cívica"
    ]
  },
  "asignaturas_oficiales_2027": [
    {
      "nombre": "Desarrollo Personal",
      "pagina_impresa_2027": 27,
      "resumen_ejes": [
        "Desarrollo humano y adolescencia",
        "Socialización e identidad",
        "Emociones e inteligencia emocional",
        "Proyecto de vida",
        "Sexualidad y salud reproductiva",
        "Ética y dignidad humana"
      ]
    },
    {
      "nombre": "Ciudadanía y Cívica",
      "pagina_impresa_2027": 27,
      "resumen_ejes": [
        "Saber filosófico, teoría del conocimiento y epistemología",
        "Axiología, ética y antropología filosófica",
        "Derechos humanos y políticos",
        "Familia y matrimonio",
        "Estado, Constitución y organismos",
        "Seguridad y defensa nacional, SINAGERD, convivencia democrática"
      ]
    },
    {
      "nombre": "Historia",
      "pagina_impresa_2027": 27,
      "resumen_ejes": [
        "Historia y prehistoria",
        "Culturas occidentales y Perú prehispánico",
        "Incas y Edad Media",
        "Exploración y colonización de América",
        "Virreinato e independencia del Perú",
        "Revoluciones del siglo XVIII",
        "Historia peruana y mundial XIX-XX",
        "Segunda Guerra Mundial y Guerra Fría",
        "Gobiernos del Perú 1948-2001"
      ]
    },
    {
      "nombre": "Geografía",
      "pagina_impresa_2027": 28,
      "resumen_ejes": [
        "Tierra y representación",
        "Geología, relieve y clima",
        "Geografía física del Perú",
        "Población y organización territorial",
        "Ocho regiones naturales",
        "Ecología y sostenibilidad",
        "Geografía económica y de La Libertad",
        "Continentes y geopolítica"
      ]
    },
    {
      "nombre": "Economía",
      "pagina_impresa_2027": 28,
      "resumen_ejes": [
        "Fundamentos, necesidades y factores productivos",
        "Oferta, demanda y elasticidad",
        "Empresas, producción y costos",
        "Modelos de mercado",
        "Mercado monetario y sistema financiero",
        "Estado, tributación y sector externo",
        "Crecimiento, ciclos y perturbaciones económicas"
      ]
    },
    {
      "nombre": "Comunicología",
      "pagina_impresa_2027": 28,
      "resumen_ejes": [
        "Proceso comunicativo y comunicación oral",
        "Signos y códigos",
        "Gramática y oración",
        "Semántica",
        "Ortografía y puntuación",
        "Producción textual"
      ]
    },
    {
      "nombre": "Literatura",
      "pagina_impresa_2027": 29,
      "resumen_ejes": [
        "Teoría y recursos literarios",
        "Literatura universal",
        "Literatura española",
        "Literatura latinoamericana",
        "Literatura peruana",
        "Literatura regional"
      ]
    },
    {
      "nombre": "Matemática",
      "pagina_impresa_2027": 30,
      "resumen_ejes": [
        "Conjuntos, numeración, lógica y números reales",
        "Divisibilidad, proporcionalidad e interés",
        "Álgebra, ecuaciones e inecuaciones",
        "Funciones y sucesiones",
        "Geometría plana",
        "Trigonometría",
        "Geometría analítica",
        "Combinatoria, probabilidad y estadística"
      ]
    },
    {
      "nombre": "Biología",
      "pagina_impresa_2027": 30,
      "resumen_ejes": [
        "Método científico",
        "Célula y tejidos",
        "Sistemas de relación",
        "Sistemas de nutrición",
        "Reproducción",
        "Herencia",
        "Ecología y biodiversidad"
      ]
    },
    {
      "nombre": "Física",
      "pagina_impresa_2027": 31,
      "resumen_ejes": [
        "Magnitudes, análisis dimensional y vectores",
        "Cinemática y dinámica",
        "Trabajo, potencia y energía",
        "Mecánica de fluidos",
        "Temperatura y teoría cinética",
        "Electricidad y magnetismo",
        "Óptica"
      ]
    },
    {
      "nombre": "Química",
      "pagina_impresa_2027": 31,
      "resumen_ejes": [
        "Materia, átomo y estructura electrónica",
        "Química nuclear",
        "Tabla periódica y enlaces",
        "Química inorgánica y reacciones",
        "Estequiometría y soluciones",
        "Electroquímica, cinética y equilibrio",
        "Ácidos, bases y química orgánica"
      ]
    }
  ],
  "cursos_preuniversitarios_desglosados": [
    {
      "id": "historia_peru",
      "nombre": "Historia del Perú",
      "bloques_oficiales_relacionados": [
        "Historia"
      ],
      "temas": [
        {
          "tema": "Perú prehispánico",
          "subtemas": [
            "Primeras sociedades del Perú",
            "Culturas y procesos anteriores al Tahuantinsuyo"
          ]
        },
        {
          "tema": "Los incas",
          "subtemas": [
            "Organización y expansión del Tahuantinsuyo"
          ]
        },
        {
          "tema": "Virreinato del Perú",
          "subtemas": [
            "Organización y sociedad colonial"
          ]
        },
        {
          "tema": "Emancipación del Perú",
          "subtemas": [
            "Proceso de independencia"
          ]
        },
        {
          "tema": "Prosperidad falaz",
          "subtemas": [
            "Etapa del guano"
          ]
        },
        {
          "tema": "Guerra del guano y del salitre",
          "subtemas": [
            "Guerra del Pacífico"
          ]
        },
        {
          "tema": "Perú republicano de los siglos XIX y XX",
          "subtemas": [
            "Procesos políticos, sociales y económicos"
          ]
        },
        {
          "tema": "Gobiernos del Perú entre 1948 y 1980",
          "subtemas": []
        },
        {
          "tema": "Gobiernos del Perú entre 1980 y 2001",
          "subtemas": []
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "historia_universal",
      "nombre": "Historia Universal",
      "bloques_oficiales_relacionados": [
        "Historia"
      ],
      "temas": [
        {
          "tema": "Historia y prehistoria",
          "subtemas": [
            "Conceptos y periodización histórica"
          ]
        },
        {
          "tema": "Altas culturas de Occidente",
          "subtemas": []
        },
        {
          "tema": "Edad Media",
          "subtemas": []
        },
        {
          "tema": "Viajes europeos y colonización de América",
          "subtemas": []
        },
        {
          "tema": "Grandes revoluciones del siglo XVIII",
          "subtemas": []
        },
        {
          "tema": "El mundo entre los siglos XIX y XX",
          "subtemas": []
        },
        {
          "tema": "Segunda Guerra Mundial",
          "subtemas": []
        },
        {
          "tema": "Guerra Fría",
          "subtemas": []
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "geografia",
      "nombre": "Geografía",
      "bloques_oficiales_relacionados": [
        "Geografía"
      ],
      "temas": [
        {
          "tema": "Espacio geográfico y la Tierra",
          "subtemas": [
            "La Tierra como morada humana",
            "Localización y representación de la Tierra"
          ]
        },
        {
          "tema": "Geología y relieve",
          "subtemas": [
            "Geología",
            "Modelado del paisaje"
          ]
        },
        {
          "tema": "Medioambiente y sociedad",
          "subtemas": [
            "Relación del ser humano con el medioambiente"
          ]
        },
        {
          "tema": "Climatología",
          "subtemas": [
            "Estudio del clima"
          ]
        },
        {
          "tema": "Geografía física del Perú",
          "subtemas": [
            "Ubicación y geoformas del relieve",
            "Hidrografía"
          ]
        },
        {
          "tema": "Organización territorial y población del Perú",
          "subtemas": [
            "Organización político-administrativa",
            "Población humana"
          ]
        },
        {
          "tema": "Ocho regiones naturales del Perú",
          "subtemas": []
        },
        {
          "tema": "Sostenibilidad y ecología",
          "subtemas": [
            "Desarrollo sostenible",
            "Equilibrio ecológico"
          ]
        },
        {
          "tema": "Geografía económica del Perú",
          "subtemas": []
        },
        {
          "tema": "Geografía de La Libertad",
          "subtemas": [
            "Naturaleza, cultura y desarrollo regional"
          ]
        },
        {
          "tema": "Geografía continental",
          "subtemas": [
            "América",
            "Europa",
            "Asia",
            "África",
            "Oceanía"
          ]
        },
        {
          "tema": "Geopolítica",
          "subtemas": [
            "Juego del poder mundial"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "economia",
      "nombre": "Economía",
      "bloques_oficiales_relacionados": [
        "Economía"
      ],
      "temas": [
        {
          "tema": "Fundamentos de economía",
          "subtemas": [
            "Manifestaciones económicas y su evolución"
          ]
        },
        {
          "tema": "Necesidades, bienes y recursos",
          "subtemas": [
            "Necesidades sociales",
            "Bienes económicos",
            "Recursos"
          ]
        },
        {
          "tema": "Factores productivos",
          "subtemas": [
            "Tierra",
            "Trabajo",
            "Capital"
          ]
        },
        {
          "tema": "Oferta y demanda",
          "subtemas": [
            "Demanda",
            "Oferta",
            "Elasticidades del mercado"
          ]
        },
        {
          "tema": "Organizaciones empresariales",
          "subtemas": [
            "Tipos de empresa"
          ]
        },
        {
          "tema": "Producción y costos",
          "subtemas": [
            "Producción",
            "Costos de corto plazo",
            "Costos de largo plazo"
          ]
        },
        {
          "tema": "Modelos y estructuras de mercado",
          "subtemas": []
        },
        {
          "tema": "Dinero y sistema monetario",
          "subtemas": [
            "Mercado monetario"
          ]
        },
        {
          "tema": "Sistema financiero",
          "subtemas": [
            "Operaciones crediticias",
            "Instrumentos del crédito"
          ]
        },
        {
          "tema": "Estado y economía",
          "subtemas": [
            "Intervención del Estado",
            "Tributación en el Perú"
          ]
        },
        {
          "tema": "Economía internacional",
          "subtemas": [
            "Comercio exterior",
            "Finanzas del sector externo"
          ]
        },
        {
          "tema": "Macroeconomía",
          "subtemas": [
            "Crecimiento económico",
            "Ciclo económico",
            "Perturbaciones económicas"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "lenguaje",
      "nombre": "Lenguaje y Comunicología",
      "bloques_oficiales_relacionados": [
        "Comunicología"
      ],
      "temas": [
        {
          "tema": "Comunicación humana",
          "subtemas": [
            "Proceso comunicativo",
            "Elementos",
            "Fines",
            "Formas"
          ]
        },
        {
          "tema": "Comunicación oral",
          "subtemas": [
            "Estrategias y técnicas",
            "Comunicación efectiva"
          ]
        },
        {
          "tema": "Signos y códigos",
          "subtemas": [
            "Signos de la comunicación humana",
            "Códigos"
          ]
        },
        {
          "tema": "Gramática",
          "subtemas": [
            "Elementos gramaticales"
          ]
        },
        {
          "tema": "Oración",
          "subtemas": [
            "Estructura de la oración",
            "Tipos de oración"
          ]
        },
        {
          "tema": "Semántica",
          "subtemas": [
            "Significado",
            "Significación",
            "Sentido"
          ]
        },
        {
          "tema": "Relaciones léxico-semánticas",
          "subtemas": []
        },
        {
          "tema": "Normativa del español",
          "subtemas": [
            "Ortografía",
            "Puntuación"
          ]
        },
        {
          "tema": "Producción textual",
          "subtemas": [
            "Fundamentos",
            "Elementos",
            "Recursos y requisitos",
            "Estrategias y técnicas de redacción"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "razonamiento_verbal",
      "nombre": "Razonamiento Verbal y Comprensión Lectora",
      "bloques_oficiales_relacionados": [
        "Comunicología"
      ],
      "temas": [
        {
          "tema": "Significado y relaciones semánticas",
          "subtemas": [
            "Sentido contextual",
            "Relaciones léxico-semánticas"
          ]
        },
        {
          "tema": "Textos y tipologías",
          "subtemas": [
            "Texto narrativo",
            "Texto expositivo",
            "Texto argumentativo",
            "Texto descriptivo",
            "Texto instructivo",
            "Texto transaccional"
          ]
        },
        {
          "tema": "Organización del discurso",
          "subtemas": [
            "Estructura textual",
            "Intertextualidad"
          ]
        },
        {
          "tema": "Propiedades del texto",
          "subtemas": [
            "Cohesión",
            "Coherencia",
            "Adecuación"
          ]
        },
        {
          "tema": "Conectores textuales",
          "subtemas": [
            "Marcadores textuales",
            "Conectores lógico-textuales"
          ]
        },
        {
          "tema": "Comprensión de lectura",
          "subtemas": [
            "Nivel literal",
            "Nivel inferencial",
            "Nivel crítico"
          ]
        },
        {
          "tema": "Estrategias de lectura",
          "subtemas": [
            "Técnicas de lectura y comprensión"
          ]
        }
      ],
      "fuentes": [
        "guia_2027",
        "ejes_2026_ii"
      ],
      "nota": "El detalle de análisis del discurso y los niveles de comprensión lectora figura expresamente en el PDF oficial 2026-II, pero no como bloque separado en las páginas de ejes de la Guía 2027."
    },
    {
      "id": "literatura",
      "nombre": "Literatura",
      "bloques_oficiales_relacionados": [
        "Literatura"
      ],
      "temas": [
        {
          "tema": "Teoría literaria",
          "subtemas": [
            "Naturaleza y características del texto literario",
            "Tipos de texto literario",
            "Técnicas y recursos de construcción literaria"
          ]
        },
        {
          "tema": "Literatura universal",
          "subtemas": [
            "Edipo rey",
            "La divina comedia",
            "Hamlet",
            "Ensayo sobre la ceguera"
          ]
        },
        {
          "tema": "Literatura española",
          "subtemas": [
            "El ingenioso hidalgo don Quijote de la Mancha",
            "Fuenteovejuna"
          ]
        },
        {
          "tema": "Literatura latinoamericana",
          "subtemas": [
            "Cien años de soledad",
            "Veinte poemas de amor y una canción desesperada",
            "El túnel"
          ]
        },
        {
          "tema": "Literatura peruana",
          "subtemas": [
            "El mundo es ancho y ajeno",
            "Trilce",
            "La ciudad y los perros"
          ]
        },
        {
          "tema": "Literatura regional",
          "subtemas": [
            "El huso de la palabra"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "aritmetica",
      "nombre": "Aritmética",
      "bloques_oficiales_relacionados": [
        "Matemática"
      ],
      "temas": [
        {
          "tema": "Conjuntos",
          "subtemas": [
            "Teoría de conjuntos"
          ]
        },
        {
          "tema": "Sistemas de numeración",
          "subtemas": []
        },
        {
          "tema": "Números reales",
          "subtemas": [
            "Propiedades y operaciones"
          ]
        },
        {
          "tema": "Divisibilidad",
          "subtemas": []
        },
        {
          "tema": "Magnitudes proporcionales",
          "subtemas": [
            "Proporcionalidad"
          ]
        },
        {
          "tema": "Matemática financiera básica",
          "subtemas": [
            "Regla de interés"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "algebra",
      "nombre": "Álgebra",
      "bloques_oficiales_relacionados": [
        "Matemática"
      ],
      "temas": [
        {
          "tema": "Expresiones algebraicas",
          "subtemas": [
            "Operaciones con expresiones algebraicas"
          ]
        },
        {
          "tema": "Productos y cocientes notables",
          "subtemas": []
        },
        {
          "tema": "Factorización y binomio de Newton",
          "subtemas": []
        },
        {
          "tema": "Ecuaciones",
          "subtemas": [
            "Lineales",
            "Cuadráticas",
            "Polinómicas",
            "Con valor absoluto",
            "Exponenciales",
            "Logarítmicas"
          ]
        },
        {
          "tema": "Inecuaciones",
          "subtemas": [
            "Lineales",
            "Cuadráticas",
            "Polinómicas",
            "Con valor absoluto",
            "Exponenciales"
          ]
        },
        {
          "tema": "Intervalos",
          "subtemas": []
        },
        {
          "tema": "Relaciones y conjuntos cartesianos",
          "subtemas": [
            "Relaciones binarias",
            "Producto cartesiano"
          ]
        },
        {
          "tema": "Funciones",
          "subtemas": [
            "Definición y elementos",
            "Dominio y rango",
            "Constante",
            "Lineal",
            "Cuadrática",
            "Racional",
            "Raíz cuadrada",
            "Valor absoluto",
            "Exponencial",
            "Logarítmica"
          ]
        },
        {
          "tema": "Operaciones entre funciones",
          "subtemas": [
            "Adición",
            "Sustracción",
            "Multiplicación",
            "División",
            "Composición"
          ]
        },
        {
          "tema": "Sucesiones y series",
          "subtemas": [
            "Sucesiones",
            "Series",
            "Sumatorias"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "geometria",
      "nombre": "Geometría",
      "bloques_oficiales_relacionados": [
        "Matemática"
      ],
      "temas": [
        {
          "tema": "Geometría plana",
          "subtemas": [
            "Segmentos",
            "Ángulos",
            "Triángulos"
          ]
        },
        {
          "tema": "Polígonos y cuadriláteros",
          "subtemas": []
        },
        {
          "tema": "Circunferencia y círculo",
          "subtemas": []
        },
        {
          "tema": "Medición de regiones planas",
          "subtemas": [
            "Áreas",
            "Perímetros"
          ]
        },
        {
          "tema": "Geometría analítica",
          "subtemas": [
            "Introducción y plano cartesiano"
          ]
        },
        {
          "tema": "La recta en el plano",
          "subtemas": [
            "Ecuación cartesiana",
            "Pendiente",
            "Ángulo entre dos rectas",
            "Paralelismo",
            "Perpendicularidad"
          ]
        },
        {
          "tema": "Regiones poligonales",
          "subtemas": [
            "Áreas en el plano cartesiano"
          ]
        },
        {
          "tema": "Cónicas",
          "subtemas": [
            "Circunferencia",
            "Parábola",
            "Elipse",
            "Hipérbola"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "trigonometria",
      "nombre": "Trigonometría",
      "bloques_oficiales_relacionados": [
        "Matemática"
      ],
      "temas": [
        {
          "tema": "Medición angular",
          "subtemas": [
            "Sistemas de medidas angulares"
          ]
        },
        {
          "tema": "Razones trigonométricas",
          "subtemas": []
        },
        {
          "tema": "Identidades trigonométricas",
          "subtemas": []
        },
        {
          "tema": "Funciones trigonométricas",
          "subtemas": []
        },
        {
          "tema": "Transformaciones trigonométricas",
          "subtemas": []
        },
        {
          "tema": "Resolución de triángulos oblicuángulos",
          "subtemas": []
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "razonamiento_matematico",
      "nombre": "Razonamiento Matemático y Lógico",
      "bloques_oficiales_relacionados": [
        "Matemática"
      ],
      "temas": [
        {
          "tema": "Lógica",
          "subtemas": [
            "Naturaleza",
            "Características",
            "Importancia"
          ]
        },
        {
          "tema": "Proposiciones lógicas",
          "subtemas": [
            "Principios",
            "Leyes",
            "Componentes",
            "Tipos"
          ]
        },
        {
          "tema": "Argumentación",
          "subtemas": [
            "Conceptos",
            "Definiciones",
            "Argumentos",
            "Falacias",
            "Silogismos"
          ]
        },
        {
          "tema": "Conjuntos y relaciones",
          "subtemas": [
            "Teoría de conjuntos",
            "Relaciones binarias",
            "Producto cartesiano"
          ]
        },
        {
          "tema": "Patrones numéricos",
          "subtemas": [
            "Sucesiones",
            "Series",
            "Sumatorias"
          ]
        },
        {
          "tema": "Análisis combinatorio",
          "subtemas": []
        },
        {
          "tema": "Probabilidades",
          "subtemas": []
        },
        {
          "tema": "Estadística introductoria",
          "subtemas": [
            "Medidas de tendencia central"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ],
      "nota": "Curso de preparación organizado a partir de contenidos del eje Matemática; la guía no le asigna preguntas independientes."
    },
    {
      "id": "biologia",
      "nombre": "Biología",
      "bloques_oficiales_relacionados": [
        "Biología"
      ],
      "temas": [
        {
          "tema": "Biología y ciencia de la vida",
          "subtemas": []
        },
        {
          "tema": "Método científico",
          "subtemas": []
        },
        {
          "tema": "Biología celular",
          "subtemas": [
            "Estructura celular",
            "Funcionamiento celular"
          ]
        },
        {
          "tema": "Organización de la materia viva",
          "subtemas": [
            "Tejidos"
          ]
        },
        {
          "tema": "Funciones de relación",
          "subtemas": [
            "Sistema óseo",
            "Sistema muscular",
            "Sistema nervioso",
            "Sistema sensorial",
            "Sistema endocrino"
          ]
        },
        {
          "tema": "Funciones de nutrición",
          "subtemas": [
            "Sistema circulatorio",
            "Sistema respiratorio",
            "Sistema digestivo",
            "Sistema excretor"
          ]
        },
        {
          "tema": "Reproducción de los seres vivos",
          "subtemas": []
        },
        {
          "tema": "Herencia biológica",
          "subtemas": []
        },
        {
          "tema": "Ecología y biodiversidad",
          "subtemas": [
            "Ecosistemas",
            "Equilibrio ecológico",
            "Desequilibrio ecológico"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "fisica",
      "nombre": "Física",
      "bloques_oficiales_relacionados": [
        "Física"
      ],
      "temas": [
        {
          "tema": "Magnitudes físicas",
          "subtemas": [
            "Fundamentales y derivadas",
            "Magnitudes escalares y vectoriales"
          ]
        },
        {
          "tema": "Análisis dimensional",
          "subtemas": [
            "Ecuaciones dimensionales",
            "Principio de homogeneidad"
          ]
        },
        {
          "tema": "Vectores",
          "subtemas": [
            "Operaciones por métodos geométricos",
            "Operaciones por métodos analíticos"
          ]
        },
        {
          "tema": "Cinemática",
          "subtemas": [
            "Posición y desplazamiento",
            "Velocidad media e instantánea",
            "Aceleración media e instantánea",
            "Gráficas del movimiento"
          ]
        },
        {
          "tema": "Movimiento rectilíneo",
          "subtemas": [
            "MRU",
            "MRUV",
            "Movimiento vertical de caída libre"
          ]
        },
        {
          "tema": "Movimiento en dos dimensiones",
          "subtemas": [
            "Proyectiles",
            "Movimiento circular uniforme",
            "Movimiento circular uniformemente variado"
          ]
        },
        {
          "tema": "Dinámica",
          "subtemas": [
            "Primera ley de Newton",
            "Segunda ley de Newton"
          ]
        },
        {
          "tema": "Trabajo, energía y potencia",
          "subtemas": [
            "Trabajo con fuerzas constantes y variables",
            "Energía cinética",
            "Teorema trabajo-energía",
            "Energía potencial gravitatoria y elástica",
            "Conservación de energía mecánica"
          ]
        },
        {
          "tema": "Mecánica de fluidos",
          "subtemas": [
            "Densidad",
            "Presión atmosférica, hidrostática y manométrica",
            "Hidrostática",
            "Principio de Pascal",
            "Principio de Arquímedes",
            "Flotación",
            "Hidrodinámica",
            "Principio de Bernoulli"
          ]
        },
        {
          "tema": "Termodinámica",
          "subtemas": [
            "Temperatura",
            "Teoría cinética molecular",
            "Conservación y transformación de la energía"
          ]
        },
        {
          "tema": "Electrostática",
          "subtemas": [
            "Carga",
            "Fuerza y campo eléctricos",
            "Ley de Coulomb",
            "Líneas de campo",
            "Potencial eléctrico",
            "Energía potencial eléctrica",
            "Superficies equipotenciales"
          ]
        },
        {
          "tema": "Electricidad",
          "subtemas": [
            "Corriente eléctrica",
            "Resistencias",
            "Ley de Ohm",
            "Circuitos",
            "Asociación de resistencias",
            "Leyes de Kirchhoff",
            "Potencia y energía eléctrica",
            "Mediciones eléctricas"
          ]
        },
        {
          "tema": "Magnetismo e inducción",
          "subtemas": [
            "Campo y fuerzas magnéticas",
            "Ley de Biot-Savart",
            "Ley de inducción de Faraday",
            "Ley de Lenz",
            "Transformadores"
          ]
        },
        {
          "tema": "Óptica",
          "subtemas": [
            "Propagación de la luz",
            "Reflexión",
            "Espejos",
            "Lentes"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "quimica",
      "nombre": "Química",
      "bloques_oficiales_relacionados": [
        "Química"
      ],
      "temas": [
        {
          "tema": "Materia y energía",
          "subtemas": [
            "Principios generales de la materia"
          ]
        },
        {
          "tema": "Estructura atómica",
          "subtemas": [
            "El átomo",
            "Estructura atómica",
            "Números cuánticos",
            "Configuración electrónica"
          ]
        },
        {
          "tema": "Fundamentos físico-químicos",
          "subtemas": [
            "Ondas electromagnéticas",
            "Química nuclear"
          ]
        },
        {
          "tema": "Sistema periódico",
          "subtemas": [
            "Tabla periódica"
          ]
        },
        {
          "tema": "Enlace químico",
          "subtemas": [
            "Enlaces químicos"
          ]
        },
        {
          "tema": "Química inorgánica",
          "subtemas": [
            "Funciones químicas inorgánicas"
          ]
        },
        {
          "tema": "Reacciones químicas",
          "subtemas": []
        },
        {
          "tema": "Cálculos químicos",
          "subtemas": [
            "Unidades químicas de masa",
            "Estequiometría"
          ]
        },
        {
          "tema": "Disoluciones",
          "subtemas": [
            "Soluciones"
          ]
        },
        {
          "tema": "Electroquímica",
          "subtemas": []
        },
        {
          "tema": "Cinética y equilibrio",
          "subtemas": [
            "Cinética química",
            "Equilibrio químico"
          ]
        },
        {
          "tema": "Ácidos y bases",
          "subtemas": []
        },
        {
          "tema": "Química orgánica",
          "subtemas": [
            "Fundamentos",
            "Funciones oxigenadas",
            "Funciones nitrogenadas"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "psicologia",
      "nombre": "Psicología y Desarrollo Personal",
      "bloques_oficiales_relacionados": [
        "Desarrollo Personal"
      ],
      "temas": [
        {
          "tema": "Desarrollo humano",
          "subtemas": []
        },
        {
          "tema": "Adolescencia",
          "subtemas": [
            "Cambios biológicos",
            "Cambios cognitivos",
            "Cambios emocionales",
            "Cambios socioculturales"
          ]
        },
        {
          "tema": "Socialización",
          "subtemas": [
            "Agentes sociales",
            "Factores de riesgo"
          ]
        },
        {
          "tema": "Identidad personal",
          "subtemas": [
            "Formación de la identidad"
          ]
        },
        {
          "tema": "Emociones",
          "subtemas": [
            "Tipos de emociones"
          ]
        },
        {
          "tema": "Inteligencia emocional",
          "subtemas": [
            "Componentes intrapersonales",
            "Componentes interpersonales",
            "Habilidades sociales"
          ]
        },
        {
          "tema": "Proyecto de vida",
          "subtemas": [
            "Sentido de vida",
            "Proyecto de vida"
          ]
        },
        {
          "tema": "Identidad sexual y de género",
          "subtemas": []
        },
        {
          "tema": "Vinculación afectiva",
          "subtemas": []
        },
        {
          "tema": "Salud sexual y reproductiva",
          "subtemas": []
        },
        {
          "tema": "Desarrollo moral",
          "subtemas": [
            "Conducta moral",
            "Principios éticos",
            "Dilemas morales",
            "Dignidad humana"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "filosofia",
      "nombre": "Filosofía",
      "bloques_oficiales_relacionados": [
        "Ciudadanía y Cívica"
      ],
      "temas": [
        {
          "tema": "Introducción a la filosofía",
          "subtemas": [
            "El saber filosófico"
          ]
        },
        {
          "tema": "Teoría del conocimiento",
          "subtemas": []
        },
        {
          "tema": "Epistemología",
          "subtemas": []
        },
        {
          "tema": "Axiología y ética",
          "subtemas": []
        },
        {
          "tema": "Antropología filosófica",
          "subtemas": []
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    },
    {
      "id": "educacion_civica",
      "nombre": "Educación Cívica",
      "bloques_oficiales_relacionados": [
        "Ciudadanía y Cívica"
      ],
      "temas": [
        {
          "tema": "Derechos humanos",
          "subtemas": [
            "El ser humano y sus derechos",
            "Dignidad de la persona"
          ]
        },
        {
          "tema": "Ciudadanía en el Perú",
          "subtemas": [
            "Derechos políticos del ciudadano peruano"
          ]
        },
        {
          "tema": "Familia y matrimonio",
          "subtemas": []
        },
        {
          "tema": "Estado y Constitución",
          "subtemas": [
            "Constitución Política del Perú",
            "Poderes del Estado"
          ]
        },
        {
          "tema": "Organismos constitucionales",
          "subtemas": []
        },
        {
          "tema": "Organismos internacionales",
          "subtemas": []
        },
        {
          "tema": "Seguridad y defensa nacional",
          "subtemas": [
            "Servicio militar voluntario"
          ]
        },
        {
          "tema": "Gestión del riesgo de desastres",
          "subtemas": [
            "SINAGERD"
          ]
        },
        {
          "tema": "Convivencia democrática",
          "subtemas": [
            "Cultura de paz"
          ]
        }
      ],
      "fuentes": [
        "guia_2027"
      ]
    }
  ],
  "temas_complementarios_del_documento_2026_ii": {
    "asignatura": "Análisis del discurso",
    "documento": "ejes_2026_ii",
    "pagina_pdf": 2,
    "temas": [
      "Naturaleza y tipos de texto: narrativo, expositivo, argumentativo, descriptivo, instructivo y transaccional",
      "Intertextualidad",
      "Estructura textual",
      "Cohesión, coherencia y adecuación",
      "Marcadores y conectores lógico-textuales",
      "Estrategias y técnicas de lectura",
      "Comprensión lectora literal, inferencial y crítica"
    ],
    "estado_en_2027": "No figura con encabezado independiente en el cuadro de ejes de la Guía 2027; se presenta como referencia complementaria sin asegurar su eliminación o permanencia en el examen."
  },
  "cepunt": {
    "ciclo_de_referencia": "septiembre-diciembre de 2026",
    "modalidad": "presencial y/o virtual según CEPUNT",
    "examenes_sumativos": 3,
    "ponderaciones_segun_reglamento_2027": [
      2,
      3,
      5
    ],
    "semanas_evaluadas": [
      "1-5",
      "6-10",
      "11-16"
    ],
    "nota": "El reglamento indica evaluaciones progresivas de las asignaturas desarrolladas; no confirma que los cursos de este JSON sean la distribución horaria exacta de CEPUNT."
  },
  "notas_metodologicas": [
    "La Guía 2027 publica once bloques oficiales temáticos de evaluación; la organización en dieciocho cursos preuniversitarios es una clasificación pedagógica, no una lista oficial de cursos de CEPUNT.",
    "Los desgloses y subtemas de los cursos pueden hacer explícitos ejemplos didácticos contenidos en ejes generales; no se debe interpretar cada subtema como pregunta garantizada.",
    "La cantidad de preguntas se asigna a bloques grandes por área, nunca a cada curso del desglose.",
    "La tabla 2027 del área C presenta 10/15/18/35/22, diferente de la tabla 2026-II que presenta 15/18/35/22/10; se preservaron los datos de 2027 en áreas_postulacion_2027.",
    "El PDF 2026-II incluye Análisis del discurso como bloque separado; el cuadro de contenidos de la Guía 2027 no lo muestra de esa manera."
  ]
}
';
IF NOT EXISTS(SELECT 1 FROM dbo.TemarioUNT WHERE TemarioId=2027) INSERT dbo.TemarioUNT VALUES(2027,'Admisión 2027',@DocumentoUNT);
DECLARE @ContenidosUNT NVARCHAR(MAX)=N'[{"codigo": "historia_peru:1", "curso": "Historia del Perú", "tema": "Perú prehispánico", "subtemas": ["Primeras sociedades del Perú", "Culturas y procesos anteriores al Tahuantinsuyo"]}, {"codigo": "historia_peru:2", "curso": "Historia del Perú", "tema": "Los incas", "subtemas": ["Organización y expansión del Tahuantinsuyo"]}, {"codigo": "historia_peru:3", "curso": "Historia del Perú", "tema": "Virreinato del Perú", "subtemas": ["Organización y sociedad colonial"]}, {"codigo": "historia_peru:4", "curso": "Historia del Perú", "tema": "Emancipación del Perú", "subtemas": ["Proceso de independencia"]}, {"codigo": "historia_peru:5", "curso": "Historia del Perú", "tema": "Prosperidad falaz", "subtemas": ["Etapa del guano"]}, {"codigo": "historia_peru:6", "curso": "Historia del Perú", "tema": "Guerra del guano y del salitre", "subtemas": ["Guerra del Pacífico"]}, {"codigo": "historia_peru:7", "curso": "Historia del Perú", "tema": "Perú republicano de los siglos XIX y XX", "subtemas": ["Procesos políticos, sociales y económicos"]}, {"codigo": "historia_peru:8", "curso": "Historia del Perú", "tema": "Gobiernos del Perú entre 1948 y 1980", "subtemas": []}, {"codigo": "historia_peru:9", "curso": "Historia del Perú", "tema": "Gobiernos del Perú entre 1980 y 2001", "subtemas": []}, {"codigo": "historia_universal:1", "curso": "Historia Universal", "tema": "Historia y prehistoria", "subtemas": ["Conceptos y periodización histórica"]}, {"codigo": "historia_universal:2", "curso": "Historia Universal", "tema": "Altas culturas de Occidente", "subtemas": []}, {"codigo": "historia_universal:3", "curso": "Historia Universal", "tema": "Edad Media", "subtemas": []}, {"codigo": "historia_universal:4", "curso": "Historia Universal", "tema": "Viajes europeos y colonización de América", "subtemas": []}, {"codigo": "historia_universal:5", "curso": "Historia Universal", "tema": "Grandes revoluciones del siglo XVIII", "subtemas": []}, {"codigo": "historia_universal:6", "curso": "Historia Universal", "tema": "El mundo entre los siglos XIX y XX", "subtemas": []}, {"codigo": "historia_universal:7", "curso": "Historia Universal", "tema": "Segunda Guerra Mundial", "subtemas": []}, {"codigo": "historia_universal:8", "curso": "Historia Universal", "tema": "Guerra Fría", "subtemas": []}, {"codigo": "geografia:1", "curso": "Geografía", "tema": "Espacio geográfico y la Tierra", "subtemas": ["La Tierra como morada humana", "Localización y representación de la Tierra"]}, {"codigo": "geografia:2", "curso": "Geografía", "tema": "Geología y relieve", "subtemas": ["Geología", "Modelado del paisaje"]}, {"codigo": "geografia:3", "curso": "Geografía", "tema": "Medioambiente y sociedad", "subtemas": ["Relación del ser humano con el medioambiente"]}, {"codigo": "geografia:4", "curso": "Geografía", "tema": "Climatología", "subtemas": ["Estudio del clima"]}, {"codigo": "geografia:5", "curso": "Geografía", "tema": "Geografía física del Perú", "subtemas": ["Ubicación y geoformas del relieve", "Hidrografía"]}, {"codigo": "geografia:6", "curso": "Geografía", "tema": "Organización territorial y población del Perú", "subtemas": ["Organización político-administrativa", "Población humana"]}, {"codigo": "geografia:7", "curso": "Geografía", "tema": "Ocho regiones naturales del Perú", "subtemas": []}, {"codigo": "geografia:8", "curso": "Geografía", "tema": "Sostenibilidad y ecología", "subtemas": ["Desarrollo sostenible", "Equilibrio ecológico"]}, {"codigo": "geografia:9", "curso": "Geografía", "tema": "Geografía económica del Perú", "subtemas": []}, {"codigo": "geografia:10", "curso": "Geografía", "tema": "Geografía de La Libertad", "subtemas": ["Naturaleza, cultura y desarrollo regional"]}, {"codigo": "geografia:11", "curso": "Geografía", "tema": "Geografía continental", "subtemas": ["América", "Europa", "Asia", "África", "Oceanía"]}, {"codigo": "geografia:12", "curso": "Geografía", "tema": "Geopolítica", "subtemas": ["Juego del poder mundial"]}, {"codigo": "economia:1", "curso": "Economía", "tema": "Fundamentos de economía", "subtemas": ["Manifestaciones económicas y su evolución"]}, {"codigo": "economia:2", "curso": "Economía", "tema": "Necesidades, bienes y recursos", "subtemas": ["Necesidades sociales", "Bienes económicos", "Recursos"]}, {"codigo": "economia:3", "curso": "Economía", "tema": "Factores productivos", "subtemas": ["Tierra", "Trabajo", "Capital"]}, {"codigo": "economia:4", "curso": "Economía", "tema": "Oferta y demanda", "subtemas": ["Demanda", "Oferta", "Elasticidades del mercado"]}, {"codigo": "economia:5", "curso": "Economía", "tema": "Organizaciones empresariales", "subtemas": ["Tipos de empresa"]}, {"codigo": "economia:6", "curso": "Economía", "tema": "Producción y costos", "subtemas": ["Producción", "Costos de corto plazo", "Costos de largo plazo"]}, {"codigo": "economia:7", "curso": "Economía", "tema": "Modelos y estructuras de mercado", "subtemas": []}, {"codigo": "economia:8", "curso": "Economía", "tema": "Dinero y sistema monetario", "subtemas": ["Mercado monetario"]}, {"codigo": "economia:9", "curso": "Economía", "tema": "Sistema financiero", "subtemas": ["Operaciones crediticias", "Instrumentos del crédito"]}, {"codigo": "economia:10", "curso": "Economía", "tema": "Estado y economía", "subtemas": ["Intervención del Estado", "Tributación en el Perú"]}, {"codigo": "economia:11", "curso": "Economía", "tema": "Economía internacional", "subtemas": ["Comercio exterior", "Finanzas del sector externo"]}, {"codigo": "economia:12", "curso": "Economía", "tema": "Macroeconomía", "subtemas": ["Crecimiento económico", "Ciclo económico", "Perturbaciones económicas"]}, {"codigo": "lenguaje:1", "curso": "Lenguaje y Comunicología", "tema": "Comunicación humana", "subtemas": ["Proceso comunicativo", "Elementos", "Fines", "Formas"]}, {"codigo": "lenguaje:2", "curso": "Lenguaje y Comunicología", "tema": "Comunicación oral", "subtemas": ["Estrategias y técnicas", "Comunicación efectiva"]}, {"codigo": "lenguaje:3", "curso": "Lenguaje y Comunicología", "tema": "Signos y códigos", "subtemas": ["Signos de la comunicación humana", "Códigos"]}, {"codigo": "lenguaje:4", "curso": "Lenguaje y Comunicología", "tema": "Gramática", "subtemas": ["Elementos gramaticales"]}, {"codigo": "lenguaje:5", "curso": "Lenguaje y Comunicología", "tema": "Oración", "subtemas": ["Estructura de la oración", "Tipos de oración"]}, {"codigo": "lenguaje:6", "curso": "Lenguaje y Comunicología", "tema": "Semántica", "subtemas": ["Significado", "Significación", "Sentido"]}, {"codigo": "lenguaje:7", "curso": "Lenguaje y Comunicología", "tema": "Relaciones léxico-semánticas", "subtemas": []}, {"codigo": "lenguaje:8", "curso": "Lenguaje y Comunicología", "tema": "Normativa del español", "subtemas": ["Ortografía", "Puntuación"]}, {"codigo": "lenguaje:9", "curso": "Lenguaje y Comunicología", "tema": "Producción textual", "subtemas": ["Fundamentos", "Elementos", "Recursos y requisitos", "Estrategias y técnicas de redacción"]}, {"codigo": "razonamiento_verbal:1", "curso": "Razonamiento Verbal y Comprensión Lectora", "tema": "Significado y relaciones semánticas", "subtemas": ["Sentido contextual", "Relaciones léxico-semánticas"]}, {"codigo": "razonamiento_verbal:2", "curso": "Razonamiento Verbal y Comprensión Lectora", "tema": "Textos y tipologías", "subtemas": ["Texto narrativo", "Texto expositivo", "Texto argumentativo", "Texto descriptivo", "Texto instructivo", "Texto transaccional"]}, {"codigo": "razonamiento_verbal:3", "curso": "Razonamiento Verbal y Comprensión Lectora", "tema": "Organización del discurso", "subtemas": ["Estructura textual", "Intertextualidad"]}, {"codigo": "razonamiento_verbal:4", "curso": "Razonamiento Verbal y Comprensión Lectora", "tema": "Propiedades del texto", "subtemas": ["Cohesión", "Coherencia", "Adecuación"]}, {"codigo": "razonamiento_verbal:5", "curso": "Razonamiento Verbal y Comprensión Lectora", "tema": "Conectores textuales", "subtemas": ["Marcadores textuales", "Conectores lógico-textuales"]}, {"codigo": "razonamiento_verbal:6", "curso": "Razonamiento Verbal y Comprensión Lectora", "tema": "Comprensión de lectura", "subtemas": ["Nivel literal", "Nivel inferencial", "Nivel crítico"]}, {"codigo": "razonamiento_verbal:7", "curso": "Razonamiento Verbal y Comprensión Lectora", "tema": "Estrategias de lectura", "subtemas": ["Técnicas de lectura y comprensión"]}, {"codigo": "literatura:1", "curso": "Literatura", "tema": "Teoría literaria", "subtemas": ["Naturaleza y características del texto literario", "Tipos de texto literario", "Técnicas y recursos de construcción literaria"]}, {"codigo": "literatura:2", "curso": "Literatura", "tema": "Literatura universal", "subtemas": ["Edipo rey", "La divina comedia", "Hamlet", "Ensayo sobre la ceguera"]}, {"codigo": "literatura:3", "curso": "Literatura", "tema": "Literatura española", "subtemas": ["El ingenioso hidalgo don Quijote de la Mancha", "Fuenteovejuna"]}, {"codigo": "literatura:4", "curso": "Literatura", "tema": "Literatura latinoamericana", "subtemas": ["Cien años de soledad", "Veinte poemas de amor y una canción desesperada", "El túnel"]}, {"codigo": "literatura:5", "curso": "Literatura", "tema": "Literatura peruana", "subtemas": ["El mundo es ancho y ajeno", "Trilce", "La ciudad y los perros"]}, {"codigo": "literatura:6", "curso": "Literatura", "tema": "Literatura regional", "subtemas": ["El huso de la palabra"]}, {"codigo": "aritmetica:1", "curso": "Aritmética", "tema": "Conjuntos", "subtemas": ["Teoría de conjuntos"]}, {"codigo": "aritmetica:2", "curso": "Aritmética", "tema": "Sistemas de numeración", "subtemas": []}, {"codigo": "aritmetica:3", "curso": "Aritmética", "tema": "Números reales", "subtemas": ["Propiedades y operaciones"]}, {"codigo": "aritmetica:4", "curso": "Aritmética", "tema": "Divisibilidad", "subtemas": []}, {"codigo": "aritmetica:5", "curso": "Aritmética", "tema": "Magnitudes proporcionales", "subtemas": ["Proporcionalidad"]}, {"codigo": "aritmetica:6", "curso": "Aritmética", "tema": "Matemática financiera básica", "subtemas": ["Regla de interés"]}, {"codigo": "algebra:1", "curso": "Álgebra", "tema": "Expresiones algebraicas", "subtemas": ["Operaciones con expresiones algebraicas"]}, {"codigo": "algebra:2", "curso": "Álgebra", "tema": "Productos y cocientes notables", "subtemas": []}, {"codigo": "algebra:3", "curso": "Álgebra", "tema": "Factorización y binomio de Newton", "subtemas": []}, {"codigo": "algebra:4", "curso": "Álgebra", "tema": "Ecuaciones", "subtemas": ["Lineales", "Cuadráticas", "Polinómicas", "Con valor absoluto", "Exponenciales", "Logarítmicas"]}, {"codigo": "algebra:5", "curso": "Álgebra", "tema": "Inecuaciones", "subtemas": ["Lineales", "Cuadráticas", "Polinómicas", "Con valor absoluto", "Exponenciales"]}, {"codigo": "algebra:6", "curso": "Álgebra", "tema": "Intervalos", "subtemas": []}, {"codigo": "algebra:7", "curso": "Álgebra", "tema": "Relaciones y conjuntos cartesianos", "subtemas": ["Relaciones binarias", "Producto cartesiano"]}, {"codigo": "algebra:8", "curso": "Álgebra", "tema": "Funciones", "subtemas": ["Definición y elementos", "Dominio y rango", "Constante", "Lineal", "Cuadrática", "Racional", "Raíz cuadrada", "Valor absoluto", "Exponencial", "Logarítmica"]}, {"codigo": "algebra:9", "curso": "Álgebra", "tema": "Operaciones entre funciones", "subtemas": ["Adición", "Sustracción", "Multiplicación", "División", "Composición"]}, {"codigo": "algebra:10", "curso": "Álgebra", "tema": "Sucesiones y series", "subtemas": ["Sucesiones", "Series", "Sumatorias"]}, {"codigo": "geometria:1", "curso": "Geometría", "tema": "Geometría plana", "subtemas": ["Segmentos", "Ángulos", "Triángulos"]}, {"codigo": "geometria:2", "curso": "Geometría", "tema": "Polígonos y cuadriláteros", "subtemas": []}, {"codigo": "geometria:3", "curso": "Geometría", "tema": "Circunferencia y círculo", "subtemas": []}, {"codigo": "geometria:4", "curso": "Geometría", "tema": "Medición de regiones planas", "subtemas": ["Áreas", "Perímetros"]}, {"codigo": "geometria:5", "curso": "Geometría", "tema": "Geometría analítica", "subtemas": ["Introducción y plano cartesiano"]}, {"codigo": "geometria:6", "curso": "Geometría", "tema": "La recta en el plano", "subtemas": ["Ecuación cartesiana", "Pendiente", "Ángulo entre dos rectas", "Paralelismo", "Perpendicularidad"]}, {"codigo": "geometria:7", "curso": "Geometría", "tema": "Regiones poligonales", "subtemas": ["Áreas en el plano cartesiano"]}, {"codigo": "geometria:8", "curso": "Geometría", "tema": "Cónicas", "subtemas": ["Circunferencia", "Parábola", "Elipse", "Hipérbola"]}, {"codigo": "trigonometria:1", "curso": "Trigonometría", "tema": "Medición angular", "subtemas": ["Sistemas de medidas angulares"]}, {"codigo": "trigonometria:2", "curso": "Trigonometría", "tema": "Razones trigonométricas", "subtemas": []}, {"codigo": "trigonometria:3", "curso": "Trigonometría", "tema": "Identidades trigonométricas", "subtemas": []}, {"codigo": "trigonometria:4", "curso": "Trigonometría", "tema": "Funciones trigonométricas", "subtemas": []}, {"codigo": "trigonometria:5", "curso": "Trigonometría", "tema": "Transformaciones trigonométricas", "subtemas": []}, {"codigo": "trigonometria:6", "curso": "Trigonometría", "tema": "Resolución de triángulos oblicuángulos", "subtemas": []}, {"codigo": "razonamiento_matematico:1", "curso": "Razonamiento Matemático y Lógico", "tema": "Lógica", "subtemas": ["Naturaleza", "Características", "Importancia"]}, {"codigo": "razonamiento_matematico:2", "curso": "Razonamiento Matemático y Lógico", "tema": "Proposiciones lógicas", "subtemas": ["Principios", "Leyes", "Componentes", "Tipos"]}, {"codigo": "razonamiento_matematico:3", "curso": "Razonamiento Matemático y Lógico", "tema": "Argumentación", "subtemas": ["Conceptos", "Definiciones", "Argumentos", "Falacias", "Silogismos"]}, {"codigo": "razonamiento_matematico:4", "curso": "Razonamiento Matemático y Lógico", "tema": "Conjuntos y relaciones", "subtemas": ["Teoría de conjuntos", "Relaciones binarias", "Producto cartesiano"]}, {"codigo": "razonamiento_matematico:5", "curso": "Razonamiento Matemático y Lógico", "tema": "Patrones numéricos", "subtemas": ["Sucesiones", "Series", "Sumatorias"]}, {"codigo": "razonamiento_matematico:6", "curso": "Razonamiento Matemático y Lógico", "tema": "Análisis combinatorio", "subtemas": []}, {"codigo": "razonamiento_matematico:7", "curso": "Razonamiento Matemático y Lógico", "tema": "Probabilidades", "subtemas": []}, {"codigo": "razonamiento_matematico:8", "curso": "Razonamiento Matemático y Lógico", "tema": "Estadística introductoria", "subtemas": ["Medidas de tendencia central"]}, {"codigo": "biologia:1", "curso": "Biología", "tema": "Biología y ciencia de la vida", "subtemas": []}, {"codigo": "biologia:2", "curso": "Biología", "tema": "Método científico", "subtemas": []}, {"codigo": "biologia:3", "curso": "Biología", "tema": "Biología celular", "subtemas": ["Estructura celular", "Funcionamiento celular"]}, {"codigo": "biologia:4", "curso": "Biología", "tema": "Organización de la materia viva", "subtemas": ["Tejidos"]}, {"codigo": "biologia:5", "curso": "Biología", "tema": "Funciones de relación", "subtemas": ["Sistema óseo", "Sistema muscular", "Sistema nervioso", "Sistema sensorial", "Sistema endocrino"]}, {"codigo": "biologia:6", "curso": "Biología", "tema": "Funciones de nutrición", "subtemas": ["Sistema circulatorio", "Sistema respiratorio", "Sistema digestivo", "Sistema excretor"]}, {"codigo": "biologia:7", "curso": "Biología", "tema": "Reproducción de los seres vivos", "subtemas": []}, {"codigo": "biologia:8", "curso": "Biología", "tema": "Herencia biológica", "subtemas": []}, {"codigo": "biologia:9", "curso": "Biología", "tema": "Ecología y biodiversidad", "subtemas": ["Ecosistemas", "Equilibrio ecológico", "Desequilibrio ecológico"]}, {"codigo": "fisica:1", "curso": "Física", "tema": "Magnitudes físicas", "subtemas": ["Fundamentales y derivadas", "Magnitudes escalares y vectoriales"]}, {"codigo": "fisica:2", "curso": "Física", "tema": "Análisis dimensional", "subtemas": ["Ecuaciones dimensionales", "Principio de homogeneidad"]}, {"codigo": "fisica:3", "curso": "Física", "tema": "Vectores", "subtemas": ["Operaciones por métodos geométricos", "Operaciones por métodos analíticos"]}, {"codigo": "fisica:4", "curso": "Física", "tema": "Cinemática", "subtemas": ["Posición y desplazamiento", "Velocidad media e instantánea", "Aceleración media e instantánea", "Gráficas del movimiento"]}, {"codigo": "fisica:5", "curso": "Física", "tema": "Movimiento rectilíneo", "subtemas": ["MRU", "MRUV", "Movimiento vertical de caída libre"]}, {"codigo": "fisica:6", "curso": "Física", "tema": "Movimiento en dos dimensiones", "subtemas": ["Proyectiles", "Movimiento circular uniforme", "Movimiento circular uniformemente variado"]}, {"codigo": "fisica:7", "curso": "Física", "tema": "Dinámica", "subtemas": ["Primera ley de Newton", "Segunda ley de Newton"]}, {"codigo": "fisica:8", "curso": "Física", "tema": "Trabajo, energía y potencia", "subtemas": ["Trabajo con fuerzas constantes y variables", "Energía cinética", "Teorema trabajo-energía", "Energía potencial gravitatoria y elástica", "Conservación de energía mecánica"]}, {"codigo": "fisica:9", "curso": "Física", "tema": "Mecánica de fluidos", "subtemas": ["Densidad", "Presión atmosférica, hidrostática y manométrica", "Hidrostática", "Principio de Pascal", "Principio de Arquímedes", "Flotación", "Hidrodinámica", "Principio de Bernoulli"]}, {"codigo": "fisica:10", "curso": "Física", "tema": "Termodinámica", "subtemas": ["Temperatura", "Teoría cinética molecular", "Conservación y transformación de la energía"]}, {"codigo": "fisica:11", "curso": "Física", "tema": "Electrostática", "subtemas": ["Carga", "Fuerza y campo eléctricos", "Ley de Coulomb", "Líneas de campo", "Potencial eléctrico", "Energía potencial eléctrica", "Superficies equipotenciales"]}, {"codigo": "fisica:12", "curso": "Física", "tema": "Electricidad", "subtemas": ["Corriente eléctrica", "Resistencias", "Ley de Ohm", "Circuitos", "Asociación de resistencias", "Leyes de Kirchhoff", "Potencia y energía eléctrica", "Mediciones eléctricas"]}, {"codigo": "fisica:13", "curso": "Física", "tema": "Magnetismo e inducción", "subtemas": ["Campo y fuerzas magnéticas", "Ley de Biot-Savart", "Ley de inducción de Faraday", "Ley de Lenz", "Transformadores"]}, {"codigo": "fisica:14", "curso": "Física", "tema": "Óptica", "subtemas": ["Propagación de la luz", "Reflexión", "Espejos", "Lentes"]}, {"codigo": "quimica:1", "curso": "Química", "tema": "Materia y energía", "subtemas": ["Principios generales de la materia"]}, {"codigo": "quimica:2", "curso": "Química", "tema": "Estructura atómica", "subtemas": ["El átomo", "Estructura atómica", "Números cuánticos", "Configuración electrónica"]}, {"codigo": "quimica:3", "curso": "Química", "tema": "Fundamentos físico-químicos", "subtemas": ["Ondas electromagnéticas", "Química nuclear"]}, {"codigo": "quimica:4", "curso": "Química", "tema": "Sistema periódico", "subtemas": ["Tabla periódica"]}, {"codigo": "quimica:5", "curso": "Química", "tema": "Enlace químico", "subtemas": ["Enlaces químicos"]}, {"codigo": "quimica:6", "curso": "Química", "tema": "Química inorgánica", "subtemas": ["Funciones químicas inorgánicas"]}, {"codigo": "quimica:7", "curso": "Química", "tema": "Reacciones químicas", "subtemas": []}, {"codigo": "quimica:8", "curso": "Química", "tema": "Cálculos químicos", "subtemas": ["Unidades químicas de masa", "Estequiometría"]}, {"codigo": "quimica:9", "curso": "Química", "tema": "Disoluciones", "subtemas": ["Soluciones"]}, {"codigo": "quimica:10", "curso": "Química", "tema": "Electroquímica", "subtemas": []}, {"codigo": "quimica:11", "curso": "Química", "tema": "Cinética y equilibrio", "subtemas": ["Cinética química", "Equilibrio químico"]}, {"codigo": "quimica:12", "curso": "Química", "tema": "Ácidos y bases", "subtemas": []}, {"codigo": "quimica:13", "curso": "Química", "tema": "Química orgánica", "subtemas": ["Fundamentos", "Funciones oxigenadas", "Funciones nitrogenadas"]}, {"codigo": "psicologia:1", "curso": "Psicología y Desarrollo Personal", "tema": "Desarrollo humano", "subtemas": []}, {"codigo": "psicologia:2", "curso": "Psicología y Desarrollo Personal", "tema": "Adolescencia", "subtemas": ["Cambios biológicos", "Cambios cognitivos", "Cambios emocionales", "Cambios socioculturales"]}, {"codigo": "psicologia:3", "curso": "Psicología y Desarrollo Personal", "tema": "Socialización", "subtemas": ["Agentes sociales", "Factores de riesgo"]}, {"codigo": "psicologia:4", "curso": "Psicología y Desarrollo Personal", "tema": "Identidad personal", "subtemas": ["Formación de la identidad"]}, {"codigo": "psicologia:5", "curso": "Psicología y Desarrollo Personal", "tema": "Emociones", "subtemas": ["Tipos de emociones"]}, {"codigo": "psicologia:6", "curso": "Psicología y Desarrollo Personal", "tema": "Inteligencia emocional", "subtemas": ["Componentes intrapersonales", "Componentes interpersonales", "Habilidades sociales"]}, {"codigo": "psicologia:7", "curso": "Psicología y Desarrollo Personal", "tema": "Proyecto de vida", "subtemas": ["Sentido de vida", "Proyecto de vida"]}, {"codigo": "psicologia:8", "curso": "Psicología y Desarrollo Personal", "tema": "Identidad sexual y de género", "subtemas": []}, {"codigo": "psicologia:9", "curso": "Psicología y Desarrollo Personal", "tema": "Vinculación afectiva", "subtemas": []}, {"codigo": "psicologia:10", "curso": "Psicología y Desarrollo Personal", "tema": "Salud sexual y reproductiva", "subtemas": []}, {"codigo": "psicologia:11", "curso": "Psicología y Desarrollo Personal", "tema": "Desarrollo moral", "subtemas": ["Conducta moral", "Principios éticos", "Dilemas morales", "Dignidad humana"]}, {"codigo": "filosofia:1", "curso": "Filosofía", "tema": "Introducción a la filosofía", "subtemas": ["El saber filosófico"]}, {"codigo": "filosofia:2", "curso": "Filosofía", "tema": "Teoría del conocimiento", "subtemas": []}, {"codigo": "filosofia:3", "curso": "Filosofía", "tema": "Epistemología", "subtemas": []}, {"codigo": "filosofia:4", "curso": "Filosofía", "tema": "Axiología y ética", "subtemas": []}, {"codigo": "filosofia:5", "curso": "Filosofía", "tema": "Antropología filosófica", "subtemas": []}, {"codigo": "educacion_civica:1", "curso": "Educación Cívica", "tema": "Derechos humanos", "subtemas": ["El ser humano y sus derechos", "Dignidad de la persona"]}, {"codigo": "educacion_civica:2", "curso": "Educación Cívica", "tema": "Ciudadanía en el Perú", "subtemas": ["Derechos políticos del ciudadano peruano"]}, {"codigo": "educacion_civica:3", "curso": "Educación Cívica", "tema": "Familia y matrimonio", "subtemas": []}, {"codigo": "educacion_civica:4", "curso": "Educación Cívica", "tema": "Estado y Constitución", "subtemas": ["Constitución Política del Perú", "Poderes del Estado"]}, {"codigo": "educacion_civica:5", "curso": "Educación Cívica", "tema": "Organismos constitucionales", "subtemas": []}, {"codigo": "educacion_civica:6", "curso": "Educación Cívica", "tema": "Organismos internacionales", "subtemas": []}, {"codigo": "educacion_civica:7", "curso": "Educación Cívica", "tema": "Seguridad y defensa nacional", "subtemas": ["Servicio militar voluntario"]}, {"codigo": "educacion_civica:8", "curso": "Educación Cívica", "tema": "Gestión del riesgo de desastres", "subtemas": ["SINAGERD"]}, {"codigo": "educacion_civica:9", "curso": "Educación Cívica", "tema": "Convivencia democrática", "subtemas": ["Cultura de paz"]}]';
INSERT dbo.ContenidoUNT(TemarioId,Codigo,Curso,Tema,Subtemas) SELECT 2027,j.codigo,j.curso,j.tema,j.subtemas FROM OPENJSON(@ContenidosUNT) WITH(codigo VARCHAR(100),curso VARCHAR(100),tema VARCHAR(250),subtemas NVARCHAR(MAX) AS JSON) j WHERE NOT EXISTS(SELECT 1 FROM dbo.ContenidoUNT c WHERE c.Codigo=j.codigo);
INSERT dbo.ProgresoTemaUNT(EstudianteId,ContenidoId,Estado,Origen) SELECT e.EstudianteId,c.ContenidoId,CASE WHEN e.EtapaActual<>'CUSTOMER' THEN 'PENDIENTE' WHEN c.ContenidoId%13<e.EstudianteId%5 THEN 'COMPLETADA' WHEN c.ContenidoId%13=e.EstudianteId%5 THEN 'EN_CURSO' ELSE 'PENDIENTE' END,'CARGA_DEMO' FROM dbo.Estudiante e CROSS JOIN dbo.ContenidoUNT c WHERE NOT EXISTS(SELECT 1 FROM dbo.ProgresoTemaUNT p WHERE p.EstudianteId=e.EstudianteId AND p.ContenidoId=c.ContenidoId);
GO

-- Autorización ficticia inicial de reportes por el portal local; no revoca decisiones existentes.
INSERT dbo.AutorizacionContacto(ContactoId,Canal,Finalidad,Autorizado,FechaDecision,Evidencia)
SELECT DISTINCT ap.ContactoId,'PLATAFORMA','REPORTES',1,GETDATE(),N'Aceptación inicial de reportes internos del portal local en el registro de demostración'
FROM dbo.Apoderado ap WHERE EXISTS(SELECT 1 FROM dbo.AutorizacionContacto a WHERE a.ContactoId=ap.ContactoId AND a.Finalidad='REPORTES' AND a.Autorizado=1)
AND NOT EXISTS(SELECT 1 FROM dbo.AutorizacionContacto a WHERE a.ContactoId=ap.ContactoId AND a.Canal='PLATAFORMA' AND a.Finalidad='REPORTES');
GO

-- AtencionMensaje inicia vacia: los casos de la carga previa son administrativos.
-- Sus vinculos se registran con mensajes reales del portal al reportar o derivar;
-- no se inventan mensajes de origen para los casos preexistentes.
