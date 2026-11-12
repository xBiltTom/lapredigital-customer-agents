/* LaPreDigital | Pruebas exploratorias de la primera version OLTP
Ejecutar despues de 01 y 02 en la misma instancia. No envia mensajes reales.
Cada caso ejecuta BEGIN TRANSACTION y ROLLBACK: no deja cambios de negocio.
Los IDENTITY pueden avanzar aunque haya ROLLBACK; los huecos no son errores.
OK verifica una proteccion existente. HALLAZGO reproduce una regla no protegida.
Los hallazgos son trabajo pendiente, no aprobacion funcional del modelo.
*/
USE LaPreDigital_Customers;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 THROW 51901,'Ejecutar sin transaccion previa.',1;
DECLARE @Pruebas TABLE(Id INT IDENTITY, Caso NVARCHAR(150), Comando NVARCHAR(MAX), ErrorEsperado INT, EsHallazgo BIT);
DECLARE @Resultados TABLE(Id INT,Caso NVARCHAR(150),Resultado VARCHAR(20),ErrorObtenido INT,Detalle NVARCHAR(2048));
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Historial UPDATE de varias filas',N'DECLARE @Antes INT=(SELECT COUNT(*) FROM dbo.ContactoHistorial);
UPDATE dbo.Contacto SET NombreCompleto=NombreCompleto+'' prueba'' WHERE ContactoId IN (SELECT TOP(2) ContactoId FROM dbo.Contacto ORDER BY ContactoId);
IF (SELECT COUNT(*) FROM dbo.ContactoHistorial)<>@Antes+2 THROW 51900, ''No se guardaron ambas filas anteriores.'',1;',0,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Historial DELETE de varias filas',N'DECLARE @Antes INT=(SELECT COUNT(*) FROM dbo.ContactoHistorial WHERE Operacion=''D'');
INSERT dbo.Contacto(NombreCompleto,CanalOrigen) VALUES (''Prueba borrar 1'',''DEMO''),(''Prueba borrar 2'',''DEMO'');
DELETE dbo.Contacto WHERE NombreCompleto IN (''Prueba borrar 1'',''Prueba borrar 2'');
IF (SELECT COUNT(*) FROM dbo.ContactoHistorial WHERE Operacion=''D'')<>@Antes+2 THROW 51900,''No se guardaron ambas eliminaciones.'',1;',0,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Unicode en narrativa',N'DECLARE @Id INT=(SELECT MIN(MensajeId) FROM dbo.Mensaje);
UPDATE dbo.Mensaje SET Contenido=N''Ánimo, mañana seguimos 🚀 学'' WHERE MensajeId=@Id;
IF NOT EXISTS(SELECT 1 FROM dbo.Mensaje WHERE MensajeId=@Id AND Contenido=N''Ánimo, mañana seguimos 🚀 学'') THROW 51900,''Se perdio Unicode.'',1;',0,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Desactivar renovacion conserva acceso',N'DECLARE @Id INT=(SELECT SuscripcionId FROM dbo.Suscripcion s JOIN dbo.Estudiante e ON e.EstudianteId=s.EstudianteId WHERE e.Codigo=''C001'' AND s.Estado=''VIGENTE'');
UPDATE dbo.Suscripcion SET RenovacionAutomatica=0,FechaDesactivacionRenovacion=GETDATE() WHERE SuscripcionId=@Id;
IF NOT EXISTS(SELECT 1 FROM dbo.PeriodoServicio WHERE SuscripcionId=@Id AND EstadoAcceso=''HABILITADO'' AND Inicio<=GETDATE() AND Fin>GETDATE()) THROW 51900,''Se perdio acceso pagado.'',1;',0,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Pago confirmado inmutable',N'UPDATE dbo.Pago SET Proveedor=''Alterado'' WHERE PagoId=(SELECT MIN(PagoId) FROM dbo.Pago WHERE Estado=''CONFIRMADO'');',51020,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'No duplicar suscripcion vigente',N'INSERT dbo.Suscripcion(EstudianteId,FechaContratacion,RenovacionAutomatica,Estado) SELECT TOP(1) EstudianteId,GETDATE(),1,''VIGENTE'' FROM dbo.Suscripcion WHERE Estado=''VIGENTE'';',2601,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'No superponer periodos',N'DECLARE @S INT=(SELECT s.SuscripcionId FROM dbo.Suscripcion s JOIN dbo.Estudiante e ON e.EstudianteId=s.EstudianteId WHERE e.Codigo=''C001'');
INSERT dbo.PeriodoServicio(SuscripcionId,ModalidadPlanId,Tipo,Inicio,Fin,PrecioAcordadoPEN,ImporteExigiblePEN,CondicionesAceptadas,EstadoAcceso)
SELECT SuscripcionId,ModalidadPlanId,''INICIAL'',Inicio,Fin,PrecioAcordadoPEN,PrecioAcordadoPEN,''Prueba'',''PENDIENTE'' FROM dbo.PeriodoServicio WHERE SuscripcionId=@S;',51010,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'No habilitar sin pago',N'DECLARE @S INT,@P INT;
INSERT dbo.Suscripcion(EstudianteId,FechaContratacion,RenovacionAutomatica,Estado) SELECT EstudianteId,GETDATE(),1,''VIGENTE'' FROM dbo.Estudiante WHERE Codigo=''C013'';
SET @S=SCOPE_IDENTITY();
INSERT dbo.PeriodoServicio(SuscripcionId,ModalidadPlanId,Tipo,Inicio,Fin,PrecioAcordadoPEN,ImporteExigiblePEN,CondicionesAceptadas,EstadoAcceso)
SELECT @S,MIN(ModalidadPlanId),''INICIAL'',GETDATE(),DATEADD(MONTH,1,GETDATE()),39.90,39.90,''Prueba'',''PENDIENTE'' FROM dbo.ModalidadPlan;
SET @P=SCOPE_IDENTITY();
UPDATE dbo.PeriodoServicio SET EstadoAcceso=''HABILITADO'',FechaHabilitacion=GETDATE() WHERE PeriodoServicioId=@P;',51014,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'No cobro de importe incorrecto',N'DECLARE @S INT,@P INT;
INSERT dbo.Suscripcion(EstudianteId,FechaContratacion,RenovacionAutomatica,Estado) SELECT EstudianteId,GETDATE(),1,''VIGENTE'' FROM dbo.Estudiante WHERE Codigo=''C013'';
SET @S=SCOPE_IDENTITY();
INSERT dbo.PeriodoServicio(SuscripcionId,ModalidadPlanId,Tipo,Inicio,Fin,PrecioAcordadoPEN,ImporteExigiblePEN,CondicionesAceptadas,EstadoAcceso)
SELECT @S,MIN(ModalidadPlanId),''INICIAL'',GETDATE(),DATEADD(MONTH,1,GETDATE()),39.90,39.90,''Prueba'',''PENDIENTE'' FROM dbo.ModalidadPlan;
SET @P=SCOPE_IDENTITY();
INSERT dbo.Pago(PeriodoServicioId,CodigoOperacion,Proveedor,Canal,Tipo,Estado,ImportePEN,FechaOperacion,FechaConfirmacion)
VALUES(@P,''PRUEBA-IMPORTE'',''DEMO'',''YAPE'',''COBRO'',''CONFIRMADO'',1,GETDATE(),GETDATE());',51021,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Renovacion necesita periodo anterior',N'DECLARE @S INT,@P INT;
INSERT dbo.Suscripcion(EstudianteId,FechaContratacion,RenovacionAutomatica,Estado) SELECT EstudianteId,GETDATE(),1,''VIGENTE'' FROM dbo.Estudiante WHERE Codigo=''C013'';
SET @S=SCOPE_IDENTITY();
INSERT dbo.PeriodoServicio(SuscripcionId,ModalidadPlanId,Tipo,Inicio,Fin,PrecioAcordadoPEN,ImporteExigiblePEN,CondicionesAceptadas,EstadoAcceso)
SELECT @S,MIN(ModalidadPlanId),''INICIAL'',GETDATE(),DATEADD(MONTH,1,GETDATE()),39.90,39.90,''Prueba'',''PENDIENTE'' FROM dbo.ModalidadPlan;
SET @P=SCOPE_IDENTITY();
UPDATE dbo.PeriodoServicio SET Tipo=''RENOVACION'' WHERE PeriodoServicioId=@P;',51012,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Beca requiere dueno',N'DECLARE @S INT,@P INT;
INSERT dbo.Suscripcion(EstudianteId,FechaContratacion,RenovacionAutomatica,Estado) SELECT EstudianteId,GETDATE(),1,''VIGENTE'' FROM dbo.Estudiante WHERE Codigo=''C013'';
SET @S=SCOPE_IDENTITY();
INSERT dbo.PeriodoServicio(SuscripcionId,ModalidadPlanId,Tipo,Inicio,Fin,PrecioAcordadoPEN,ImporteExigiblePEN,CondicionesAceptadas,EstadoAcceso)
SELECT @S,MIN(ModalidadPlanId),''INICIAL'',GETDATE(),DATEADD(MONTH,1,GETDATE()),39.90,39.90,''Prueba'',''PENDIENTE'' FROM dbo.ModalidadPlan;
SET @P=SCOPE_IDENTITY();
UPDATE dbo.PeriodoServicio SET BecaPorcentaje=100,ImporteExigiblePEN=0,AutorizadoPorId=(SELECT MIN(PersonalInternoId) FROM dbo.PersonalInterno WHERE Rol=''SOPORTE''),FechaAutorizacion=GETDATE() WHERE PeriodoServicioId=@P;',51013,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Ruta no publicada por soporte',N'UPDATE dbo.RutaEstudio SET ActualizadaPorId=(SELECT MIN(PersonalInternoId) FROM dbo.PersonalInterno WHERE Rol=''SOPORTE'') WHERE RutaEstudioId=(SELECT MIN(RutaEstudioId) FROM dbo.RutaEstudio);',51032,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Baja exactamente al vencimiento',N'UPDATE dbo.BajaServicio SET FechaBaja=DATEADD(DAY,7,FechaBaja) WHERE BajaServicioId=(SELECT MIN(BajaServicioId) FROM dbo.BajaServicio);',51030,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Valoracion no anterior a solicitud',N'UPDATE v SET FechaRespuesta=DATEADD(SECOND,-1,s.FechaEmision) FROM dbo.Valoracion v JOIN dbo.SolicitudValoracion s ON s.SolicitudValoracionId=v.SolicitudValoracionId;',51031,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Referido fijado inmutable',N'UPDATE dbo.Referido SET NombreReferido=''Alterado'' WHERE PrimerPagoId IS NOT NULL;',51040,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Evidencia de otro estudiante rechazada',N'UPDATE sr SET EventoUsoId=(SELECT MIN(u.EventoUsoId) FROM dbo.EventoUso u WHERE u.EstudianteId<>er.EstudianteId) FROM dbo.SenalRiesgo sr JOIN dbo.EvaluacionRiesgo er ON er.EvaluacionRiesgoId=sr.EvaluacionRiesgoId WHERE sr.EventoUsoId IS NOT NULL;',51046,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Validacion rechaza lote mixto completo',N'UPDATE dbo.RutaEstudio SET ActualizadaPorId=CASE WHEN RutaEstudioId=(SELECT MIN(RutaEstudioId) FROM dbo.RutaEstudio) THEN (SELECT MIN(PersonalInternoId) FROM dbo.PersonalInterno WHERE Rol=''SOPORTE'') ELSE ActualizadaPorId END;',51032,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Seguimiento no usa mensaje ajeno',N'UPDATE i SET MensajeSeguimientoId=(SELECT MIN(m.MensajeId) FROM dbo.Mensaje m JOIN dbo.Conversacion c ON c.ConversacionId=m.ConversacionId WHERE c.EstudianteId<>i.EstudianteId AND m.Direccion=''SALIENTE'') FROM dbo.Intervencion i;',51042,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Beca completa sin pagos en demo',N'IF EXISTS(SELECT 1 FROM dbo.PeriodoServicio p JOIN dbo.Pago pg ON pg.PeriodoServicioId=p.PeriodoServicioId WHERE p.BecaPorcentaje=100) THROW 51900,''Beca con pago.'',1;',0,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'C-4 Bruno completo y mensaje enviado',N'IF NOT EXISTS(SELECT 1 FROM dbo.Intervencion i JOIN dbo.Estudiante e ON e.EstudianteId=i.EstudianteId JOIN dbo.Mensaje m ON m.MensajeId=i.MensajeSeguimientoId WHERE e.Codigo=''C002'' AND i.Estado=''COMPLETADA'' AND m.FechaEnvio IS NOT NULL AND m.Estado IN (''ENVIADO'',''ENTREGADO'')) THROW 51900,''Bruno no cumple C4.'',1;',0,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Aceptacion aun sin aplicacion',N'IF NOT EXISTS(SELECT 1 FROM dbo.PropuestaCambioPlan WHERE Estado=''ACEPTADA'' AND PeriodoAplicadoId IS NULL) THROW 51900,''Falta caso aceptado sin aplicar.'',1;',0,0);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Riesgo alto se puede cambiar a bajo',N'UPDATE dbo.EvaluacionRiesgo SET Nivel=''BAJO'' WHERE Estado=''CLASIFICADA'' AND Nivel=''ALTO'';',0,1);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Senal acepta nivel contrario a su evidencia',N'UPDATE dbo.SenalRiesgo SET Nivel=''BAJO'' WHERE Codigo=''INSATISFACCION'';',0,1);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Mensaje registrado como enviado sin permiso',N'INSERT dbo.Mensaje(ConversacionId,Direccion,Emisor,Contenido,Estado,FechaEnvio)
SELECT TOP(1) c.ConversacionId,''SALIENTE'',''IA_ACADEMICO'',N''Prueba sin envio externo'',''ENVIADO'',GETDATE()
FROM dbo.Conversacion c JOIN dbo.AutorizacionContacto a ON a.ContactoId=c.ContactoId AND a.Canal=c.Canal AND a.Finalidad=c.Finalidad
WHERE a.Autorizado=0;
IF @@ROWCOUNT<>1 THROW 51900,''No se encontro conversacion sin permiso.'',1;',0,1);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Evidencia de uso permite alterar su estudiante',N'UPDATE dbo.EventoUso SET EstudianteId=(SELECT EstudianteId FROM dbo.Estudiante WHERE Codigo=''C013'') WHERE EventoUsoId=(SELECT MIN(EventoUsoId) FROM dbo.SenalRiesgo WHERE EventoUsoId IS NOT NULL);',0,1);
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES(N'Etapa CUSTOMER sin habilitacion admitida',N'UPDATE dbo.Estudiante SET EtapaActual=''CUSTOMER'' WHERE Codigo=''C013'';',0,1);

-- Limites exactos de las comparaciones usadas en las consultas exploratorias.
-- No equivalen a ejecutar un clasificador: todavia no existe uno implementado.
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES
(N'Umbrales exactos de inactividad',N'
DECLARE @Corte DATETIME2(0)=''2026-11-11T12:00:00'';
IF EXISTS(SELECT 1 FROM (VALUES(259199,''BAJO''),(259200,''MEDIO''),(604799,''MEDIO''),(604800,''ALTO'')) v(Segundos,Nivel)
WHERE CASE WHEN DATEADD(SECOND,-v.Segundos,@Corte)<=DATEADD(HOUR,-168,@Corte) THEN ''ALTO'' WHEN DATEADD(SECOND,-v.Segundos,@Corte)<=DATEADD(HOUR,-72,@Corte) THEN ''MEDIO'' ELSE ''BAJO'' END<>v.Nivel)
THROW 51900,''Umbral incorrecto de inactividad.'',1;',0,0),
(N'Umbrales exactos de incidencia',N'
DECLARE @Corte DATETIME2(0)=''2026-11-11T12:00:00'';
IF EXISTS(SELECT 1 FROM (VALUES(172800,''BAJO''),(172801,''MEDIO''),(345600,''MEDIO''),(345601,''ALTO'')) v(Segundos,Nivel)
WHERE CASE WHEN DATEADD(SECOND,-v.Segundos,@Corte)<DATEADD(HOUR,-96,@Corte) THEN ''ALTO'' WHEN DATEADD(SECOND,-v.Segundos,@Corte)<DATEADD(HOUR,-48,@Corte) THEN ''MEDIO'' ELSE ''BAJO'' END<>v.Nivel)
THROW 51900,''Umbral incorrecto de incidencia.'',1;',0,0);

-- Un nuevo formulario no crea otra fecha de ingreso; los invalidos no cuentan.
INSERT @Pruebas(Caso,Comando,ErrorEsperado,EsHallazgo) VALUES
(N'Primer formulario valido conserva el ingreso a LEAD',N'
DECLARE @Contacto INT=(SELECT ContactoId FROM dbo.Estudiante WHERE Codigo=''C001'');
DECLARE @Primero DATETIME2(0)=(SELECT MIN(FechaEnvio) FROM dbo.FormularioContacto WHERE ContactoId=@Contacto AND Valido=1);
IF @Primero IS NULL THROW 51900,''Falta el formulario inicial valido.'',1;
INSERT dbo.FormularioContacto(ContactoId,RolDeclarado,FechaEnvio,CanalOrigen,Valido)
VALUES(@Contacto,''ESTUDIANTE'',DATEADD(DAY,-1,@Primero),''DEMO'',0),
      (@Contacto,''ESTUDIANTE'',DATEADD(SECOND,1,@Primero),''DEMO'',1);
IF (SELECT MIN(FechaEnvio) FROM dbo.FormularioContacto WHERE ContactoId=@Contacto AND Valido=1)<>@Primero
    THROW 51900,''Un reenvio o formulario invalido altero la fecha de ingreso.'',1;',0,0);

DECLARE @Id INT=1,@Caso NVARCHAR(150),@Comando NVARCHAR(MAX),@Esperado INT,@Hallazgo BIT,@Error INT,@Detalle NVARCHAR(2048);
WHILE @Id<=(SELECT COUNT(*) FROM @Pruebas)
BEGIN
    SELECT @Caso=Caso,@Comando=Comando,@Esperado=ErrorEsperado,@Hallazgo=EsHallazgo FROM @Pruebas WHERE Id=@Id;
    SELECT @Error=0,@Detalle=NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        EXEC sys.sp_executesql @Comando;
        ROLLBACK TRANSACTION;
    END TRY
    BEGIN CATCH
        SELECT @Error=ERROR_NUMBER(),@Detalle=ERROR_MESSAGE();
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    END CATCH;
    INSERT @Resultados VALUES(@Id,@Caso,CASE WHEN @Error<>@Esperado THEN 'FALLO' WHEN @Hallazgo=1 THEN 'HALLAZGO' ELSE 'OK' END,@Error,@Detalle);
    SET @Id+=1;
END;
SELECT Id,Caso,Resultado,ErrorObtenido,Detalle FROM @Resultados ORDER BY Id;
SELECT Resultado,COUNT(*) AS Casos FROM @Resultados GROUP BY Resultado;
IF EXISTS(SELECT 1 FROM @Resultados WHERE Resultado='FALLO') THROW 51902,'Hay resultados distintos de lo esperado; revisar detalle.',1;
GO
