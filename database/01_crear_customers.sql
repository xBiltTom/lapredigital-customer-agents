
/* LaPreDigital | OLTP CUSTOMERS */
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Creacion de la base con la intercalacion acordada para espanol y Unicode.
IF DB_ID('LaPreDigital_Customers') IS NULL
BEGIN
    CREATE DATABASE LaPreDigital_Customers COLLATE Latin1_General_100_CI_AS_SC;
END
GO

USE LaPreDigital_Customers;
GO

-- Si falla una operacion dentro de una transaccion por un error de ejecucion,
-- SQL Server revierte esa transaccion completa. No la revierte de ocurrir errores de sintaxis.
SET XACT_ABORT ON;
GO

-- 1. PERSONAS, CONTACTOS Y AUTORIZACIONES
CREATE TABLE dbo.PersonalInterno (
    PersonalInternoId               INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Nombre                          VARCHAR(120) NOT NULL,
    Rol                             VARCHAR(15) NOT NULL CHECK (Rol IN (N'DUEÑO','SOPORTE')),
    Activo                          BIT NOT NULL DEFAULT 1
);
GO

-- El ingreso a LEAD se obtiene del primer FormularioContacto valido (FechaEnvio).
-- FechaRegistro indica cuando se creo el registro de contacto en la base.
CREATE TABLE dbo.Contacto (
    ContactoId                      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    NombreCompleto                  VARCHAR(160) NOT NULL,
    Correo                          VARCHAR(254) NULL,
    Telefono                        VARCHAR(25) NULL,
    CanalOrigen                     VARCHAR(25) NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_Contacto_Correo ON dbo.Contacto(Correo) WHERE Correo IS NOT NULL;
CREATE INDEX IX_Contacto_Telefono ON dbo.Contacto(Telefono) WHERE Telefono IS NOT NULL;
GO

CREATE TABLE dbo.FormularioContacto (
    FormularioContactoId            INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ContactoId                      INT NOT NULL REFERENCES dbo.Contacto(ContactoId),
    RolDeclarado                    VARCHAR(15) NOT NULL CHECK (RolDeclarado IN ('ESTUDIANTE','PADRE','MADRE','APODERADO')),
    FechaEnvio                      DATETIME2(0) NOT NULL,
    CanalOrigen                     VARCHAR(25) NOT NULL,
    Valido                          BIT NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE dbo.Apoderado (
    ApoderadoId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ContactoId                      INT NOT NULL UNIQUE REFERENCES dbo.Contacto(ContactoId)
);
GO

CREATE TABLE dbo.Estudiante (
    EstudianteId                    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Codigo                          VARCHAR(20) NOT NULL UNIQUE,
    ContactoId                      INT NOT NULL UNIQUE REFERENCES dbo.Contacto(ContactoId),
    ApoderadoId                     INT NULL REFERENCES dbo.Apoderado(ApoderadoId),
    Parentesco                      VARCHAR(30) NULL,
    UniversidadObjetivo             VARCHAR(150) NOT NULL DEFAULT 'Universidad Nacional de Trujillo',
    CarreraObjetivo                 VARCHAR(120) NULL,
    FechaExamen                     DATE NULL,
    DisponibilidadSemanalHoras      DECIMAL(5,2) NULL CHECK (DisponibilidadSemanalHoras BETWEEN 0 AND 168),
    EtapaActual                     VARCHAR(10) NOT NULL CHECK (EtapaActual IN ('LEAD','PAYER','CUSTOMER','TURNED')),
    PrioridadComercial              VARCHAR(5) NULL CHECK (PrioridadComercial IN ('ALTA','MEDIA','BAJA','NULA')),
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE dbo.AutorizacionContacto (
    AutorizacionContactoId          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ContactoId                      INT NOT NULL REFERENCES dbo.Contacto(ContactoId),
    Canal                           VARCHAR(10) NOT NULL CHECK (Canal IN ('EMAIL','WHATSAPP','PLATAFORMA')),
    Finalidad                       VARCHAR(15) NOT NULL CHECK (Finalidad IN ('ACADEMICA','COMERCIAL','REPORTES')),
    Autorizado                      BIT NOT NULL,
    FechaDecision                   DATETIME2(0) NOT NULL,
    Evidencia                       NVARCHAR(300) NOT NULL,
    UNIQUE (ContactoId, Canal, Finalidad)
);
GO

-- 2. PLANES Y PRESTACIONES
CREATE TABLE dbo.PlanServicio (
    PlanServicioId                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Codigo                          VARCHAR(20) NOT NULL UNIQUE,
    Nombre                          VARCHAR(80) NOT NULL,
    Nivel                           TINYINT NOT NULL UNIQUE,
    Activo                          BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE dbo.ModalidadPlan (
    ModalidadPlanId                 INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PlanServicioId                  INT NOT NULL REFERENCES dbo.PlanServicio(PlanServicioId),
    Meses                           TINYINT NOT NULL CHECK (Meses IN (1,6)),
    PrecioPEN                       DECIMAL(10,2) NOT NULL CHECK (PrecioPEN > 0),
    Activo                          BIT NOT NULL DEFAULT 1,
    UNIQUE                          (PlanServicioId, Meses)
);
GO
CREATE TABLE dbo.Prestacion (
    PrestacionId                    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Codigo                          VARCHAR(35) NOT NULL UNIQUE,
    Descripcion                     VARCHAR(200) NOT NULL
);
GO

CREATE TABLE dbo.PlanPrestacion (
    PlanServicioId                  INT NOT NULL REFERENCES dbo.PlanServicio(PlanServicioId),
    PrestacionId                    INT NOT NULL REFERENCES dbo.Prestacion(PrestacionId),
    PRIMARY KEY (PlanServicioId, PrestacionId)
);
GO
-- 3. CONTRATACION, PERIODOS Y PAGOS (dependencias de CUSTOMERS)

CREATE TABLE dbo.Suscripcion (
    SuscripcionId                   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteId                    INT NOT NULL REFERENCES dbo.Estudiante(EstudianteId),
    ResponsableEconomicoId          INT NULL REFERENCES dbo.Contacto(ContactoId),
    FechaContratacion               DATETIME2(0) NOT NULL,
    RenovacionAutomatica            BIT NOT NULL,
    FechaDesactivacionRenovacion    DATETIME2(0) NULL,
    Estado                          VARCHAR(12) NOT NULL CHECK (Estado IN ('VIGENTE','FINALIZADA','ANULADA')),
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    UNIQUE (SuscripcionId, EstudianteId),
    CHECK (RenovacionAutomatica = 0 OR FechaDesactivacionRenovacion IS NULL)
);
GO
CREATE UNIQUE INDEX UX_Suscripcion_Activa ON dbo.Suscripcion(EstudianteId) WHERE Estado = 'VIGENTE';
GO
CREATE TABLE dbo.PeriodoServicio (
    PeriodoServicioId               INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SuscripcionId                   INT NOT NULL REFERENCES dbo.Suscripcion(SuscripcionId),
    ModalidadPlanId                 INT NOT NULL REFERENCES dbo.ModalidadPlan(ModalidadPlanId),
    PeriodoAnteriorId               INT NULL REFERENCES dbo.PeriodoServicio(PeriodoServicioId),
    Tipo                            VARCHAR(12) NOT NULL CHECK (Tipo IN ('INICIAL','RENOVACION','REACTIVACION')),
    Inicio                          DATETIME2(0) NOT NULL,
    Fin                             DATETIME2(0) NOT NULL,
    PrecioAcordadoPEN               DECIMAL(10,2) NOT NULL CHECK (PrecioAcordadoPEN > 0),
    BecaPorcentaje                  DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (BecaPorcentaje BETWEEN 0 AND 100),
    DescuentoPEN                    DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (DescuentoPEN >= 0),
    ImporteExigiblePEN              DECIMAL(10,2) NOT NULL CHECK (ImporteExigiblePEN >= 0),
    AutorizadoPorId                 INT NULL REFERENCES dbo.PersonalInterno(PersonalInternoId),
    FechaAutorizacion               DATETIME2(0) NULL,
    CondicionesAceptadas            VARCHAR(1000) NOT NULL,
    BeneficiosExtra                 VARCHAR(500) NULL,
    EstadoAcceso                    VARCHAR(15) NOT NULL CHECK (EstadoAcceso IN ('PENDIENTE','HABILITADO','CON_INCIDENCIA','FINALIZADO','ANULADO')),
    FechaHabilitacion               DATETIME2(0) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    UNIQUE (PeriodoServicioId, SuscripcionId),
    CHECK (Fin > Inicio),
    CHECK (PeriodoAnteriorId IS NULL OR PeriodoAnteriorId <> PeriodoServicioId),
    CHECK (ImporteExigiblePEN = ROUND(PrecioAcordadoPEN * (100 - BecaPorcentaje) / 100.0, 2) - DescuentoPEN),
    CHECK ((BecaPorcentaje = 0 AND DescuentoPEN = 0) OR (AutorizadoPorId IS NOT NULL AND FechaAutorizacion IS NOT NULL)),
    CHECK (BecaPorcentaje = 100 OR ImporteExigiblePEN > 0),
    CHECK (EstadoAcceso NOT IN ('HABILITADO','CON_INCIDENCIA') OR FechaHabilitacion IS NOT NULL)
);
GO
CREATE INDEX IX_PeriodoServicio_Vigencia ON dbo.PeriodoServicio(SuscripcionId, Inicio, Fin);
GO
CREATE TABLE dbo.Pago (
    PagoId                          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PeriodoServicioId               INT NOT NULL REFERENCES dbo.PeriodoServicio(PeriodoServicioId),
    PagadorContactoId               INT NULL REFERENCES dbo.Contacto(ContactoId),
    CodigoOperacion                 VARCHAR(80) NOT NULL UNIQUE,
    Proveedor                       VARCHAR(60) NOT NULL,
    Canal                           VARCHAR(10) NOT NULL CHECK (Canal IN ('TARJETA','YAPE','PLIN')),
    Tipo                            VARCHAR(12) NOT NULL CHECK (Tipo IN ('COBRO','REEMBOLSO','REVERSION','DISPUTA')),
    PagoOriginalId                  INT NULL REFERENCES dbo.Pago(PagoId),
    Estado                          VARCHAR(12) NOT NULL CHECK (Estado IN ('PENDIENTE','CONFIRMADO','FALLIDO')),
    Moneda                          CHAR(3) NOT NULL DEFAULT 'PEN' CHECK (Moneda = 'PEN'),
    ImportePEN                      DECIMAL(10,2) NOT NULL CHECK (ImportePEN > 0),
    ImpuestosPEN                    DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (ImpuestosPEN >= 0),
    ComisionPEN                     DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (ComisionPEN >= 0),
    NetoPEN                         AS CONVERT(DECIMAL(10,2), ImportePEN - ImpuestosPEN - ComisionPEN) PERSISTED,
    FechaOperacion                  DATETIME2(0) NOT NULL,
    FechaConfirmacion               DATETIME2(0) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    CHECK (ImpuestosPEN + ComisionPEN <= ImportePEN),
    CHECK (Estado <> 'CONFIRMADO' OR FechaConfirmacion IS NOT NULL),
    CHECK (FechaConfirmacion IS NULL OR FechaConfirmacion >= FechaOperacion),
    CHECK ((Tipo = 'COBRO' AND PagoOriginalId IS NULL) OR (Tipo <> 'COBRO' AND PagoOriginalId IS NOT NULL))
);
GO
CREATE UNIQUE INDEX UX_Pago_CobroConfirmado ON dbo.Pago(PeriodoServicioId) WHERE Tipo = 'COBRO' AND Estado = 'CONFIRMADO';
GO
CREATE TABLE dbo.CambioEtapa (
    CambioEtapaId                   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteId                    INT NOT NULL REFERENCES dbo.Estudiante(EstudianteId),
    EtapaOrigen                     VARCHAR(10) NULL CHECK (EtapaOrigen IN ('LEAD','PAYER','CUSTOMER','TURNED')),
    EtapaDestino                    VARCHAR(10) NOT NULL CHECK (EtapaDestino IN ('LEAD','PAYER','CUSTOMER','TURNED')),
    FechaCambio                     DATETIME2(0) NOT NULL,
    Motivo                          VARCHAR(250) NOT NULL,
    SuscripcionId                   INT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (SuscripcionId, EstudianteId) REFERENCES dbo.Suscripcion(SuscripcionId, EstudianteId),
    CHECK (EtapaOrigen IS NULL OR EtapaOrigen <> EtapaDestino)
);
GO
CREATE TABLE dbo.BajaServicio (
    BajaServicioId                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PeriodoServicioId               INT NOT NULL UNIQUE REFERENCES dbo.PeriodoServicio(PeriodoServicioId),
    FechaBaja                       DATETIME2(0) NOT NULL,
    Tipo                            VARCHAR(12) NOT NULL CHECK (Tipo IN ('VENCIMIENTO','CANCELACION')),
    MotivoComunicado                NVARCHAR(400) NULL,
    FechaMotivo                     DATETIME2(0) NULL,
    ElegibleReactivacion            BIT NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO
-- 4. SERVICIO ACADEMICO: CONTENIDOS, RUTAS Y EVALUACIONES

CREATE TABLE dbo.Curso (
    CursoId                         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Nombre                          VARCHAR(100) NOT NULL UNIQUE
);
GO
CREATE TABLE dbo.Tema (
    TemaId                          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CursoId                         INT NOT NULL REFERENCES dbo.Curso(CursoId),
    Nombre                          VARCHAR(120) NOT NULL,
    UNIQUE (CursoId, Nombre)
);
GO
CREATE TABLE dbo.RecursoAcademico (
    RecursoAcademicoId              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TemaId                          INT NOT NULL REFERENCES dbo.Tema(TemaId),
    Titulo                          VARCHAR(180) NOT NULL,
    Tipo                            VARCHAR(20) NOT NULL CHECK (Tipo IN ('TEXTO','PDF','VIDEO','EJERCICIO','EJEMPLO_RESUELTO','EXAMEN_DESARROLLADO','EVALUACION','SIMULACRO')),
    Ubicacion                       VARCHAR(500) NULL,
    DuracionEstimadaMin             SMALLINT NULL CHECK (DuracionEstimadaMin > 0),
    Activo                          BIT NOT NULL DEFAULT 1
);
GO
CREATE TABLE dbo.RutaEstudio (
    RutaEstudioId                   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteId                    INT NOT NULL REFERENCES dbo.Estudiante(EstudianteId),
    VersionNumero                   SMALLINT NOT NULL CHECK (VersionNumero > 0),
    Objetivo                        VARCHAR(350) NOT NULL,
    FechaExamenObjetivo             DATE NULL,
    Inicio                          DATETIME2(0) NOT NULL,
    FinPrevisto                     DATETIME2(0) NULL,
    Vigente                         BIT NOT NULL,
    ActualizadaPorId                INT NOT NULL REFERENCES dbo.PersonalInterno(PersonalInternoId),
    FechaActualizacion              DATETIME2(0) NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    UNIQUE (EstudianteId, VersionNumero),
    UNIQUE (RutaEstudioId, EstudianteId),
    CHECK (FinPrevisto IS NULL OR FinPrevisto > Inicio)
);
GO
CREATE UNIQUE INDEX UX_RutaEstudio_Vigente ON dbo.RutaEstudio(EstudianteId) WHERE Vigente = 1;
GO
CREATE TABLE dbo.ActividadRuta (
    ActividadRutaId                 INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    RutaEstudioId                   INT NOT NULL REFERENCES dbo.RutaEstudio(RutaEstudioId),
    RecursoAcademicoId              INT NOT NULL REFERENCES dbo.RecursoAcademico(RecursoAcademicoId),
    Orden                           SMALLINT NOT NULL CHECK (Orden > 0),
    FechaPlanificada                DATETIME2(0) NOT NULL,
    FechaLimite                     DATETIME2(0) NOT NULL,
    Estado                          VARCHAR(12) NOT NULL CHECK (Estado IN ('PENDIENTE','EN_CURSO','COMPLETADA','CANCELADA')),
    FechaCompletada                 DATETIME2(0) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    UNIQUE (RutaEstudioId, Orden),
    CHECK (FechaLimite >= FechaPlanificada),
    CHECK ((Estado = 'COMPLETADA' AND FechaCompletada IS NOT NULL) OR (Estado <> 'COMPLETADA' AND FechaCompletada IS NULL))
);
GO
CREATE TABLE dbo.DificultadAcademica (
    DificultadAcademicaId           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteId                    INT NOT NULL REFERENCES dbo.Estudiante(EstudianteId),
    TemaId                          INT NULL REFERENCES dbo.Tema(TemaId),
    Descripcion                     NVARCHAR(600) NOT NULL,
    Origen                          VARCHAR(15) NOT NULL CHECK (Origen IN ('ESTUDIANTE','EVALUACION',N'DUEÑO')),
    FechaIdentificacion             DATETIME2(0) NOT NULL,
    Estado                          VARCHAR(15) NOT NULL CHECK (Estado IN ('IDENTIFICADA','EN_SEGUIMIENTO','SUPERADA')),
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO
CREATE TABLE dbo.RevisionRuta (
    RevisionRutaId                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    RutaEstudioId                   INT NOT NULL REFERENCES dbo.RutaEstudio(RutaEstudioId),
    Motivo                          VARCHAR(20) NOT NULL CHECK (Motivo IN ('CAMBIO_OBJETIVO','CAMBIO_FECHA_EXAMEN','DIFICULTAD_ACADEMICA')),
    FechaIdentificacion             DATETIME2(0) NOT NULL,
    Recomendacion                   NVARCHAR(1000) NULL,
    Estado                          VARCHAR(10) NOT NULL CHECK (Estado IN ('PENDIENTE','REVISADA')),
    RevisadaPorId                   INT NULL REFERENCES dbo.PersonalInterno(PersonalInternoId),
    FechaRevision                   DATETIME2(0) NULL,
    Resultado                       NVARCHAR(1000) NULL,
    RutaResultanteId                INT NULL REFERENCES dbo.RutaEstudio(RutaEstudioId),
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    CHECK ((Estado = 'PENDIENTE' AND FechaRevision IS NULL AND RevisadaPorId IS NULL) OR (Estado = 'REVISADA' AND FechaRevision IS NOT NULL AND RevisadaPorId IS NOT NULL)),
    CHECK (FechaRevision IS NULL OR FechaRevision >= FechaIdentificacion)
);
GO
CREATE TABLE dbo.GrupoComparabilidad (
    GrupoComparabilidadId           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Codigo                          VARCHAR(25) NOT NULL UNIQUE,
    Alcance                         VARCHAR(250) NOT NULL,
    Escala                          VARCHAR(100) NOT NULL,
    Dificultad                      VARCHAR(100) NOT NULL,
    ValidadoPorId                   INT NOT NULL REFERENCES dbo.PersonalInterno(PersonalInternoId)
);
GO
CREATE TABLE dbo.Evaluacion (
    EvaluacionId                    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Nombre                          VARCHAR(160) NOT NULL,
    Tipo                            VARCHAR(12) NOT NULL CHECK (Tipo IN ('DIAGNOSTICO','EVALUACION','SIMULACRO')),
    GrupoComparabilidadId           INT NULL REFERENCES dbo.GrupoComparabilidad(GrupoComparabilidadId),
    TotalPreguntas                  SMALLINT NOT NULL CHECK (TotalPreguntas > 0),
    UNIQUE (EvaluacionId, TotalPreguntas)
);
GO
CREATE TABLE dbo.IntentoEvaluacion (
    IntentoEvaluacionId             INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteId                    INT NOT NULL REFERENCES dbo.Estudiante(EstudianteId),
    EvaluacionId                    INT NOT NULL,
    FechaInicio                     DATETIME2(0) NOT NULL,
    FechaFin                        DATETIME2(0) NOT NULL,
    TotalPreguntas                  SMALLINT NOT NULL,
    Aciertos                        SMALLINT NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (EvaluacionId, TotalPreguntas) REFERENCES dbo.Evaluacion(EvaluacionId, TotalPreguntas),
    CHECK (Aciertos BETWEEN 0 AND TotalPreguntas),
    CHECK (FechaFin >= FechaInicio)
);
GO
CREATE TABLE dbo.EventoUso (
    EventoUsoId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteId                    INT NOT NULL REFERENCES dbo.Estudiante(EstudianteId),
    RecursoAcademicoId              INT NULL REFERENCES dbo.RecursoAcademico(RecursoAcademicoId),
    Tipo                            VARCHAR(20) NOT NULL CHECK (Tipo IN ('ACCESO','CONSULTA_RECURSO','ESTUDIO','EJERCICIO','EVALUACION','SIMULACRO')),
    FechaEvento                     DATETIME2(0) NOT NULL,
    DuracionSegundos                INT NULL CHECK (DuracionSegundos >= 0),
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO
CREATE INDEX IX_EventoUso_EstudianteFecha ON dbo.EventoUso(EstudianteId, FechaEvento DESC);
CREATE INDEX IX_IntentoEvaluacion_EstudianteFecha ON dbo.IntentoEvaluacion(EstudianteId, FechaFin);
GO
-- 5. CONVERSACIONES, SATISFACCION E INCIDENCIAS

CREATE TABLE dbo.Conversacion (
    ConversacionId                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteId                    INT NOT NULL REFERENCES dbo.Estudiante(EstudianteId),
    ContactoId                      INT NOT NULL REFERENCES dbo.Contacto(ContactoId),
    Canal                           VARCHAR(10) NOT NULL CHECK (Canal IN ('EMAIL','WHATSAPP','PLATAFORMA')),
    Finalidad                       VARCHAR(15) NOT NULL CHECK (Finalidad IN ('ACADEMICA','COMERCIAL','REPORTES')),
    FechaInicio                     DATETIME2(0) NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    UNIQUE (ConversacionId, EstudianteId)
);
GO
-- El contenido de mensajes puede incluir emojis y texto Unicode del agente.
CREATE TABLE dbo.Mensaje (
    MensajeId                       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ConversacionId                  INT NOT NULL REFERENCES dbo.Conversacion(ConversacionId),
    RespuestaAMensajeId             INT NULL REFERENCES dbo.Mensaje(MensajeId),
    Direccion                       VARCHAR(10) NOT NULL CHECK (Direccion IN ('ENTRANTE','SALIENTE')),
    Emisor                          VARCHAR(12) NOT NULL CHECK (Emisor IN ('CONTACTO',N'DUEÑO','SOPORTE','SISTEMA','IA_ACADEMICO')),
    Contenido                       NVARCHAR(2000) NOT NULL,
    Estado                          VARCHAR(10) NOT NULL CHECK (Estado IN ('RECIBIDO','PROGRAMADO','ENVIADO','ENTREGADO','FALLIDO')),
    FechaProgramada                 DATETIME2(0) NULL,
    FechaEnvio                      DATETIME2(0) NULL,
    FechaEntrega                    DATETIME2(0) NULL,
    FechaRecepcion                  DATETIME2(0) NULL,
    IntencionExpresa                VARCHAR(15) NULL CHECK (IntencionExpresa IN ('CANCELAR','NO_RENOVAR','PEDIR_APOYO','NINGUNA')),
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    CHECK ((Direccion = 'ENTRANTE' AND Emisor = 'CONTACTO' AND Estado = 'RECIBIDO' AND FechaRecepcion IS NOT NULL) OR (Direccion = 'SALIENTE' AND Emisor <> 'CONTACTO' AND Estado <> 'RECIBIDO' AND FechaRecepcion IS NULL)),
    CHECK (Estado NOT IN ('ENVIADO','ENTREGADO') OR FechaEnvio IS NOT NULL),
    CHECK (Estado <> 'ENTREGADO' OR FechaEntrega IS NOT NULL),
    CHECK (FechaEntrega IS NULL OR (FechaEnvio IS NOT NULL AND FechaEntrega >= FechaEnvio))
);
GO
CREATE TABLE dbo.AspectoValoracion (
    AspectoValoracionId             INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Nombre                          VARCHAR(100) NOT NULL UNIQUE
);
GO
CREATE TABLE dbo.SolicitudValoracion (
    SolicitudValoracionId           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteId                    INT NOT NULL REFERENCES dbo.Estudiante(EstudianteId),
    AspectoValoracionId             INT NOT NULL REFERENCES dbo.AspectoValoracion(AspectoValoracionId),
    FechaEmision                    DATETIME2(0) NOT NULL,
    Motivo                          VARCHAR(300) NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO
-- El comentario es texto libre: se conservan emojis y caracteres Unicode.
CREATE TABLE dbo.Valoracion (
    ValoracionId                    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SolicitudValoracionId           INT NOT NULL UNIQUE REFERENCES dbo.SolicitudValoracion(SolicitudValoracionId),
    FechaRespuesta                  DATETIME2(0) NOT NULL,
    Estrellas                       TINYINT NOT NULL CHECK (Estrellas BETWEEN 1 AND 5),
    Comentario                      NVARCHAR(1000) NULL,
    Valida                          BIT NOT NULL DEFAULT 1,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO
CREATE TABLE dbo.CasoAtencion (
    CasoAtencionId                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteId                    INT NOT NULL REFERENCES dbo.Estudiante(EstudianteId),
    Tipo                            VARCHAR(10) NOT NULL CHECK (Tipo IN ('CONSULTA','INCIDENCIA')),
    Ambito                          VARCHAR(10) NOT NULL CHECK (Ambito IN ('SERVICIO','ACCESO','PAGO')),
    Descripcion                     NVARCHAR(1500) NOT NULL,
    FechaAperturaOriginal           DATETIME2(0) NOT NULL,
    FechaLimite                     DATETIME2(0) NULL,
    Estado                          VARCHAR(12) NOT NULL CHECK (Estado IN ('ABIERTA','EN_ATENCION','RESUELTA','REABIERTA')),
    ResponsableId                   INT NULL REFERENCES dbo.PersonalInterno(PersonalInternoId),
    FechaResolucionDefinitiva       DATETIME2(0) NULL,
    Resolucion                      NVARCHAR(1500) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    CHECK ((Estado = 'RESUELTA' AND FechaResolucionDefinitiva IS NOT NULL) OR (Estado <> 'RESUELTA' AND FechaResolucionDefinitiva IS NULL)),
    CHECK (FechaResolucionDefinitiva IS NULL OR FechaResolucionDefinitiva >= FechaAperturaOriginal)
);
GO
CREATE TABLE dbo.EventoCaso (
    EventoCasoId                    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CasoAtencionId                  INT NOT NULL REFERENCES dbo.CasoAtencion(CasoAtencionId),
    FechaEvento                     DATETIME2(0) NOT NULL,
    Estado                          VARCHAR(12) NOT NULL CHECK (Estado IN ('ABIERTA','EN_ATENCION','RESUELTA','REABIERTA')),
    Detalle                         NVARCHAR(1000) NOT NULL,
    ResponsableId                   INT NULL REFERENCES dbo.PersonalInterno(PersonalInternoId),
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO
CREATE INDEX IX_CasoAtencion_EstudianteEstado ON dbo.CasoAtencion(EstudianteId, Estado, FechaAperturaOriginal);
GO
-- 6. RIESGO Y ACCIONES DE ACOMPANAMIENTO

CREATE TABLE dbo.EvaluacionRiesgo (
    EvaluacionRiesgoId              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteId                    INT NOT NULL REFERENCES dbo.Estudiante(EstudianteId),
    FechaEvaluacion                 DATETIME2(0) NOT NULL,
    Estado                          VARCHAR(12) NOT NULL CHECK (Estado IN ('PENDIENTE','CLASIFICADA')),
    Nivel                           VARCHAR(5) NULL CHECK (Nivel IN ('BAJO','MEDIO','ALTO')),
    VersionReglas                   VARCHAR(20) NOT NULL DEFAULT 'INFORME_7.1',
    Motivo                          NVARCHAR(1000) NOT NULL,
    Origen                          VARCHAR(12) NOT NULL CHECK (Origen IN (N'DUEÑO','SISTEMA','IA_ACADEMICO','DEMO')),
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    UNIQUE (EvaluacionRiesgoId, EstudianteId),
    CHECK ((Estado = 'PENDIENTE' AND Nivel IS NULL) OR (Estado = 'CLASIFICADA' AND Nivel IS NOT NULL))
);
GO
CREATE TABLE dbo.SenalRiesgo (
    SenalRiesgoId                   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EvaluacionRiesgoId              INT NOT NULL REFERENCES dbo.EvaluacionRiesgo(EvaluacionRiesgoId),
    Codigo                          VARCHAR(30) NOT NULL CHECK (Codigo IN ('ACTIVIDAD_RECIENTE','INACTIVIDAD','INCIDENCIA_ABIERTA','INSATISFACCION','INTENCION_CANCELAR','DIFICULTAD_ACADEMICA')),
    Nivel                           VARCHAR(5) NOT NULL CHECK (Nivel IN ('BAJO','MEDIO','ALTO')),
    FechaObservacion                DATETIME2(0) NOT NULL,
    Detalle                         NVARCHAR(800) NOT NULL,
    EventoUsoId                     INT NULL REFERENCES dbo.EventoUso(EventoUsoId),
    CasoAtencionId                  INT NULL REFERENCES dbo.CasoAtencion(CasoAtencionId),
    ValoracionId                    INT NULL REFERENCES dbo.Valoracion(ValoracionId),
    MensajeId                       INT NULL REFERENCES dbo.Mensaje(MensajeId),
    DificultadAcademicaId           INT NULL REFERENCES dbo.DificultadAcademica(DificultadAcademicaId),
    CHECK ((CASE WHEN EventoUsoId IS NULL THEN 0 ELSE 1 END + CASE WHEN CasoAtencionId IS NULL THEN 0 ELSE 1 END + CASE WHEN ValoracionId IS NULL THEN 0 ELSE 1 END + CASE WHEN MensajeId IS NULL THEN 0 ELSE 1 END + CASE WHEN DificultadAcademicaId IS NULL THEN 0 ELSE 1 END) = 1)
);
GO
CREATE TABLE dbo.Intervencion (
    IntervencionId                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteId                    INT NOT NULL REFERENCES dbo.Estudiante(EstudianteId),
    EvaluacionRiesgoId              INT NULL,
    Tipo                            VARCHAR(25) NOT NULL CHECK (Tipo IN ('SEGUIMIENTO','RECORDATORIO','ACOMPANAMIENTO','RECOMENDACION_RUTA','DERIVACION_HUMANA')),
    Motivo                          NVARCHAR(1000) NOT NULL,
    Recomendacion                   NVARCHAR(1500) NOT NULL,
    FechaCreacion                   DATETIME2(0) NOT NULL,
    FechaProgramada                 DATETIME2(0) NULL,
    RequiereAprobacion              BIT NOT NULL DEFAULT 0,
    AprobadoPorId                   INT NULL REFERENCES dbo.PersonalInterno(PersonalInternoId),
    FechaAprobacion                 DATETIME2(0) NULL,
    Estado                          VARCHAR(15) NOT NULL CHECK (Estado IN ('PROPUESTA','PROGRAMADA','EN_CURSO','COMPLETADA','CANCELADA')),
    MensajeSeguimientoId            INT NULL REFERENCES dbo.Mensaje(MensajeId),
    FechaCompletada                 DATETIME2(0) NULL,
    Resultado                       NVARCHAR(1500) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (EvaluacionRiesgoId, EstudianteId) REFERENCES dbo.EvaluacionRiesgo(EvaluacionRiesgoId, EstudianteId),
    CHECK ((Estado = 'COMPLETADA' AND FechaCompletada IS NOT NULL) OR (Estado <> 'COMPLETADA' AND FechaCompletada IS NULL)),
    CHECK (FechaCompletada IS NULL OR FechaCompletada >= FechaCreacion),
    CHECK (RequiereAprobacion = 0 OR Estado NOT IN ('EN_CURSO','COMPLETADA') OR (AprobadoPorId IS NOT NULL AND FechaAprobacion IS NOT NULL))
);
GO
CREATE TABLE dbo.EventoIntervencion (
    EventoIntervencionId            INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IntervencionId                  INT NOT NULL REFERENCES dbo.Intervencion(IntervencionId),
    FechaEvento                     DATETIME2(0) NOT NULL,
    Estado                          VARCHAR(15) NOT NULL CHECK (Estado IN ('PROPUESTA','PROGRAMADA','EN_CURSO','COMPLETADA','CANCELADA')),
    Detalle                         NVARCHAR(1000) NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO
-- 7. CAMBIOS DE PLAN Y REFERIDOS

CREATE TABLE dbo.PropuestaCambioPlan (
    PropuestaCambioPlanId           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PeriodoActualId                 INT NOT NULL REFERENCES dbo.PeriodoServicio(PeriodoServicioId),
    ModalidadSugeridaId             INT NOT NULL REFERENCES dbo.ModalidadPlan(ModalidadPlanId),
    Necesidad                       NVARCHAR(1000) NOT NULL,
    SolicitadoPorCliente            BIT NOT NULL,
    FechaSolicitudCliente           DATETIME2(0) NULL,
    FechaPresentacion               DATETIME2(0) NOT NULL,
    Estado                          VARCHAR(10) NOT NULL CHECK (Estado IN ('PRESENTADA','ACEPTADA','RECHAZADA','APLICADA')),
    FechaRespuesta                  DATETIME2(0) NULL,
    Respuesta                       NVARCHAR(1000) NULL,
    PeriodoAplicadoId               INT NULL REFERENCES dbo.PeriodoServicio(PeriodoServicioId),
    FechaAplicacion                 DATETIME2(0) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    CHECK (Estado = 'PRESENTADA' OR FechaRespuesta IS NOT NULL),
    CHECK (FechaRespuesta IS NULL OR FechaRespuesta >= FechaPresentacion),
    CHECK (SolicitadoPorCliente = 0 OR FechaSolicitudCliente IS NOT NULL),
    CHECK ((Estado = 'APLICADA' AND PeriodoAplicadoId IS NOT NULL AND FechaAplicacion IS NOT NULL AND SolicitadoPorCliente = 1) OR (Estado <> 'APLICADA' AND PeriodoAplicadoId IS NULL AND FechaAplicacion IS NULL))
);
GO
CREATE TABLE dbo.InvitacionReferido (
    InvitacionReferidoId            INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteReferenteId           INT NOT NULL REFERENCES dbo.Estudiante(EstudianteId),
    FechaInvitacion                 DATETIME2(0) NOT NULL,
    MensajeId                       INT NULL REFERENCES dbo.Mensaje(MensajeId),
    Codigo                          VARCHAR(25) NOT NULL UNIQUE,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    UNIQUE (InvitacionReferidoId, EstudianteReferenteId)
);
GO
CREATE TABLE dbo.Referido (
    ReferidoId                      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    InvitacionReferidoId            INT NOT NULL,
    EstudianteReferenteId           INT NOT NULL,
    NombreReferido                  VARCHAR(160) NOT NULL,
    FechaRegistroReferido           DATETIME2(0) NOT NULL,
    EstudianteReferidoId            INT NULL REFERENCES dbo.Estudiante(EstudianteId),
    FechaSeleccionReferente         DATETIME2(0) NOT NULL,
    PrimerPagoId                    INT NULL REFERENCES dbo.Pago(PagoId),
    FechaFijacion                   DATETIME2(0) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (InvitacionReferidoId, EstudianteReferenteId) REFERENCES dbo.InvitacionReferido(InvitacionReferidoId, EstudianteReferenteId),
    CHECK (EstudianteReferidoId IS NULL OR EstudianteReferidoId <> EstudianteReferenteId),
    CHECK ((PrimerPagoId IS NULL AND FechaFijacion IS NULL) OR (PrimerPagoId IS NOT NULL AND FechaFijacion IS NOT NULL)),
    CHECK (FechaFijacion IS NULL OR FechaSeleccionReferente < FechaFijacion)
);
GO
CREATE UNIQUE INDEX UX_Referido_Estudiante ON dbo.Referido(EstudianteReferidoId) WHERE EstudianteReferidoId IS NOT NULL;
CREATE INDEX IX_EvaluacionRiesgo_EstudianteFecha ON dbo.EvaluacionRiesgo(EstudianteId, FechaEvaluacion DESC);
CREATE INDEX IX_Mensaje_Conversacion ON dbo.Mensaje(ConversacionId, FechaEnvio, FechaRecepcion);
GO

-- 8. HISTORIALES: tablas comunes con los valores anteriores

-- Versiones anteriores de dbo.Contacto.
CREATE TABLE dbo.ContactoHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ContactoId                      INT NOT NULL,
    NombreCompleto                  VARCHAR(160) NOT NULL,
    Correo                          VARCHAR(254) NULL,
    Telefono                        VARCHAR(25) NULL,
    CanalOrigen                     VARCHAR(25) NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_ContactoHistorial_Registro ON dbo.ContactoHistorial(ContactoId, FechaCambio);
GO

-- Versiones anteriores de dbo.Estudiante.
CREATE TABLE dbo.EstudianteHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EstudianteId                    INT NOT NULL,
    Codigo                          VARCHAR(20) NOT NULL,
    ContactoId                      INT NOT NULL,
    ApoderadoId                     INT NULL,
    Parentesco                      VARCHAR(30) NULL,
    UniversidadObjetivo             VARCHAR(150) NOT NULL,
    CarreraObjetivo                 VARCHAR(120) NULL,
    FechaExamen                     DATE NULL,
    DisponibilidadSemanalHoras      DECIMAL(5,2) NULL,
    EtapaActual                     VARCHAR(10) NOT NULL,
    PrioridadComercial              VARCHAR(5) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_EstudianteHistorial_Registro ON dbo.EstudianteHistorial(EstudianteId, FechaCambio);
GO

-- Versiones anteriores de dbo.AutorizacionContacto.
CREATE TABLE dbo.AutorizacionContactoHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    AutorizacionContactoId          INT NOT NULL,
    ContactoId                      INT NOT NULL,
    Canal                           VARCHAR(10) NOT NULL,
    Finalidad                       VARCHAR(15) NOT NULL,
    Autorizado                      BIT NOT NULL,
    FechaDecision                   DATETIME2(0) NOT NULL,
    Evidencia                       NVARCHAR(300) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_AutorizacionContactoHistorial_Registro ON dbo.AutorizacionContactoHistorial(AutorizacionContactoId, FechaCambio);
GO

-- Versiones anteriores de dbo.Suscripcion.
CREATE TABLE dbo.SuscripcionHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SuscripcionId                   INT NOT NULL,
    EstudianteId                    INT NOT NULL,
    ResponsableEconomicoId          INT NULL,
    FechaContratacion               DATETIME2(0) NOT NULL,
    RenovacionAutomatica            BIT NOT NULL,
    FechaDesactivacionRenovacion    DATETIME2(0) NULL,
    Estado                          VARCHAR(12) NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_SuscripcionHistorial_Registro ON dbo.SuscripcionHistorial(SuscripcionId, FechaCambio);
GO

-- Versiones anteriores de dbo.PeriodoServicio.
CREATE TABLE dbo.PeriodoServicioHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PeriodoServicioId               INT NOT NULL,
    SuscripcionId                   INT NOT NULL,
    ModalidadPlanId                 INT NOT NULL,
    PeriodoAnteriorId               INT NULL,
    Tipo                            VARCHAR(12) NOT NULL,
    Inicio                          DATETIME2(0) NOT NULL,
    Fin                             DATETIME2(0) NOT NULL,
    PrecioAcordadoPEN               DECIMAL(10,2) NOT NULL,
    BecaPorcentaje                  DECIMAL(5,2) NOT NULL,
    DescuentoPEN                    DECIMAL(10,2) NOT NULL,
    ImporteExigiblePEN              DECIMAL(10,2) NOT NULL,
    AutorizadoPorId                 INT NULL,
    FechaAutorizacion               DATETIME2(0) NULL,
    CondicionesAceptadas            VARCHAR(1000) NOT NULL,
    BeneficiosExtra                 VARCHAR(500) NULL,
    EstadoAcceso                    VARCHAR(15) NOT NULL,
    FechaHabilitacion               DATETIME2(0) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_PeriodoServicioHistorial_Registro ON dbo.PeriodoServicioHistorial(PeriodoServicioId, FechaCambio);
GO

-- Versiones anteriores de dbo.BajaServicio.
CREATE TABLE dbo.BajaServicioHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    BajaServicioId                  INT NOT NULL,
    PeriodoServicioId               INT NOT NULL,
    FechaBaja                       DATETIME2(0) NOT NULL,
    Tipo                            VARCHAR(12) NOT NULL,
    MotivoComunicado                NVARCHAR(400) NULL,
    FechaMotivo                     DATETIME2(0) NULL,
    ElegibleReactivacion            BIT NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_BajaServicioHistorial_Registro ON dbo.BajaServicioHistorial(BajaServicioId, FechaCambio);
GO

-- Versiones anteriores de dbo.RutaEstudio.
CREATE TABLE dbo.RutaEstudioHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    RutaEstudioId                   INT NOT NULL,
    EstudianteId                    INT NOT NULL,
    VersionNumero                   SMALLINT NOT NULL,
    Objetivo                        VARCHAR(350) NOT NULL,
    FechaExamenObjetivo             DATE NULL,
    Inicio                          DATETIME2(0) NOT NULL,
    FinPrevisto                     DATETIME2(0) NULL,
    Vigente                         BIT NOT NULL,
    ActualizadaPorId                INT NOT NULL,
    FechaActualizacion              DATETIME2(0) NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_RutaEstudioHistorial_Registro ON dbo.RutaEstudioHistorial(RutaEstudioId, FechaCambio);
GO

-- Versiones anteriores de dbo.ActividadRuta.
CREATE TABLE dbo.ActividadRutaHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ActividadRutaId                 INT NOT NULL,
    RutaEstudioId                   INT NOT NULL,
    RecursoAcademicoId              INT NOT NULL,
    Orden                           SMALLINT NOT NULL,
    FechaPlanificada                DATETIME2(0) NOT NULL,
    FechaLimite                     DATETIME2(0) NOT NULL,
    Estado                          VARCHAR(12) NOT NULL,
    FechaCompletada                 DATETIME2(0) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_ActividadRutaHistorial_Registro ON dbo.ActividadRutaHistorial(ActividadRutaId, FechaCambio);
GO

-- Versiones anteriores de dbo.DificultadAcademica.
CREATE TABLE dbo.DificultadAcademicaHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DificultadAcademicaId           INT NOT NULL,
    EstudianteId                    INT NOT NULL,
    TemaId                          INT NULL,
    Descripcion                     NVARCHAR(600) NOT NULL,
    Origen                          VARCHAR(15) NOT NULL,
    FechaIdentificacion             DATETIME2(0) NOT NULL,
    Estado                          VARCHAR(15) NOT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_DificultadAcademicaHistorial_Registro ON dbo.DificultadAcademicaHistorial(DificultadAcademicaId, FechaCambio);
GO

-- Versiones anteriores de dbo.RevisionRuta.
CREATE TABLE dbo.RevisionRutaHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    RevisionRutaId                  INT NOT NULL,
    RutaEstudioId                   INT NOT NULL,
    Motivo                          VARCHAR(20) NOT NULL,
    FechaIdentificacion             DATETIME2(0) NOT NULL,
    Recomendacion                   NVARCHAR(1000) NULL,
    Estado                          VARCHAR(10) NOT NULL,
    RevisadaPorId                   INT NULL,
    FechaRevision                   DATETIME2(0) NULL,
    Resultado                       NVARCHAR(1000) NULL,
    RutaResultanteId                INT NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_RevisionRutaHistorial_Registro ON dbo.RevisionRutaHistorial(RevisionRutaId, FechaCambio);
GO

-- Versiones anteriores de dbo.CasoAtencion.
CREATE TABLE dbo.CasoAtencionHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CasoAtencionId                  INT NOT NULL,
    EstudianteId                    INT NOT NULL,
    Tipo                            VARCHAR(10) NOT NULL,
    Ambito                          VARCHAR(10) NOT NULL,
    Descripcion                     NVARCHAR(1500) NOT NULL,
    FechaAperturaOriginal           DATETIME2(0) NOT NULL,
    FechaLimite                     DATETIME2(0) NULL,
    Estado                          VARCHAR(12) NOT NULL,
    ResponsableId                   INT NULL,
    FechaResolucionDefinitiva       DATETIME2(0) NULL,
    Resolucion                      NVARCHAR(1500) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_CasoAtencionHistorial_Registro ON dbo.CasoAtencionHistorial(CasoAtencionId, FechaCambio);
GO

-- Versiones anteriores de dbo.Intervencion.
CREATE TABLE dbo.IntervencionHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IntervencionId                  INT NOT NULL,
    EstudianteId                    INT NOT NULL,
    EvaluacionRiesgoId              INT NULL,
    Tipo                            VARCHAR(25) NOT NULL,
    Motivo                          NVARCHAR(1000) NOT NULL,
    Recomendacion                   NVARCHAR(1500) NOT NULL,
    FechaCreacion                   DATETIME2(0) NOT NULL,
    FechaProgramada                 DATETIME2(0) NULL,
    RequiereAprobacion              BIT NOT NULL,
    AprobadoPorId                   INT NULL,
    FechaAprobacion                 DATETIME2(0) NULL,
    Estado                          VARCHAR(15) NOT NULL,
    MensajeSeguimientoId            INT NULL,
    FechaCompletada                 DATETIME2(0) NULL,
    Resultado                       NVARCHAR(1500) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_IntervencionHistorial_Registro ON dbo.IntervencionHistorial(IntervencionId, FechaCambio);
GO

-- Versiones anteriores de dbo.PropuestaCambioPlan.
CREATE TABLE dbo.PropuestaCambioPlanHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PropuestaCambioPlanId           INT NOT NULL,
    PeriodoActualId                 INT NOT NULL,
    ModalidadSugeridaId             INT NOT NULL,
    Necesidad                       NVARCHAR(1000) NOT NULL,
    SolicitadoPorCliente            BIT NOT NULL,
    FechaSolicitudCliente           DATETIME2(0) NULL,
    FechaPresentacion               DATETIME2(0) NOT NULL,
    Estado                          VARCHAR(10) NOT NULL,
    FechaRespuesta                  DATETIME2(0) NULL,
    Respuesta                       NVARCHAR(1000) NULL,
    PeriodoAplicadoId               INT NULL,
    FechaAplicacion                 DATETIME2(0) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_PropuestaCambioPlanHistorial_Registro ON dbo.PropuestaCambioPlanHistorial(PropuestaCambioPlanId, FechaCambio);
GO

-- Versiones anteriores de dbo.Referido.
CREATE TABLE dbo.ReferidoHistorial (
    HistorialId                     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ReferidoId                      INT NOT NULL,
    InvitacionReferidoId            INT NOT NULL,
    EstudianteReferenteId           INT NOT NULL,
    NombreReferido                  VARCHAR(160) NOT NULL,
    FechaRegistroReferido           DATETIME2(0) NOT NULL,
    EstudianteReferidoId            INT NULL,
    FechaSeleccionReferente         DATETIME2(0) NOT NULL,
    PrimerPagoId                    INT NULL,
    FechaFijacion                   DATETIME2(0) NULL,
    FechaRegistro                   DATETIME2(0) NOT NULL,
    FechaCambio                     DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Operacion                       CHAR(1) NOT NULL CHECK (Operacion IN ('U','D'))
);
GO
CREATE INDEX IX_ReferidoHistorial_Registro ON dbo.ReferidoHistorial(ReferidoId, FechaCambio);
GO

-- 9. TRIGGERS DE HISTORIAL: una misma idea para cada tabla.
-- En un trigger, "deleted" contiene las filas como estaban ANTES del cambio.
-- "inserted" contiene las filas como quedan DESPUES de un UPDATE.
-- En un DELETE, inserted esta vacia. Por eso el LEFT JOIN permite distinguir U/D.
-- INSERT ... SELECT copia todas las filas afectadas, no solamente una.
-- SET NOCOUNT ON solo oculta el mensaje "N filas afectadas" de las copias.

CREATE TRIGGER dbo.TR_Contacto_GuardarHistorial
ON dbo.Contacto
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ContactoHistorial (
        ContactoId, NombreCompleto, Correo, Telefono, CanalOrigen, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.ContactoId, anterior.NombreCompleto, anterior.Correo, anterior.Telefono, anterior.CanalOrigen, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.ContactoId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.ContactoId = anterior.ContactoId;
END;
GO

CREATE TRIGGER dbo.TR_Estudiante_GuardarHistorial
ON dbo.Estudiante
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.EstudianteHistorial (
        EstudianteId, Codigo, ContactoId, ApoderadoId, Parentesco, UniversidadObjetivo, CarreraObjetivo, FechaExamen, DisponibilidadSemanalHoras, EtapaActual, PrioridadComercial, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.EstudianteId, anterior.Codigo, anterior.ContactoId, anterior.ApoderadoId, anterior.Parentesco, anterior.UniversidadObjetivo, anterior.CarreraObjetivo, anterior.FechaExamen, anterior.DisponibilidadSemanalHoras, anterior.EtapaActual, anterior.PrioridadComercial, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.EstudianteId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.EstudianteId = anterior.EstudianteId;
END;
GO

CREATE TRIGGER dbo.TR_AutorizacionContacto_GuardarHistorial
ON dbo.AutorizacionContacto
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.AutorizacionContactoHistorial (
        AutorizacionContactoId, ContactoId, Canal, Finalidad, Autorizado, FechaDecision, Evidencia,
        FechaCambio, Operacion
    )
    SELECT
        anterior.AutorizacionContactoId, anterior.ContactoId, anterior.Canal, anterior.Finalidad, anterior.Autorizado, anterior.FechaDecision, anterior.Evidencia,
        GETDATE(),
        CASE WHEN actual.AutorizacionContactoId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.AutorizacionContactoId = anterior.AutorizacionContactoId;
END;
GO

CREATE TRIGGER dbo.TR_Suscripcion_GuardarHistorial
ON dbo.Suscripcion
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.SuscripcionHistorial (
        SuscripcionId, EstudianteId, ResponsableEconomicoId, FechaContratacion, RenovacionAutomatica, FechaDesactivacionRenovacion, Estado, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.SuscripcionId, anterior.EstudianteId, anterior.ResponsableEconomicoId, anterior.FechaContratacion, anterior.RenovacionAutomatica, anterior.FechaDesactivacionRenovacion, anterior.Estado, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.SuscripcionId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.SuscripcionId = anterior.SuscripcionId;
END;
GO

CREATE TRIGGER dbo.TR_PeriodoServicio_GuardarHistorial
ON dbo.PeriodoServicio
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.PeriodoServicioHistorial (
        PeriodoServicioId, SuscripcionId, ModalidadPlanId, PeriodoAnteriorId, Tipo, Inicio, Fin, PrecioAcordadoPEN, BecaPorcentaje, DescuentoPEN, ImporteExigiblePEN, AutorizadoPorId, FechaAutorizacion, CondicionesAceptadas, BeneficiosExtra, EstadoAcceso, FechaHabilitacion, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.PeriodoServicioId, anterior.SuscripcionId, anterior.ModalidadPlanId, anterior.PeriodoAnteriorId, anterior.Tipo, anterior.Inicio, anterior.Fin, anterior.PrecioAcordadoPEN, anterior.BecaPorcentaje, anterior.DescuentoPEN, anterior.ImporteExigiblePEN, anterior.AutorizadoPorId, anterior.FechaAutorizacion, anterior.CondicionesAceptadas, anterior.BeneficiosExtra, anterior.EstadoAcceso, anterior.FechaHabilitacion, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.PeriodoServicioId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.PeriodoServicioId = anterior.PeriodoServicioId;
END;
GO

CREATE TRIGGER dbo.TR_BajaServicio_GuardarHistorial
ON dbo.BajaServicio
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.BajaServicioHistorial (
        BajaServicioId, PeriodoServicioId, FechaBaja, Tipo, MotivoComunicado, FechaMotivo, ElegibleReactivacion, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.BajaServicioId, anterior.PeriodoServicioId, anterior.FechaBaja, anterior.Tipo, anterior.MotivoComunicado, anterior.FechaMotivo, anterior.ElegibleReactivacion, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.BajaServicioId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.BajaServicioId = anterior.BajaServicioId;
END;
GO

CREATE TRIGGER dbo.TR_RutaEstudio_GuardarHistorial
ON dbo.RutaEstudio
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.RutaEstudioHistorial (
        RutaEstudioId, EstudianteId, VersionNumero, Objetivo, FechaExamenObjetivo, Inicio, FinPrevisto, Vigente, ActualizadaPorId, FechaActualizacion, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.RutaEstudioId, anterior.EstudianteId, anterior.VersionNumero, anterior.Objetivo, anterior.FechaExamenObjetivo, anterior.Inicio, anterior.FinPrevisto, anterior.Vigente, anterior.ActualizadaPorId, anterior.FechaActualizacion, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.RutaEstudioId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.RutaEstudioId = anterior.RutaEstudioId;
END;
GO

CREATE TRIGGER dbo.TR_ActividadRuta_GuardarHistorial
ON dbo.ActividadRuta
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ActividadRutaHistorial (
        ActividadRutaId, RutaEstudioId, RecursoAcademicoId, Orden, FechaPlanificada, FechaLimite, Estado, FechaCompletada, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.ActividadRutaId, anterior.RutaEstudioId, anterior.RecursoAcademicoId, anterior.Orden, anterior.FechaPlanificada, anterior.FechaLimite, anterior.Estado, anterior.FechaCompletada, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.ActividadRutaId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.ActividadRutaId = anterior.ActividadRutaId;
END;
GO

CREATE TRIGGER dbo.TR_DificultadAcademica_GuardarHistorial
ON dbo.DificultadAcademica
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.DificultadAcademicaHistorial (
        DificultadAcademicaId, EstudianteId, TemaId, Descripcion, Origen, FechaIdentificacion, Estado, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.DificultadAcademicaId, anterior.EstudianteId, anterior.TemaId, anterior.Descripcion, anterior.Origen, anterior.FechaIdentificacion, anterior.Estado, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.DificultadAcademicaId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.DificultadAcademicaId = anterior.DificultadAcademicaId;
END;
GO

CREATE TRIGGER dbo.TR_RevisionRuta_GuardarHistorial
ON dbo.RevisionRuta
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.RevisionRutaHistorial (
        RevisionRutaId, RutaEstudioId, Motivo, FechaIdentificacion, Recomendacion, Estado, RevisadaPorId, FechaRevision, Resultado, RutaResultanteId, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.RevisionRutaId, anterior.RutaEstudioId, anterior.Motivo, anterior.FechaIdentificacion, anterior.Recomendacion, anterior.Estado, anterior.RevisadaPorId, anterior.FechaRevision, anterior.Resultado, anterior.RutaResultanteId, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.RevisionRutaId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.RevisionRutaId = anterior.RevisionRutaId;
END;
GO

CREATE TRIGGER dbo.TR_CasoAtencion_GuardarHistorial
ON dbo.CasoAtencion
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.CasoAtencionHistorial (
        CasoAtencionId, EstudianteId, Tipo, Ambito, Descripcion, FechaAperturaOriginal, FechaLimite, Estado, ResponsableId, FechaResolucionDefinitiva, Resolucion, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.CasoAtencionId, anterior.EstudianteId, anterior.Tipo, anterior.Ambito, anterior.Descripcion, anterior.FechaAperturaOriginal, anterior.FechaLimite, anterior.Estado, anterior.ResponsableId, anterior.FechaResolucionDefinitiva, anterior.Resolucion, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.CasoAtencionId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.CasoAtencionId = anterior.CasoAtencionId;
END;
GO

CREATE TRIGGER dbo.TR_Intervencion_GuardarHistorial
ON dbo.Intervencion
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.IntervencionHistorial (
        IntervencionId, EstudianteId, EvaluacionRiesgoId, Tipo, Motivo, Recomendacion, FechaCreacion, FechaProgramada, RequiereAprobacion, AprobadoPorId, FechaAprobacion, Estado, MensajeSeguimientoId, FechaCompletada, Resultado, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.IntervencionId, anterior.EstudianteId, anterior.EvaluacionRiesgoId, anterior.Tipo, anterior.Motivo, anterior.Recomendacion, anterior.FechaCreacion, anterior.FechaProgramada, anterior.RequiereAprobacion, anterior.AprobadoPorId, anterior.FechaAprobacion, anterior.Estado, anterior.MensajeSeguimientoId, anterior.FechaCompletada, anterior.Resultado, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.IntervencionId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.IntervencionId = anterior.IntervencionId;
END;
GO

CREATE TRIGGER dbo.TR_PropuestaCambioPlan_GuardarHistorial
ON dbo.PropuestaCambioPlan
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.PropuestaCambioPlanHistorial (
        PropuestaCambioPlanId, PeriodoActualId, ModalidadSugeridaId, Necesidad, SolicitadoPorCliente, FechaSolicitudCliente, FechaPresentacion, Estado, FechaRespuesta, Respuesta, PeriodoAplicadoId, FechaAplicacion, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.PropuestaCambioPlanId, anterior.PeriodoActualId, anterior.ModalidadSugeridaId, anterior.Necesidad, anterior.SolicitadoPorCliente, anterior.FechaSolicitudCliente, anterior.FechaPresentacion, anterior.Estado, anterior.FechaRespuesta, anterior.Respuesta, anterior.PeriodoAplicadoId, anterior.FechaAplicacion, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.PropuestaCambioPlanId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.PropuestaCambioPlanId = anterior.PropuestaCambioPlanId;
END;
GO

CREATE TRIGGER dbo.TR_Referido_GuardarHistorial
ON dbo.Referido
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ReferidoHistorial (
        ReferidoId, InvitacionReferidoId, EstudianteReferenteId, NombreReferido, FechaRegistroReferido, EstudianteReferidoId, FechaSeleccionReferente, PrimerPagoId, FechaFijacion, FechaRegistro,
        FechaCambio, Operacion
    )
    SELECT
        anterior.ReferidoId, anterior.InvitacionReferidoId, anterior.EstudianteReferenteId, anterior.NombreReferido, anterior.FechaRegistroReferido, anterior.EstudianteReferidoId, anterior.FechaSeleccionReferente, anterior.PrimerPagoId, anterior.FechaFijacion, anterior.FechaRegistro,
        GETDATE(),
        CASE WHEN actual.ReferidoId IS NULL THEN 'D' ELSE 'U' END
    FROM deleted AS anterior
    LEFT JOIN inserted AS actual
        ON actual.ReferidoId = anterior.ReferidoId;
END;
GO

-- 10. TRIGGERS DE VALIDACION: reglas entre tablas

CREATE TRIGGER dbo.TR_PeriodoServicio_Integridad ON dbo.PeriodoServicio
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Un estudiante no debe pagar dos periodos superpuestos en la misma suscripcion.
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.PeriodoServicio p
               ON p.SuscripcionId=i.SuscripcionId AND p.PeriodoServicioId<>i.PeriodoServicioId
               WHERE i.EstadoAcceso<>'ANULADO' AND p.EstadoAcceso<>'ANULADO'
                 AND i.Inicio<p.Fin AND p.Inicio<i.Fin)
        THROW 51010, N'Los periodos de una suscripcion no pueden superponerse.', 1;
    -- Una renovacion continua el periodo anterior de la misma suscripcion.
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.PeriodoServicio p ON p.PeriodoServicioId=i.PeriodoAnteriorId
               WHERE p.SuscripcionId<>i.SuscripcionId OR p.Fin<>i.Inicio OR i.Tipo<>'RENOVACION')
        THROW 51011, N'La renovacion debe enlazar el periodo anterior de la misma suscripcion sin interrupcion.', 1;
    -- El enlace al periodo anterior no puede faltar si es una renovacion.
    IF EXISTS (SELECT 1 FROM inserted WHERE Tipo='RENOVACION' AND PeriodoAnteriorId IS NULL)
        THROW 51012, N'Una renovacion necesita periodo anterior.', 1;
    -- Solo el dueno activo puede autorizar beneficios economicos.
    IF EXISTS (SELECT 1 FROM inserted i LEFT JOIN dbo.PersonalInterno u ON u.PersonalInternoId=i.AutorizadoPorId
               WHERE (i.BecaPorcentaje>0 OR i.DescuentoPEN>0) AND (u.Rol<>N'DUEÑO' OR u.Activo=0))
        THROW 51013, N'La beca o descuento exige autorizacion del dueno activo.', 1;
    -- El acceso necesita un cobro confirmado o una beca completa autorizada.
    IF EXISTS (SELECT 1 FROM inserted i WHERE i.EstadoAcceso IN ('HABILITADO','CON_INCIDENCIA')
               AND i.BecaPorcentaje<100 AND NOT EXISTS
               (SELECT 1 FROM dbo.Pago p WHERE p.PeriodoServicioId=i.PeriodoServicioId
                AND p.Tipo='COBRO' AND p.Estado='CONFIRMADO' AND p.ImportePEN=i.ImporteExigiblePEN
                AND p.FechaConfirmacion<=i.FechaHabilitacion))
        THROW 51014, N'Para habilitar un periodo se necesita pago confirmado del importe exigible o beca completa autorizada.', 1;
END;
GO
CREATE TRIGGER dbo.TR_Pago_Integridad ON dbo.Pago
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- Los pagos confirmados se corrigen con otra operacion, no sobrescribiendolos.
    IF EXISTS (SELECT 1 FROM deleted WHERE Estado='CONFIRMADO')
        THROW 51020, N'Una operacion confirmada es inmutable: registre una reversion, disputa o reembolso separado.', 1;
    -- El monto cobrado debe coincidir con el contrato; beca completa no paga.
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.PeriodoServicio s ON s.PeriodoServicioId=i.PeriodoServicioId
               WHERE i.Tipo='COBRO' AND i.Estado='CONFIRMADO' AND (s.BecaPorcentaje=100 OR i.ImportePEN<>s.ImporteExigiblePEN))
        THROW 51021, N'El cobro confirmado debe coincidir con el importe exigible; una beca completa no genera pago.', 1;
    -- Un reembolso/reversion debe apuntar al cobro original del mismo periodo.
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.Pago p ON p.PagoId=i.PagoOriginalId
               WHERE p.Tipo<>'COBRO' OR p.Estado<>'CONFIRMADO' OR p.PeriodoServicioId<>i.PeriodoServicioId)
        THROW 51022, N'La operacion correctiva debe referenciar el cobro confirmado del mismo periodo.', 1;
END;
GO
CREATE TRIGGER dbo.TR_BajaServicio_Fecha ON dbo.BajaServicio
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- La fecha de baja coincide con el fin del periodo contratado.
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.PeriodoServicio p ON p.PeriodoServicioId=i.PeriodoServicioId
               WHERE i.FechaBaja<>p.Fin)
        THROW 51030, N'La baja debe tener la misma fecha que la finalizacion del periodo contratado.', 1;
END;
GO
CREATE TRIGGER dbo.TR_Valoracion_Fecha ON dbo.Valoracion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- La respuesta debe ser posterior o igual a la solicitud de valoracion.
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.SolicitudValoracion s ON s.SolicitudValoracionId=i.SolicitudValoracionId
               WHERE i.FechaRespuesta<s.FechaEmision)
        THROW 51031, N'Una valoracion no puede preceder a su solicitud.', 1;
END;
GO
CREATE TRIGGER dbo.TR_RutaEstudio_Dueno ON dbo.RutaEstudio
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- El dueno es quien publica los cambios de la ruta academica.
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.PersonalInterno p ON p.PersonalInternoId=i.ActualizadaPorId WHERE p.Rol<>N'DUEÑO' OR p.Activo=0)
        THROW 51032, N'La actualizacion de rutas corresponde al dueno activo.', 1;
END;
GO
CREATE TRIGGER dbo.TR_RevisionRuta_Integridad ON dbo.RevisionRuta
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- La revision tambien debe ser validada por el dueno.
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.PersonalInterno p ON p.PersonalInternoId=i.RevisadaPorId WHERE p.Rol<>N'DUEÑO' OR p.Activo=0)
        THROW 51033, N'La revision de la ruta corresponde al dueno activo.', 1;
    -- Una revision no puede terminar enlazada con la ruta de otro alumno.
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.RutaEstudio a ON a.RutaEstudioId=i.RutaEstudioId
               JOIN dbo.RutaEstudio b ON b.RutaEstudioId=i.RutaResultanteId WHERE a.EstudianteId<>b.EstudianteId)
        THROW 51034, N'La ruta resultante debe pertenecer al mismo estudiante.', 1;
END;
GO
CREATE TRIGGER dbo.TR_Referido_Atribucion ON dbo.Referido
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- Una atribucion fijada por pago ya no se cambia ni se elimina.
    IF EXISTS (SELECT 1 FROM deleted WHERE PrimerPagoId IS NOT NULL)
        THROW 51040, N'La atribucion fijada por el primer pago no se puede modificar ni borrar.', 1;
    -- Se comprueban el estudiante, el primer pago y las fechas de atribucion.
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.Pago p ON p.PagoId=i.PrimerPagoId
               JOIN dbo.PeriodoServicio ps ON ps.PeriodoServicioId=p.PeriodoServicioId
               JOIN dbo.Suscripcion s ON s.SuscripcionId=ps.SuscripcionId
               WHERE p.Tipo<>'COBRO' OR p.Estado<>'CONFIRMADO' OR s.EstudianteId<>i.EstudianteReferidoId
                  OR i.EstudianteReferidoId IS NULL OR i.FechaFijacion<>p.FechaConfirmacion
                  OR i.FechaSeleccionReferente>=p.FechaConfirmacion
                  OR EXISTS (SELECT 1 FROM dbo.Pago previo JOIN dbo.PeriodoServicio pp ON pp.PeriodoServicioId=previo.PeriodoServicioId
                             JOIN dbo.Suscripcion sp ON sp.SuscripcionId=pp.SuscripcionId
                             WHERE sp.EstudianteId=s.EstudianteId AND previo.Tipo='COBRO' AND previo.Estado='CONFIRMADO'
                               AND (previo.FechaConfirmacion<p.FechaConfirmacion OR
                                    (previo.FechaConfirmacion=p.FechaConfirmacion AND previo.PagoId<p.PagoId))))
        THROW 51041, N'El referido debe fijarse al primer pago confirmado del estudiante y seleccionarse antes de ese pago.', 1;
END;
GO
CREATE TRIGGER dbo.TR_Intervencion_Mensaje ON dbo.Intervencion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- El seguimiento debe usar un mensaje saliente del mismo estudiante.
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.Mensaje m ON m.MensajeId=i.MensajeSeguimientoId
               JOIN dbo.Conversacion c ON c.ConversacionId=m.ConversacionId
               WHERE c.EstudianteId<>i.EstudianteId OR m.Direccion<>'SALIENTE')
        THROW 51042, N'El mensaje de seguimiento debe ser saliente y del mismo estudiante.', 1;
END;
GO
CREATE TRIGGER dbo.TR_PropuestaCambioPlan_Aplicacion ON dbo.PropuestaCambioPlan
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Aplicar un cambio requiere el plan aceptado y el mismo estudiante.
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.PeriodoServicio actual ON actual.PeriodoServicioId=i.PeriodoActualId
               JOIN dbo.Suscripcion sa ON sa.SuscripcionId=actual.SuscripcionId
               JOIN dbo.PeriodoServicio nuevo ON nuevo.PeriodoServicioId=i.PeriodoAplicadoId
               JOIN dbo.Suscripcion sn ON sn.SuscripcionId=nuevo.SuscripcionId
               WHERE sa.EstudianteId<>sn.EstudianteId OR nuevo.ModalidadPlanId<>i.ModalidadSugeridaId)
        THROW 51043, N'El periodo aplicado debe ser del mismo estudiante y de la modalidad aceptada.', 1;
END;
GO
-- La senal debe coincidir con el tipo de evidencia y el alumno evaluado.
-- Cada bloque mira UN tipo de evidencia, para que sea facil leerlo y ampliarlo.
CREATE TRIGGER dbo.TR_SenalRiesgo_Evidencia
ON dbo.SenalRiesgo
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- La observacion debe ser conocida al realizar la evaluacion.
    IF EXISTS (
        SELECT 1 FROM inserted AS senal
        JOIN dbo.EvaluacionRiesgo AS riesgo ON riesgo.EvaluacionRiesgoId = senal.EvaluacionRiesgoId
        WHERE senal.FechaObservacion > riesgo.FechaEvaluacion
    )
        THROW 51044, N'La senal no puede observarse despues de la evaluacion.', 1;

    -- El codigo de la senal debe usar el campo de evidencia correspondiente.
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE (Codigo IN ('ACTIVIDAD_RECIENTE','INACTIVIDAD') AND EventoUsoId IS NULL)
           OR (Codigo = 'INCIDENCIA_ABIERTA' AND CasoAtencionId IS NULL)
           OR (Codigo = 'INSATISFACCION' AND ValoracionId IS NULL)
           OR (Codigo = 'INTENCION_CANCELAR' AND MensajeId IS NULL)
           OR (Codigo = 'DIFICULTAD_ACADEMICA' AND DificultadAcademicaId IS NULL)
    )
        THROW 51045, N'El tipo de senal no coincide con su evidencia.', 1;

    -- Actividad: mismo estudiante y evento anterior o igual a la evaluacion.
    IF EXISTS (
        SELECT 1 FROM inserted AS senal
        JOIN dbo.EvaluacionRiesgo AS riesgo ON riesgo.EvaluacionRiesgoId = senal.EvaluacionRiesgoId
        JOIN dbo.EventoUso AS uso ON uso.EventoUsoId = senal.EventoUsoId
        WHERE uso.EstudianteId <> riesgo.EstudianteId
           OR uso.FechaEvento > riesgo.FechaEvaluacion
    )
        THROW 51046, N'El evento de uso no corresponde al estudiante o a la fecha evaluada.', 1;

    -- Incidencias: solo servicio/acceso; las de pago se atienden en PAYERS.
    IF EXISTS (
        SELECT 1 FROM inserted AS senal
        JOIN dbo.EvaluacionRiesgo AS riesgo ON riesgo.EvaluacionRiesgoId = senal.EvaluacionRiesgoId
        JOIN dbo.CasoAtencion AS caso ON caso.CasoAtencionId = senal.CasoAtencionId
        WHERE caso.EstudianteId <> riesgo.EstudianteId
           OR caso.FechaAperturaOriginal > riesgo.FechaEvaluacion
           OR caso.Tipo <> 'INCIDENCIA' OR caso.Ambito = 'PAGO'
    )
        THROW 51047, N'La incidencia no corresponde al estudiante, a la fecha o al ambito de servicio.', 1;

    -- Valoraciones: deben ser validas y de 1 o 2 estrellas; el agente ademas
    -- debe confirmar que evidencian insatisfaccion al interpretar el contexto.
    IF EXISTS (
        SELECT 1 FROM inserted AS senal
        JOIN dbo.EvaluacionRiesgo AS riesgo ON riesgo.EvaluacionRiesgoId = senal.EvaluacionRiesgoId
        JOIN dbo.Valoracion AS valor ON valor.ValoracionId = senal.ValoracionId
        JOIN dbo.SolicitudValoracion AS solicitud ON solicitud.SolicitudValoracionId = valor.SolicitudValoracionId
        WHERE solicitud.EstudianteId <> riesgo.EstudianteId
           OR valor.FechaRespuesta > riesgo.FechaEvaluacion
           OR valor.Valida = 0 OR valor.Estrellas > 2
    )
        THROW 51048, N'La valoracion no es evidencia valida de insatisfaccion para esta evaluacion.', 1;

    -- Cancelacion: se necesita un mensaje entrante con intencion expresa.
    IF EXISTS (
        SELECT 1 FROM inserted AS senal
        JOIN dbo.EvaluacionRiesgo AS riesgo ON riesgo.EvaluacionRiesgoId = senal.EvaluacionRiesgoId
        JOIN dbo.Mensaje AS mensaje ON mensaje.MensajeId = senal.MensajeId
        JOIN dbo.Conversacion AS conversacion ON conversacion.ConversacionId = mensaje.ConversacionId
        WHERE conversacion.EstudianteId <> riesgo.EstudianteId
           OR mensaje.FechaRecepcion > riesgo.FechaEvaluacion
           OR mensaje.Direccion <> 'ENTRANTE'
           OR mensaje.IntencionExpresa IS NULL
           OR mensaje.IntencionExpresa NOT IN ('CANCELAR','NO_RENOVAR')
    )
        THROW 51049, N'La intencion de cancelar/no renovar necesita un mensaje expreso del estudiante.', 1;

    -- Dificultades academicas: mismo estudiante y fecha ya conocida.
    IF EXISTS (
        SELECT 1 FROM inserted AS senal
        JOIN dbo.EvaluacionRiesgo AS riesgo ON riesgo.EvaluacionRiesgoId = senal.EvaluacionRiesgoId
        JOIN dbo.DificultadAcademica AS dificultad ON dificultad.DificultadAcademicaId = senal.DificultadAcademicaId
        WHERE dificultad.EstudianteId <> riesgo.EstudianteId
           OR dificultad.FechaIdentificacion > riesgo.FechaEvaluacion
    )
        THROW 51050, N'La dificultad academica no corresponde al estudiante o a la fecha evaluada.', 1;
END;
GO

PRINT N'Base y tablas creadas. Ejecute ahora 02_poblar_customers.sql actualizado.';
GO

/* COMO CONSULTAR UN HISTORIAL:

-- Datos actuales del estudiante:
SELECT EstudianteId, Codigo, CarreraObjetivo, FechaExamen
FROM dbo.Estudiante
WHERE Codigo = 'C001';

-- Versiones anteriores, mostrando primero el ultimo cambio:
SELECT HistorialId, EstudianteId, Codigo, CarreraObjetivo, FechaExamen,
       FechaCambio, Operacion
FROM dbo.EstudianteHistorial
WHERE Codigo = 'C001'
ORDER BY HistorialId DESC;

-- No se necesita FOR SYSTEM_TIME: basta SELECT sobre la tabla de historial.
*/
