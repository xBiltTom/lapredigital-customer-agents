/*
LaPreDigital | Campo de pruebas de consultas CUSTOMERS | Informe 7.1

COMO USAR
1. Ejecutar primero USE y SET de abajo; despues seleccionar un bloque hasta su GO.
2. T01-T14: consultas tradicionales. A01-A06: informacion para el futuro agente.
3. Cambiar @Codigo, @Dias o @Inicio dentro del bloque que se quiera explorar.
4. Solo lectura: no modifica tablas, no guarda evaluaciones y no envia mensajes.

INDICE (buscar el codigo con Ctrl+F)
T01 customers; T02 contrataciones; T03 vencimientos; T04 cumplimiento;
T05 mejora academica; T06 revisiones; T07 satisfaccion/respuestas;
T08 incidencias; T09 riesgo; T10 seguimiento; T11 cambios de plan;
T12 renovaciones; T13 referidos; T14 fecha de ingreso del contacto.
A01 evolucion del uso; A02 tareas pendientes; A03 evidencias de riesgo;
A04 permisos y seguimiento previo; A05 apoderados; A06 incoherencias.

FECHAS Y RESULTADOS
- GETDATE() mantiene la hora peruana configurada en el contenedor.
- Los bloques operativos consultan el estado ACTUAL. No retroceder @Corte para
  simular un cierre: hay estados que ya pueden haber cambiado desde esa fecha.
- Los indicadores mensuales son PROVISIONALES del mes en curso hasta @Corte.
  No son reportes cerrados: aun falta congelar lo conocido al cierre en el modelo.
- En porcentajes, NULL significa no aplicable si el denominador es cero.
- Cumplimiento sin actividades = no aplicable; mejora sin pruebas comparables =
  sin datos suficientes. Riesgo pendiente/vencido nunca se convierte en BAJO.
- Los esperados en comentarios corresponden a la demo recien cargada. Envejecen.

RECOMENDACIONES PARA DISCUTIR SEGUN LOS RESULTADOS
R1. Conservar GrupoComparabilidad y el enlace periodo anterior: evitan comparar
    pruebas distintas y confundir renovacion continua con reactivacion.
R2. Evaluar un enlace Intervencion -> ActividadRuta para saber que tarea ya tuvo
    recordatorio. Hoy solo se puede revisar el seguimiento general del alumno.
R3. Proteger evidencias y la coherencia evaluacion/senales antes de escribir con IA.
R4. Definir una politica de frecuencia de contacto; no inventamos una espera de
    24/48 horas porque el informe no la establece para CUSTOMERS.
R5. Definir el cierre mensual y como conservar decisiones/contexto conocidos.
No se cambia la estructura con este archivo; primero vamos a observar resultados.
*/
USE LaPreDigital_Customers;
GO
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================================
-- PARTE 1. CONSULTAS TRADICIONALES
-- ============================================================================

/* T01. Quienes son CUSTOMER y que servicio tienen ahora?
   Una fila por periodo vigente; LEFT JOIN deja visible CUSTOMER sin acceso.
   Esperado: 12 customers; Fabio con beca 100 %, Ines sin renovacion automatica.
   Si aparecen dos periodos vigentes para un alumno, revisar la integridad.
*/

-- CONSULTAS EXPLORATORIAS

SELECT
    *
FROM Estudiante E
INNER JOIN Contacto C on C.ContactoId = E.ContactoId;

SELECT
    *
FROM Contacto;

-- CONSULTAR AL ESTUDIANTE CON SU APODERADO
SELECT
    C.NombreCompleto as Estudiante,
    CA.NombreCompleto as Apoderado
FROM Estudiante E
INNER JOIN Contacto C on E.ContactoId = C.ContactoId
LEFT JOIN Apoderado A on E.ApoderadoId = A.ApoderadoId
LEFT JOIN Contacto CA on CA.ContactoId = A.ContactoId

-- NUMERO DE ESTUDIANTES QUE CADA APODERADO TIENE A SU CARGO
SELECT
    CA.NombreCompleto as Apoderado,
    COUNT(*) as Estudiantes
FROM Apoderado A
INNER JOIN Contacto CA on CA.ContactoId = A.ContactoId
INNER JOIN Estudiante E on E.ApoderadoId = A.ApoderadoId
GROUP BY CA.NombreCompleto

SELECT * FROM Apoderado;

-- PLANES Y MODALIDADES EN VENTA
SELECT
    PS.Nombre,
    MP.PrecioPEN,
    MP.Meses
FROM PlanServicio PS
INNER JOIN ModalidadPlan MP on MP.PlanServicioId = PS.PlanServicioId
WHERE PS.PlanServicioId = 2;

-- Prestaciones que ofrece un determinado plan
SELECT
    PS.Nombre,
    P.Descripcion
FROM PlanPrestacion PP
INNER JOIN Prestacion P on P.PrestacionId = PP.PrestacionId
INNER JOIN PlanServicio PS on PS.PlanServicioId = PP.PlanServicioId
WHERE PS.PlanServicioId = 3;

-- CANTIDAD DE PRESTACIONES QUE OFRECE CADA PLAN
SELECT
    PS.Nombre,
    COUNT(*) as CantidadPrestaciones
FROM PlanServicio PS
INNER JOIN PlanPrestacion PP on PP.PlanServicioId = PS.PlanServicioId
INNER JOIN Prestacion P on P.PrestacionId = PP.PrestacionId
GROUP BY PS.Nombre
ORDER BY CantidadPrestaciones DESC;

SELECT
    *
FROM ModalidadPlan;

SELECT
    *
FROM Prestacion;

-- CONTRATACION DE UN ESTUDIANTE
DECLARE @CodigoEstudiante VARCHAR(20) = 'C011'

SELECT
    CE.NombreCompleto as Estudiante,
    E.EtapaActual,

    S.SuscripcionId as Suscripcion,
    S.Estado as EstadoSuscripcion,
    S.RenovacionAutomatica RenovacionActiva,

    PS.PeriodoServicioId as Periodo,
    PS.Tipo as TipoPeriodo,
    PL.Nombre as NombrePlan,
    M.Meses as ModalidadMeses,

    PS.Inicio as PeriodoInicio,
    PS.Fin as PeriodoFin,
    PS.EstadoAcceso as Acceso,
    PS.BecaPorcentaje,
    PS.ImporteExigiblePEN
FROM Estudiante E
INNER JOIN Contacto CE on CE.ContactoId = E.ContactoId
LEFT JOIN Suscripcion S on S.EstudianteId = E.EstudianteId
LEFT JOIN PeriodoServicio PS on PS.SuscripcionId = S.SuscripcionId
LEFT JOIN ModalidadPlan M on M.ModalidadPlanId = PS.ModalidadPlanId
LEFT JOIN PlanServicio PL on PL.PlanServicioId = M.PlanServicioId
WHERE E.Codigo = @CodigoEstudiante
ORDER BY PS.Inicio, PS.PeriodoServicioId;

-- ESTUDIANTES CON LA CANTIDAD DE SUSCRIPCIONES QUE TIENEN Y EL NUMERO DE PERIODOS TOTALES
SELECT
    E.Codigo,
    CE.NombreCompleto as Estudiante,
    COUNT(DISTINCT S.SuscripcionId) as NroSuscripciones,
    COUNT(PS.PeriodoServicioId) as NroPeriodos
FROM Estudiante E
INNER JOIN Contacto CE on CE.ContactoId = E.ContactoId
LEFT JOIN Suscripcion S on S.EstudianteId = E.EstudianteId
LEFT JOIN PeriodoServicio PS on PS.SuscripcionId = S.SuscripcionId
GROUP BY E.Codigo, CE.NombreCompleto;

-- PERIODOS POR SUSCRIPCION DE UN ESTUDIANTE
SELECT
    E.Codigo,
    CE.NombreCompleto as Estudiante,
    S.SuscripcionId as Suscripcion,
    COUNT(PS.PeriodoServicioId) as NroPeriodos
FROM Estudiante E
INNER JOIN Contacto CE on CE.ContactoId = E.ContactoId
LEFT JOIN Suscripcion S on S.EstudianteId = E.EstudianteId
LEFT JOIN PeriodoServicio PS on PS.SuscripcionId = S.SuscripcionId
GROUP BY E.Codigo, CE.NombreCompleto, S.SuscripcionId;

SELECT * FROM Estudiante;

-- GASTO TOTAL DE LOS ESTUDIANTES DENTRO DE LA PLATAFORMA
SELECT
    E.Codigo,
    CE.NombreCompleto as Estudiante,
    COUNT(DISTINCT S.SuscripcionId) as NroSuscripciones,
    COUNT(PS.PeriodoServicioId) as NroPeriodos,
    SUM(PS.ImporteExigiblePEN) as GastoTotal
FROM Estudiante E
INNER JOIN Contacto CE on CE.ContactoId = E.ContactoId
LEFT JOIN Suscripcion S on S.EstudianteId = E.EstudianteId
LEFT JOIN PeriodoServicio PS on PS.SuscripcionId = S.SuscripcionId
GROUP BY E.Codigo, CE.NombreCompleto;

SELECT * FROM Suscripcion WHERE EstudianteId = '5';

SELECT * FROM PeriodoServicio;

SELECT * FROM ModalidadPlan;

SELECT
    estudiante.Codigo,
    contacto.NombreCompleto,
    COUNT(uso.EventoUsoId) AS TotalEventosRegistrados,
    MAX(uso.FechaEvento) AS UltimaActividad

FROM dbo.Estudiante AS estudiante

JOIN dbo.Contacto AS contacto
    ON contacto.ContactoId = estudiante.ContactoId

LEFT JOIN dbo.EventoUso AS uso
    ON uso.EstudianteId = estudiante.EstudianteId
    AND uso.FechaEvento <= GETDATE()

WHERE estudiante.EtapaActual = 'CUSTOMER'

GROUP BY
    estudiante.Codigo,
    contacto.NombreCompleto

ORDER BY UltimaActividad, estudiante.Codigo;

SELECT * FROM EventoUso;

SELECT * FROM RecursoAcademico;


DECLARE @MomentoActual DATETIME2(0) = GETDATE();

SELECT
    estudiante.Codigo,
    contacto.NombreCompleto,
    estudiante.EtapaActual
FROM dbo.Estudiante AS estudiante

JOIN dbo.Contacto AS contacto
    ON contacto.ContactoId = estudiante.ContactoId

WHERE estudiante.EtapaActual = 'CUSTOMER'

AND NOT EXISTS (
    SELECT 1
    FROM dbo.Suscripcion AS suscripcion

    JOIN dbo.PeriodoServicio AS periodo
        ON periodo.SuscripcionId = suscripcion.SuscripcionId

    WHERE suscripcion.EstudianteId = estudiante.EstudianteId
      AND suscripcion.Estado = 'VIGENTE'
      AND periodo.EstadoAcceso IN ('HABILITADO', 'CON_INCIDENCIA')
      AND periodo.Inicio <= @MomentoActual
      AND periodo.Fin > @MomentoActual
);

-- ==========================================

PRINT N'T01 | Customers y servicio actual';
DECLARE @Corte DATETIME2(0) = GETDATE();
SELECT e.Codigo, c.NombreCompleto, e.CarreraObjetivo, e.FechaExamen,
       s.SuscripcionId, pl.Nombre AS PlanActual, mp.Meses,
       p.PeriodoServicioId, p.Inicio, p.Fin, p.EstadoAcceso,
       p.BecaPorcentaje, p.ImporteExigiblePEN, s.RenovacionAutomatica,
       CASE WHEN p.PeriodoServicioId IS NULL THEN N'REVISAR: sin servicio vigente'
            ELSE N'Servicio vigente' END AS Situacion
FROM dbo.Estudiante e
JOIN dbo.Contacto c ON c.ContactoId = e.ContactoId
LEFT JOIN dbo.Suscripcion s ON s.EstudianteId = e.EstudianteId AND s.Estado = 'VIGENTE'
LEFT JOIN dbo.PeriodoServicio p ON p.SuscripcionId = s.SuscripcionId
 AND p.Inicio <= @Corte AND p.Fin > @Corte
 AND p.EstadoAcceso IN ('HABILITADO','CON_INCIDENCIA')
LEFT JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId = p.ModalidadPlanId
LEFT JOIN dbo.PlanServicio pl ON pl.PlanServicioId = mp.PlanServicioId
WHERE e.EtapaActual = 'CUSTOMER'
ORDER BY e.Codigo;
GO

/* T02. Historial de contratacion, pagos y bajas de un estudiante.
   Probar C005 (renovacion), C006 (beca), C010 (baja), C011 (reactivacion).
   Se agregan pagos ANTES de unir: operaciones correctivas no duplican periodos.
   No se restan automaticamente disputas como si fueran reembolsos definitivos.
*/
PRINT N'T02 | Contratacion y episodios de servicio';
DECLARE @Codigo VARCHAR(20) = 'C011';
SELECT e.Codigo, e.EtapaActual, s.SuscripcionId, s.Estado AS EstadoSuscripcion,
       pl.Nombre AS PlanContratado, p.PeriodoServicioId, p.PeriodoAnteriorId,
       p.Tipo, p.Inicio, p.Fin, p.EstadoAcceso, p.FechaHabilitacion,
       p.BecaPorcentaje, p.ImporteExigiblePEN,
       pg.CobrosConfirmados, pg.ImporteCobradoPEN, pg.OperacionesCorrectivas,
       b.FechaBaja, b.MotivoComunicado, b.ElegibleReactivacion
FROM dbo.Estudiante e
JOIN dbo.Suscripcion s ON s.EstudianteId = e.EstudianteId
JOIN dbo.PeriodoServicio p ON p.SuscripcionId = s.SuscripcionId
JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId = p.ModalidadPlanId
JOIN dbo.PlanServicio pl ON pl.PlanServicioId = mp.PlanServicioId
LEFT JOIN dbo.BajaServicio b ON b.PeriodoServicioId = p.PeriodoServicioId
OUTER APPLY (
    SELECT COUNT(CASE WHEN Tipo = 'COBRO' AND Estado = 'CONFIRMADO' THEN 1 END) AS CobrosConfirmados,
           SUM(CASE WHEN Tipo = 'COBRO' AND Estado = 'CONFIRMADO' THEN ImportePEN ELSE 0 END) AS ImporteCobradoPEN,
           COUNT(CASE WHEN Tipo <> 'COBRO' AND Estado = 'CONFIRMADO' THEN 1 END) AS OperacionesCorrectivas
    FROM dbo.Pago WHERE PeriodoServicioId = p.PeriodoServicioId
) pg
WHERE e.Codigo = @Codigo
ORDER BY p.Inicio, p.PeriodoServicioId;
GO

/* T03. Servicios por vencer y continuidad ya contratada (C-5).
   Desactivar renovacion NO significa baja antes de Fin. No hay siete dias extra.
   El agente academico orienta; el cobro y problemas economicos van a PAYERS.
*/
PRINT N'T03 | Vencimientos proximos';
DECLARE @Corte DATETIME2(0) = GETDATE();
DECLARE @Dias INT = 15;
SELECT e.Codigo, pl.Nombre AS PlanActual, p.Fin, s.RenovacionAutomatica,
       s.FechaDesactivacionRenovacion,
       CASE WHEN EXISTS (
                SELECT 1 FROM dbo.PeriodoServicio n
                WHERE n.PeriodoAnteriorId = p.PeriodoServicioId
                  AND n.Tipo = 'RENOVACION' AND n.Inicio = p.Fin
                  AND n.FechaHabilitacion <= @Corte
                  AND n.EstadoAcceso IN ('HABILITADO','CON_INCIDENCIA')
            ) THEN N'Continuidad habilitada'
            WHEN s.RenovacionAutomatica = 0 THEN N'Acceso hasta Fin; no cobrar automaticamente'
            ELSE N'Renovacion automatica activa; pago aun por confirmar' END AS Situacion
FROM dbo.Estudiante e
JOIN dbo.Suscripcion s ON s.EstudianteId = e.EstudianteId AND s.Estado = 'VIGENTE'
JOIN dbo.PeriodoServicio p ON p.SuscripcionId = s.SuscripcionId
JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId = p.ModalidadPlanId
JOIN dbo.PlanServicio pl ON pl.PlanServicioId = mp.PlanServicioId
WHERE e.EtapaActual = 'CUSTOMER' AND p.Inicio <= @Corte
  AND p.Fin > @Corte AND p.Fin <= DATEADD(DAY, @Dias, @Corte)
  AND p.EstadoAcceso IN ('HABILITADO','CON_INCIDENCIA')
ORDER BY p.Fin, e.Codigo;
GO

/* T04. Cumplimiento de la ruta vigente por estudiante (C-1.2).
   Ventana movil de 30 dias. Se excluyen tareas canceladas, como en la demo.
   Solo cuentan completadas las MISMAS tareas del denominador.
   Esperado: Gabriela 0 tareas y NULL; Ana usa su nueva ruta, no ambas versiones.
   No confundir cumplimiento con mejora de notas (T05).
*/
PRINT N'T04 | Cumplimiento de actividades';
DECLARE @Corte DATETIME2(0) = GETDATE();
DECLARE @Inicio DATETIME2(0) = DATEADD(DAY, -30, @Corte);
SELECT e.Codigo, r.RutaEstudioId, r.VersionNumero,
       COUNT(a.ActividadRutaId) AS Planificadas,
       SUM(CASE WHEN a.Estado = 'COMPLETADA' AND a.FechaCompletada <= @Corte THEN 1 ELSE 0 END) AS Completadas,
       CONVERT(DECIMAL(6,2), 100.0 * SUM(CASE WHEN a.Estado = 'COMPLETADA' AND a.FechaCompletada <= @Corte THEN 1 ELSE 0 END)
           / NULLIF(COUNT(a.ActividadRutaId), 0)) AS CumplimientoPct,
       CASE WHEN r.RutaEstudioId IS NULL THEN N'Sin ruta vigente'
            WHEN COUNT(a.ActividadRutaId) = 0 THEN N'No aplicable'
            ELSE N'Calculado' END AS Situacion
FROM dbo.Estudiante e
LEFT JOIN dbo.RutaEstudio r ON r.EstudianteId = e.EstudianteId AND r.Vigente = 1
LEFT JOIN dbo.ActividadRuta a ON a.RutaEstudioId = r.RutaEstudioId
 AND a.FechaPlanificada >= @Inicio AND a.FechaPlanificada <= @Corte
 AND a.Estado <> 'CANCELADA'
WHERE e.EtapaActual = 'CUSTOMER'
GROUP BY e.Codigo, r.RutaEstudioId, r.VersionNumero
ORDER BY e.Codigo;
GO

/* T05. Mejora academica en puntos porcentuales (C-1.3).
   Primer y ultimo intento dentro de CADA grupo comparable, hasta ahora.
   Esperado: Ana +15 pp; Carla -25 pp; Diego insuficiente en sus dos grupos;
   Gabriela cero intentos. No comparar 40 % de algebra con 55 % de geometria.
*/
PRINT N'T05 | Mejora en pruebas comparables';
DECLARE @Corte DATETIME2(0) = GETDATE();
;WITH Intentos AS (
    SELECT i.EstudianteId, ev.GrupoComparabilidadId, i.IntentoEvaluacionId,
           100.0 * i.Aciertos / i.TotalPreguntas AS AciertosPct,
           ROW_NUMBER() OVER (PARTITION BY i.EstudianteId, ev.GrupoComparabilidadId ORDER BY i.FechaFin, i.IntentoEvaluacionId) AS Primero,
           ROW_NUMBER() OVER (PARTITION BY i.EstudianteId, ev.GrupoComparabilidadId ORDER BY i.FechaFin DESC, i.IntentoEvaluacionId DESC) AS Ultimo
    FROM dbo.IntentoEvaluacion i
    JOIN dbo.Evaluacion ev ON ev.EvaluacionId = i.EvaluacionId
    WHERE ev.GrupoComparabilidadId IS NOT NULL AND i.FechaFin <= @Corte
)
SELECT e.Codigo, g.Codigo AS GrupoComparable, g.Alcance, g.Escala, g.Dificultad,
       COUNT(i.IntentoEvaluacionId) AS Intentos,
       CONVERT(DECIMAL(6,2), MAX(CASE WHEN i.Primero = 1 THEN i.AciertosPct END)) AS InicialPct,
       CONVERT(DECIMAL(6,2), MAX(CASE WHEN i.Ultimo = 1 THEN i.AciertosPct END)) AS PosteriorPct,
       CASE WHEN COUNT(i.IntentoEvaluacionId) >= 2 THEN CONVERT(DECIMAL(6,2),
           MAX(CASE WHEN i.Ultimo = 1 THEN i.AciertosPct END) - MAX(CASE WHEN i.Primero = 1 THEN i.AciertosPct END)) END AS MejoraPP,
       CASE WHEN COUNT(i.IntentoEvaluacionId) < 2 THEN N'Sin datos suficientes' ELSE N'Comparacion disponible' END AS Situacion
FROM dbo.Estudiante e
LEFT JOIN Intentos i ON i.EstudianteId = e.EstudianteId
LEFT JOIN dbo.GrupoComparabilidad g ON g.GrupoComparabilidadId = i.GrupoComparabilidadId
WHERE e.EtapaActual = 'CUSTOMER'
GROUP BY e.Codigo, g.Codigo, g.Alcance, g.Escala, g.Dificultad
ORDER BY e.Codigo, g.Codigo;
GO

/* T06. Por que se solicito revisar una ruta y quien la reviso? (C-1).
   Incluye la version anterior: una revision no desaparece al publicarse otra ruta.
   Esperado: Ana revisada por dueño con ruta resultante; otras pendientes.
   Para C-1.1 contar RUTAS, no multiplicarlas si tienen varias solicitudes.
   Antes de calcular ese KPI, acordar cuando una ruta con varias revisiones
   pendientes se considera revisada; aqui mostramos el detalle sin ocultarlo.
*/
PRINT N'T06 | Revisiones de rutas';
SELECT e.Codigo, rr.RevisionRutaId, r.RutaEstudioId, r.VersionNumero,
       rr.Motivo, rr.FechaIdentificacion, rr.Estado, rr.Recomendacion,
       pi.Nombre AS RevisadaPor, pi.Rol, rr.FechaRevision,
       rr.RutaResultanteId, rr.Resultado
FROM dbo.RevisionRuta rr
JOIN dbo.RutaEstudio r ON r.RutaEstudioId = rr.RutaEstudioId
JOIN dbo.Estudiante e ON e.EstudianteId = r.EstudianteId
LEFT JOIN dbo.PersonalInterno pi ON pi.PersonalInternoId = rr.RevisadaPorId
ORDER BY CASE WHEN rr.Estado = 'PENDIENTE' THEN 0 ELSE 1 END, rr.FechaIdentificacion;
GO

/* T07. Satisfaccion y respuesta a solicitudes (C-2.1 y C-2.2).
   Dos resultados: estrellas por fecha de RESPUESTA y solicitudes por fecha de
   EMISION. Una solicitud de octubre respondida en noviembre pertenece a cohortes
   distintas en ambos KPI. Cada calificacion valida tiene el mismo peso.
   No promediar los promedios de aspectos. NULL en porcentaje = no aplicable.
*/
PRINT N'T07 | Satisfaccion y respuesta del mes en curso';
DECLARE @Corte DATETIME2(0) = GETDATE();
DECLARE @Inicio DATE = DATEFROMPARTS(YEAR(@Corte), MONTH(@Corte), 1);
SELECT CASE WHEN GROUPING(a.Nombre) = 1 THEN N'GENERAL' ELSE a.Nombre END AS Aspecto,
       COUNT(*) AS Calificaciones,
       CONVERT(DECIMAL(4,2), AVG(CONVERT(DECIMAL(4,2), v.Estrellas))) AS PromedioEstrellas
FROM dbo.Valoracion v
JOIN dbo.SolicitudValoracion s ON s.SolicitudValoracionId = v.SolicitudValoracionId
JOIN dbo.AspectoValoracion a ON a.AspectoValoracionId = s.AspectoValoracionId
WHERE v.Valida = 1 AND v.FechaRespuesta >= @Inicio AND v.FechaRespuesta <= @Corte
GROUP BY GROUPING SETS ((a.Nombre), ());
SELECT COUNT(*) AS SolicitudesEmitidas,
       COUNT(v.ValoracionId) AS SolicitudesRespondidas,
       CONVERT(DECIMAL(6,2), 100.0 * COUNT(v.ValoracionId) / NULLIF(COUNT(*), 0)) AS RespuestaPct
FROM dbo.SolicitudValoracion s
LEFT JOIN dbo.Valoracion v ON v.SolicitudValoracionId = s.SolicitudValoracionId AND v.FechaRespuesta <= @Corte
WHERE s.FechaEmision >= @Inicio AND s.FechaEmision <= @Corte;
GO

/* T08. Incidencias de servicio/acceso y resolucion del mes (C-2.3).
   No incluye consultas ni incidencias de PAGO. Una reapertura conserva el reloj
   desde FechaAperturaOriginal, incluidas las horas intermedias.
   Los umbrales actuales proceden de PoliticaRiesgo; el limite medio es estricto y el alto tambien.
   Esperado: Mateo REABIERTA y Diego ABIERTA con señal alta; Bruno media.
*/
PRINT N'T08 | Incidencias del servicio';
DECLARE @Corte DATETIME2(0) = GETDATE();
DECLARE @MedioHoras INT, @AltoHoras INT;
SELECT TOP(1) @MedioHoras=IncidenciaMediaHoras,@AltoHoras=IncidenciaAltaHoras FROM dbo.PoliticaRiesgo ORDER BY Numero DESC;
DECLARE @Inicio DATE = DATEFROMPARTS(YEAR(@Corte), MONTH(@Corte), 1);
SELECT e.Codigo, c.CasoAtencionId, c.Ambito, c.Estado, c.Descripcion,
       c.FechaAperturaOriginal, c.FechaResolucionDefinitiva, pi.Nombre AS Responsable,
       CONVERT(DECIMAL(10,2), DATEDIFF_BIG(SECOND, c.FechaAperturaOriginal,
           COALESCE(c.FechaResolucionDefinitiva, @Corte)) / 3600.0) AS HorasDesdeApertura,
       CASE WHEN c.Estado = 'RESUELTA' THEN N'Resuelta'
            WHEN c.FechaAperturaOriginal < DATEADD(HOUR, -@AltoHoras, @Corte) THEN N'ALTO'
            WHEN c.FechaAperturaOriginal < DATEADD(HOUR, -@MedioHoras, @Corte) THEN N'MEDIO'
            ELSE N'Sin umbral horario de riesgo' END AS SenalPorAntiguedad
FROM dbo.CasoAtencion c
JOIN dbo.Estudiante e ON e.EstudianteId = c.EstudianteId
LEFT JOIN dbo.PersonalInterno pi ON pi.PersonalInternoId = c.ResponsableId
WHERE c.Tipo = 'INCIDENCIA' AND c.Ambito IN ('SERVICIO','ACCESO') AND c.FechaAperturaOriginal <= @Corte
ORDER BY c.FechaAperturaOriginal;
SELECT COUNT(*) AS IncidenciasRegistradasMes,
       COUNT(CASE WHEN Estado = 'RESUELTA' AND FechaResolucionDefinitiva <= @Corte THEN 1 END) AS Resueltas,
       CONVERT(DECIMAL(6,2), 100.0 * COUNT(CASE WHEN Estado = 'RESUELTA' AND FechaResolucionDefinitiva <= @Corte THEN 1 END)
           / NULLIF(COUNT(*), 0)) AS ResolucionPct
FROM dbo.CasoAtencion
WHERE Tipo = 'INCIDENCIA' AND Ambito IN ('SERVICIO','ACCESO')
  AND FechaAperturaOriginal >= @Inicio AND FechaAperturaOriginal <= @Corte;
GO

/* T09. Ultima evaluacion de riesgo guardada por customer (C-3).
   Una pendiente reciente se muestra PENDIENTE, no BAJO. La vigencia se consulta en la version de reglas guardada.
   Esperado: Gabriela pendiente y Hugo vencida. Esto NO recalcula la clasificacion.
   Antes de publicar C-3.1, acordar si pendiente integra cobertura: mostrarla
   separada evita tratar una falta de clasificacion como evaluacion resuelta.
*/
PRINT N'T09 | Riesgo registrado y vigencia';
DECLARE @Corte DATETIME2(0) = GETDATE();
SELECT e.Codigo, er.EvaluacionRiesgoId, er.Estado, er.Nivel, er.FechaEvaluacion,
       er.VersionReglas, er.Motivo,
       CASE WHEN er.EvaluacionRiesgoId IS NULL THEN N'SIN EVALUACION'
            WHEN er.FechaEvaluacion < DATEADD(DAY, -reglasEvaluadas.VigenciaDias, @Corte) THEN N'VENCIDA'
            WHEN er.Estado = 'PENDIENTE' THEN N'PENDIENTE'
            ELSE N'CLASIFICADA VIGENTE' END AS Situacion
FROM dbo.Estudiante e
OUTER APPLY (
    SELECT TOP (1) r.EvaluacionRiesgoId, r.Estado, r.Nivel, r.FechaEvaluacion, r.VersionReglas, r.Motivo
    FROM dbo.EvaluacionRiesgo r
    WHERE r.EstudianteId = e.EstudianteId AND r.FechaEvaluacion <= @Corte
    ORDER BY r.FechaEvaluacion DESC, r.EvaluacionRiesgoId DESC
) er
LEFT JOIN dbo.PoliticaRiesgo reglasEvaluadas ON reglasEvaluadas.VersionReglas=er.VersionReglas
WHERE e.EtapaActual = 'CUSTOMER'
ORDER BY e.Codigo;
GO

/* T10. Seguimiento de customers identificados en riesgo en el mes (C-4.1).
   Una fila por estudiante, aunque tenga varias evaluaciones o intervenciones.
   Se exige intervencion completada vinculada a una evaluacion medio/alto del
   mes, y mensaje saliente enviado, ambos posteriores a la identificacion.
   Se conserva la cohorte aunque el estudiante ya haya pasado a TURNED.
   Esperado: Bruno SI, Carla/Diego/Ines/Mateo NO. Hugo fue identificado hace 9 dias
   y puede integrar esta cohorte aunque su evaluacion actual ya este vencida.
*/
PRINT N'T10 | Seguimiento completado de la cohorte mensual';
DECLARE @Corte DATETIME2(0) = GETDATE();
DECLARE @Inicio DATE = DATEFROMPARTS(YEAR(@Corte), MONTH(@Corte), 1);
;WITH RiesgosMes AS (
    SELECT EvaluacionRiesgoId, EstudianteId, FechaEvaluacion
    FROM dbo.EvaluacionRiesgo
    WHERE Estado = 'CLASIFICADA' AND Nivel IN ('MEDIO','ALTO')
      AND FechaEvaluacion >= @Inicio AND FechaEvaluacion <= @Corte
)
SELECT e.Codigo, e.EtapaActual, COUNT(*) AS EvaluacionesConRiesgo,
       MIN(r.FechaEvaluacion) AS PrimeraIdentificacionMes,
       CASE WHEN EXISTS (
           SELECT 1 FROM RiesgosMes rm
           JOIN dbo.Intervencion i ON i.EvaluacionRiesgoId = rm.EvaluacionRiesgoId AND i.EstudianteId = rm.EstudianteId
           JOIN dbo.Mensaje m ON m.MensajeId = i.MensajeSeguimientoId
           JOIN dbo.Conversacion c ON c.ConversacionId = m.ConversacionId AND c.EstudianteId = rm.EstudianteId
           WHERE rm.EstudianteId = e.EstudianteId AND i.Estado = 'COMPLETADA'
             AND i.FechaCompletada >= rm.FechaEvaluacion AND i.FechaCompletada <= @Corte
             AND m.Direccion = 'SALIENTE' AND m.Estado IN ('ENVIADO','ENTREGADO')
             AND m.FechaEnvio >= rm.FechaEvaluacion AND m.FechaEnvio <= @Corte
       ) THEN 1 ELSE 0 END AS CumpleSeguimiento
FROM RiesgosMes r
JOIN dbo.Estudiante e ON e.EstudianteId = r.EstudianteId
GROUP BY e.EstudianteId, e.Codigo, e.EtapaActual
ORDER BY e.Codigo;
GO

/* T11. Propuestas presentadas este mes (C-6.1).
   ACEPTADA cuenta como aceptacion; APLICADA tambien, pero son estados distintos.
   Esperado: Mateo acepta y sigue en Ruta UNT; no se debe asumir Meta UNT activo.
   El plan del periodo de origen es el plan al presentar, no necesariamente el de hoy.
*/
PRINT N'T11 | Propuestas de cambio de plan';
DECLARE @Corte DATETIME2(0) = GETDATE();
DECLARE @Inicio DATE = DATEFROMPARTS(YEAR(@Corte), MONTH(@Corte), 1);
SELECT e.Codigo, pc.PropuestaCambioPlanId, pa.Nombre AS PlanDeOrigen,
       ps.Nombre AS PlanSugerido, pc.Necesidad, pc.SolicitadoPorCliente,
       pc.FechaPresentacion, pc.Estado, pc.FechaRespuesta, pc.Respuesta,
       pc.PeriodoAplicadoId, pc.FechaAplicacion,
       CASE WHEN pc.Estado IN ('ACEPTADA','APLICADA') AND pc.FechaRespuesta <= @Corte THEN 1 ELSE 0 END AS AceptadaAlCorte,
       CASE WHEN pc.Estado = 'APLICADA' AND pc.FechaAplicacion <= @Corte THEN 1 ELSE 0 END AS AplicadaAlCorte
FROM dbo.PropuestaCambioPlan pc
JOIN dbo.PeriodoServicio p ON p.PeriodoServicioId = pc.PeriodoActualId
JOIN dbo.Suscripcion s ON s.SuscripcionId = p.SuscripcionId
JOIN dbo.Estudiante e ON e.EstudianteId = s.EstudianteId
JOIN dbo.ModalidadPlan ma ON ma.ModalidadPlanId = p.ModalidadPlanId
JOIN dbo.PlanServicio pa ON pa.PlanServicioId = ma.PlanServicioId
JOIN dbo.ModalidadPlan ms ON ms.ModalidadPlanId = pc.ModalidadSugeridaId
JOIN dbo.PlanServicio ps ON ps.PlanServicioId = ms.PlanServicioId
WHERE pc.FechaPresentacion >= @Inicio AND pc.FechaPresentacion <= @Corte
ORDER BY e.Codigo;
GO

/* T12. Renovacion continua de suscripciones (C-5.1 / P-2.1), avance del mes.
   Denominador provisional: suscripciones con vencimientos YA OCURRIDOS este mes.
   Excluye periodos anulados o nunca habilitados. Cada suscripcion cuenta una vez.
   Si hay varios vencimientos en una suscripcion, se exige continuidad en todos.
   Renovacion exige enlace, Inicio = Fin anterior y habilitacion a tiempo.
   Esperado con demo recien cargada: Elena renueva; Jorge no. Lucia regreso
   despues de una interrupcion: su retorno no es renovacion de su suscripcion vieja.
*/
PRINT N'T12 | Renovaciones sin interrupcion';
DECLARE @Corte DATETIME2(0) = GETDATE();
DECLARE @Inicio DATE = DATEFROMPARTS(YEAR(@Corte), MONTH(@Corte), 1);
;WITH Vencimientos AS (
    SELECT p.SuscripcionId, p.PeriodoServicioId, p.Fin,
           CASE WHEN EXISTS (
               SELECT 1 FROM dbo.PeriodoServicio n
               WHERE n.PeriodoAnteriorId = p.PeriodoServicioId AND n.SuscripcionId = p.SuscripcionId
                 AND n.Tipo = 'RENOVACION' AND n.Inicio = p.Fin
                 AND n.FechaHabilitacion <= p.Fin AND n.EstadoAcceso <> 'ANULADO'
                 AND (n.BecaPorcentaje = 100 OR EXISTS (
                     SELECT 1 FROM dbo.Pago pg WHERE pg.PeriodoServicioId = n.PeriodoServicioId
                       AND pg.Tipo = 'COBRO' AND pg.Estado = 'CONFIRMADO'
                       AND pg.FechaConfirmacion <= p.Fin AND pg.ImportePEN = n.ImporteExigiblePEN
                 ))
           ) THEN 1 ELSE 0 END AS RenovadoSinInterrupcion
    FROM dbo.PeriodoServicio p
    WHERE p.Fin >= @Inicio AND p.Fin <= @Corte
      AND p.EstadoAcceso <> 'ANULADO' AND p.FechaHabilitacion <= p.Fin
)
SELECT e.Codigo, s.SuscripcionId, COUNT(*) AS VencimientosOcurridosMes,
       MIN(v.RenovadoSinInterrupcion) AS SuscripcionRenovadaSinInterrupcion
FROM Vencimientos v
JOIN dbo.Suscripcion s ON s.SuscripcionId = v.SuscripcionId
JOIN dbo.Estudiante e ON e.EstudianteId = s.EstudianteId
GROUP BY e.Codigo, s.SuscripcionId
ORDER BY e.Codigo, s.SuscripcionId;
GO

/* T13. Referidos registrados este mes y conversion por formulario valido (C-7).
   El pago no es necesario para pasar a LEAD. Una fila por referido.
   Esperado: Paula y Ruben pasan a LEAD; solo Ruben tiene referente fijado al pago.
*/
PRINT N'T13 | Referidos y conversion a LEAD';
DECLARE @Corte DATETIME2(0) = GETDATE();
DECLARE @Inicio DATE = DATEFROMPARTS(YEAR(@Corte), MONTH(@Corte), 1);
SELECT referente.Codigo AS Referente, r.ReferidoId, r.NombreReferido,
       referido.Codigo AS EstudianteReferido, r.FechaRegistroReferido,
       f.FechaFormularioValido, r.FechaSeleccionReferente, r.PrimerPagoId, r.FechaFijacion,
       CASE WHEN f.FechaFormularioValido IS NOT NULL THEN 1 ELSE 0 END AS ConvertidoALead,
       CASE WHEN r.PrimerPagoId IS NOT NULL THEN N'Atribucion fija' ELSE N'Aun sin atribucion por pago' END AS Situacion
FROM dbo.Referido r
JOIN dbo.Estudiante referente ON referente.EstudianteId = r.EstudianteReferenteId
LEFT JOIN dbo.Estudiante referido ON referido.EstudianteId = r.EstudianteReferidoId
OUTER APPLY (
    SELECT MIN(fc.FechaEnvio) AS FechaFormularioValido
    FROM dbo.FormularioContacto fc
    WHERE fc.ContactoId = referido.ContactoId AND fc.Valido = 1
      AND fc.FechaEnvio >= r.FechaRegistroReferido AND fc.FechaEnvio <= @Corte
) f
WHERE r.FechaRegistroReferido >= @Inicio AND r.FechaRegistroReferido <= @Corte
ORDER BY r.ReferidoId;
GO

/* T14. Cuando ingreso el contacto como LEAD y cuando se guardaron sus datos?
   El primer formulario VALIDO determina el ingreso. Los reenvios no lo reinician.
   Un contacto sin formulario valido tiene ingreso desconocido: no se lo inventa
   usando FechaRegistro. Estudiante y apoderado tienen sus propios formularios.
   Esperado: 16 contactos, con su primer formulario valido y fecha de ingreso.
*/
PRINT N'T14 | Primer formulario valido y fecha de registro';
SELECT c.ContactoId, c.NombreCompleto, e.Codigo AS CodigoEstudiante,
       f.FormularioContactoId, f.FechaEnvio AS FechaIngresoLead,
       c.FechaRegistro AS FechaRegistroContacto,
       f.FechaRegistro AS FechaRegistroFormulario,
       CASE WHEN f.FormularioContactoId IS NULL THEN N'Sin formulario valido registrado'
            ELSE N'Ingreso sustentado en formulario valido' END AS Situacion
FROM dbo.Contacto c
LEFT JOIN dbo.Estudiante e ON e.ContactoId = c.ContactoId
OUTER APPLY (
    SELECT TOP (1) fc.FormularioContactoId, fc.FechaEnvio, fc.FechaRegistro
    FROM dbo.FormularioContacto fc
    WHERE fc.ContactoId = c.ContactoId AND fc.Valido = 1
    ORDER BY fc.FechaEnvio, fc.FormularioContactoId
) f
ORDER BY c.ContactoId;
GO

-- ============================================================================
-- PARTE 2. CONSULTAS QUE NECESITARIA EL FUTURO AGENTE
-- No implementan un agente ni autorizan ejecucion automatica de acciones.
-- ============================================================================

/* A01. Frecuencia y evolucion del uso: dos ventanas de siete dias (C-3).
   Se distingue ACCESO del resto de actividades: ultimo login no es ultimo uso.
   Diferencia de eventos es un dato, no un nuevo umbral de riesgo.
   Una suscripcion con menos de 14 dias no tiene dos ventanas completas de servicio.
   Los eventos se limitan al episodio actual para no atribuir uso previo al retorno.
*/
PRINT N'A01 | Evolucion del uso';
DECLARE @Corte DATETIME2(0) = GETDATE();
DECLARE @MedioHoras INT, @AltoHoras INT;
SELECT TOP(1) @MedioHoras=InactividadMediaHoras,@AltoHoras=InactividadAltaHoras FROM dbo.PoliticaRiesgo ORDER BY Numero DESC;
SELECT e.Codigo, servicio.InicioEpisodio, u.UltimaActividad,
       u.EventosSemanaAnterior, u.EventosSemanaActual,
       u.EventosSemanaActual - u.EventosSemanaAnterior AS DiferenciaEventos,
       u.AccesosSemanaActual, u.DiasActivosSemanaActual,
       CASE WHEN servicio.InicioEpisodio IS NULL THEN N'Sin episodio vigente'
            WHEN servicio.InicioEpisodio > DATEADD(DAY, -14, @Corte) THEN N'Exposicion insuficiente para comparar 14 dias'
            ELSE N'Dos ventanas completas de servicio' END AS ComparabilidadTemporal,
       CASE WHEN u.UltimaActividad IS NULL THEN N'SIN DATOS DE USO'
            WHEN u.UltimaActividad <= DATEADD(HOUR, -@AltoHoras, @Corte) THEN N'ALTO'
            WHEN u.UltimaActividad <= DATEADD(HOUR, -@MedioHoras, @Corte) THEN N'MEDIO'
            ELSE N'Sin umbral de inactividad' END AS SenalSoloPorInactividad
FROM dbo.Estudiante e
OUTER APPLY (
    SELECT MIN(p.Inicio) AS InicioEpisodio
    FROM dbo.Suscripcion s
    JOIN dbo.PeriodoServicio p ON p.SuscripcionId = s.SuscripcionId
    WHERE s.EstudianteId = e.EstudianteId AND s.Estado = 'VIGENTE'
      AND p.EstadoAcceso <> 'ANULADO' AND p.FechaHabilitacion <= @Corte AND p.Inicio <= @Corte
) servicio
OUTER APPLY (
    SELECT MAX(FechaEvento) AS UltimaActividad,
           COUNT(CASE WHEN FechaEvento >= DATEADD(DAY, -14, @Corte) AND FechaEvento < DATEADD(DAY, -7, @Corte) THEN 1 END) AS EventosSemanaAnterior,
           COUNT(CASE WHEN FechaEvento >= DATEADD(DAY, -7, @Corte) THEN 1 END) AS EventosSemanaActual,
           COUNT(CASE WHEN FechaEvento >= DATEADD(DAY, -7, @Corte) AND Tipo = 'ACCESO' THEN 1 END) AS AccesosSemanaActual,
           COUNT(DISTINCT CASE WHEN FechaEvento >= DATEADD(DAY, -7, @Corte) THEN CONVERT(DATE, FechaEvento) END) AS DiasActivosSemanaActual
    FROM dbo.EventoUso
    WHERE EstudianteId = e.EstudianteId AND FechaEvento >= servicio.InicioEpisodio AND FechaEvento <= @Corte
) u
WHERE e.EtapaActual = 'CUSTOMER'
ORDER BY e.Codigo;
GO

/* A02. Que tareas necesitan atencion antes de redactar un recordatorio?
   Cambiar C001 por C003/C007/C012. No devuelve tareas de rutas anteriores.
   Incluye dificultad del recurso mediante su tema, sin multiplicar la actividad.
   No asegura que no se haya recordado ESA tarea: falta el enlace indicado en R2.
   Leer tambien A04 para permisos y seguimiento previo antes de proponer contacto.
*/
PRINT N'A02 | Actividades pendientes y dificultades';
DECLARE @Codigo VARCHAR(20) = 'C001';
DECLARE @Corte DATETIME2(0) = GETDATE();
SELECT e.Codigo, a.ActividadRutaId, a.Orden, cu.Nombre AS Curso,
       t.Nombre AS Tema, rec.Titulo, a.Estado, a.FechaPlanificada, a.FechaLimite,
       CASE WHEN a.FechaLimite < @Corte THEN N'Atrasada' ELSE N'En plazo' END AS Situacion,
       dif.Descripcion AS DificultadConocida, dif.Estado AS EstadoDificultad
FROM dbo.Estudiante e
JOIN dbo.RutaEstudio r ON r.EstudianteId = e.EstudianteId AND r.Vigente = 1
JOIN dbo.ActividadRuta a ON a.RutaEstudioId = r.RutaEstudioId
JOIN dbo.RecursoAcademico rec ON rec.RecursoAcademicoId = a.RecursoAcademicoId
JOIN dbo.Tema t ON t.TemaId = rec.TemaId
JOIN dbo.Curso cu ON cu.CursoId = t.CursoId
OUTER APPLY (
    SELECT TOP (1) d.Descripcion, d.Estado
    FROM dbo.DificultadAcademica d
    WHERE d.EstudianteId = e.EstudianteId AND d.TemaId = t.TemaId
      AND d.Estado <> 'SUPERADA' AND d.FechaIdentificacion <= @Corte
    ORDER BY d.FechaIdentificacion DESC, d.DificultadAcademicaId DESC
) dif
WHERE e.Codigo = @Codigo AND e.EtapaActual = 'CUSTOMER'
  AND a.Estado IN ('PENDIENTE','EN_CURSO') AND a.FechaPlanificada <= @Corte
ORDER BY a.FechaLimite, a.Orden;
GO

/* A03. Con que evidencia se justifico el ultimo riesgo de un alumno?
   Probar C003/C004/C009/C012/C007. No convierte estrellas automaticamente en
   insatisfaccion: se muestra comentario y señal interpretada si existe.
   Con PENDIENTE sin señales se conserva la fila de evaluacion.
   Las tablas de evidencia muestran su contenido actual; aun pueden modificarse.
*/
PRINT N'A03 | Evidencias de la ultima evaluacion';
DECLARE @Codigo VARCHAR(20) = 'C003';
DECLARE @Corte DATETIME2(0) = GETDATE();
SELECT e.Codigo, er.EvaluacionRiesgoId, er.FechaEvaluacion, er.Estado,
       er.Nivel AS RiesgoGuardado, er.Motivo, sr.SenalRiesgoId,
       sr.Codigo AS TipoSenal, sr.Nivel AS NivelSenal, sr.FechaObservacion, sr.Detalle,
       sr.EventoUsoId, u.FechaEvento AS UsoObservado,
       sr.CasoAtencionId, ca.Estado AS EstadoActualCaso, ca.FechaAperturaOriginal,
       sr.ValoracionId, v.Estrellas, v.Comentario,
       sr.MensajeId, m.IntencionExpresa, m.Contenido,
       sr.DificultadAcademicaId, d.Descripcion AS Dificultad
FROM dbo.Estudiante e
OUTER APPLY (
    SELECT TOP (1) r.EvaluacionRiesgoId, r.FechaEvaluacion, r.Estado, r.Nivel, r.Motivo
    FROM dbo.EvaluacionRiesgo r
    WHERE r.EstudianteId = e.EstudianteId AND r.FechaEvaluacion <= @Corte
    ORDER BY r.FechaEvaluacion DESC, r.EvaluacionRiesgoId DESC
) er
LEFT JOIN dbo.SenalRiesgo sr ON sr.EvaluacionRiesgoId = er.EvaluacionRiesgoId
LEFT JOIN dbo.EventoUso u ON u.EventoUsoId = sr.EventoUsoId
LEFT JOIN dbo.CasoAtencion ca ON ca.CasoAtencionId = sr.CasoAtencionId
LEFT JOIN dbo.Valoracion v ON v.ValoracionId = sr.ValoracionId
LEFT JOIN dbo.Mensaje m ON m.MensajeId = sr.MensajeId
LEFT JOIN dbo.DificultadAcademica d ON d.DificultadAcademicaId = sr.DificultadAcademicaId
WHERE e.Codigo = @Codigo
ORDER BY sr.SenalRiesgoId;
GO

/* A04. Preparar una decision de seguimiento con plan, permiso y accion previa.
   Una fila por alumno y canal autorizado/denegado de finalidad ACADEMICA.
   'Revisar contexto' NO equivale a permiso final de envio: leer conversaciones
   (segundo resultado), reclamos, peticiones de no contacto y frecuencia previa.
   No hay campo estructurado de no contacto GLOBAL: Ines lo dice en texto.
   No se asume que autorizar PLATAFORMA permite ignorar esa peticion.
   Esperado: Bruno/Mateo requieren soporte por plan; Hugo reevaluacion;
   Ines pide derivacion humana; varias acciones ya existen y no deben duplicarse.
*/
PRINT N'A04 | Contexto para decidir seguimiento';
DECLARE @Corte DATETIME2(0) = GETDATE();
DECLARE @Codigo VARCHAR(20) = 'C009'; -- segundo resultado: conversacion a revisar
SELECT e.Codigo, pl.Nombre AS PlanActual, er.EvaluacionRiesgoId, er.Nivel,
       ac.Canal, ac.Autorizado, ac.FechaDecision,
       previa.IntervencionId AS UltimaIntervencionId, previa.Estado AS EstadoIntervencion,
       previa.Tipo AS TipoIntervencion, previa.RequiereAprobacion,
       previa.AprobadoPorId, previa.FechaAprobacion,
       previa.FechaCreacion, previa.FechaCompletada, previa.Resultado,
       msg.FechaEnvio AS UltimoMensajeSaliente,
       CASE WHEN p.PeriodoServicioId IS NULL THEN N'Revisar servicio vigente'
            WHEN er.EvaluacionRiesgoId IS NULL OR er.Estado = 'PENDIENTE'
              OR er.FechaEvaluacion < DATEADD(DAY, -reglasEvaluadas.VigenciaDias, @Corte)
              OR er.VersionReglas<>(SELECT TOP(1) VersionReglas FROM dbo.PoliticaRiesgo ORDER BY Numero DESC) THEN N'Reevaluar riesgo'
            WHEN er.Nivel = 'BAJO' THEN N'Sin seguimiento por riesgo medio/alto'
            WHEN NOT EXISTS (
                SELECT 1 FROM dbo.PlanPrestacion pp JOIN dbo.Prestacion pr ON pr.PrestacionId = pp.PrestacionId
                WHERE pp.PlanServicioId = pl.PlanServicioId AND pr.Codigo = 'SEGUIMIENTO_IA'
            ) THEN N'Atencion humana: plan sin seguimiento IA'
            WHEN ac.Autorizado IS NULL OR ac.Autorizado = 0 OR ac.FechaDecision > @Corte THEN N'Canal sin autorizacion actual'
            WHEN previa.RequiereAprobacion = 1 AND previa.Estado IN ('PROPUESTA','PROGRAMADA','EN_CURSO')
              AND (previa.AprobadoPorId IS NULL OR previa.FechaAprobacion IS NULL) THEN N'Derivar al dueño: falta aprobacion'
            WHEN EXISTS (
                SELECT 1 FROM dbo.Intervencion i WHERE i.EstudianteId = e.EstudianteId
                  AND i.FechaCreacion <= @Corte AND i.Estado IN ('PROPUESTA','PROGRAMADA','EN_CURSO')
            ) THEN N'Revisar intervencion ya abierta; no duplicar'
            WHEN previa.EvaluacionRiesgoId = er.EvaluacionRiesgoId AND previa.Estado = 'COMPLETADA' THEN N'Revisar resultado del seguimiento completado'
            ELSE N'Revisar contexto y frecuencia antes de proponer accion' END AS SiguienteRevision
FROM dbo.Estudiante e
LEFT JOIN dbo.Suscripcion s ON s.EstudianteId = e.EstudianteId AND s.Estado = 'VIGENTE'
LEFT JOIN dbo.PeriodoServicio p ON p.SuscripcionId = s.SuscripcionId
 AND p.Inicio <= @Corte AND p.Fin > @Corte AND p.EstadoAcceso IN ('HABILITADO','CON_INCIDENCIA')
LEFT JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId = p.ModalidadPlanId
LEFT JOIN dbo.PlanServicio pl ON pl.PlanServicioId = mp.PlanServicioId
LEFT JOIN dbo.AutorizacionContacto ac ON ac.ContactoId = e.ContactoId AND ac.Finalidad = 'ACADEMICA'
OUTER APPLY (
    SELECT TOP (1) r.EvaluacionRiesgoId, r.Estado, r.Nivel, r.FechaEvaluacion, r.VersionReglas
    FROM dbo.EvaluacionRiesgo r WHERE r.EstudianteId = e.EstudianteId AND r.FechaEvaluacion <= @Corte
    ORDER BY r.FechaEvaluacion DESC, r.EvaluacionRiesgoId DESC
) er
LEFT JOIN dbo.PoliticaRiesgo reglasEvaluadas ON reglasEvaluadas.VersionReglas=er.VersionReglas
OUTER APPLY (
    SELECT TOP (1) i.IntervencionId, i.EvaluacionRiesgoId, i.Estado, i.Tipo,
           i.RequiereAprobacion, i.AprobadoPorId, i.FechaAprobacion,
           i.FechaCreacion, i.FechaCompletada, i.Resultado
    FROM dbo.Intervencion i WHERE i.EstudianteId = e.EstudianteId AND i.FechaCreacion <= @Corte
    ORDER BY i.FechaCreacion DESC, i.IntervencionId DESC
) previa
OUTER APPLY (
    SELECT MAX(m.FechaEnvio) AS FechaEnvio FROM dbo.Mensaje m
    JOIN dbo.Conversacion c ON c.ConversacionId = m.ConversacionId
    WHERE c.EstudianteId = e.EstudianteId AND m.Direccion = 'SALIENTE'
      AND m.Estado IN ('ENVIADO','ENTREGADO') AND m.FechaEnvio <= @Corte
) msg
WHERE e.EtapaActual = 'CUSTOMER'
ORDER BY CASE er.Nivel WHEN 'ALTO' THEN 1 WHEN 'MEDIO' THEN 2 ELSE 3 END, e.Codigo, ac.Canal;
SELECT e.Codigo, c.Canal, c.Finalidad, m.MensajeId, m.Direccion, m.Emisor,
       m.Estado, m.FechaEnvio, m.FechaRecepcion, m.IntencionExpresa, m.Contenido
FROM dbo.Estudiante e
JOIN dbo.Conversacion c ON c.EstudianteId = e.EstudianteId
JOIN dbo.Mensaje m ON m.ConversacionId = c.ConversacionId
WHERE e.Codigo = @Codigo AND COALESCE(m.FechaRecepcion, m.FechaEnvio, m.FechaProgramada) <= @Corte
ORDER BY COALESCE(m.FechaRecepcion, m.FechaEnvio, m.FechaProgramada), m.MensajeId;
GO

/* A05. Que apoderado tiene derecho a reportes y por que canal?
   Vinculo familiar y autorizacion NO reemplazan la prestacion del plan.
   Se muestran los bloqueados para poder contrastar Ana con Carla/Elena.
   No crea cuentas ni comprueba autenticacion; consulta requisitos de negocio.
*/
PRINT N'A05 | Reportes para apoderados';
DECLARE @Corte DATETIME2(0) = GETDATE();
SELECT e.Codigo, cp.NombreCompleto AS Apoderado, e.Parentesco,
       pl.Nombre AS PlanActual, ac.Canal, ac.Autorizado,
       CASE WHEN EXISTS (
           SELECT 1 FROM dbo.PlanPrestacion pp JOIN dbo.Prestacion pr ON pr.PrestacionId = pp.PrestacionId
           WHERE pp.PlanServicioId = pl.PlanServicioId AND pr.Codigo = 'REPORTES_APODERADO'
       ) THEN 1 ELSE 0 END AS PlanPermiteCuentaApoderado,
       CASE WHEN p.PeriodoServicioId IS NULL THEN N'Sin servicio vigente'
            WHEN NOT EXISTS (
                SELECT 1 FROM dbo.PlanPrestacion pp JOIN dbo.Prestacion pr ON pr.PrestacionId = pp.PrestacionId
                WHERE pp.PlanServicioId = pl.PlanServicioId AND pr.Codigo = 'REPORTES_APODERADO'
            ) THEN N'Plan no incluye cuenta de apoderado'
            WHEN ac.Autorizado = 1 AND ac.FechaDecision <= @Corte THEN N'Requisitos de plan y canal cumplidos; revisar contexto'
            ELSE N'Sin autorizacion para enviar reportes por este canal' END AS Situacion
FROM dbo.Estudiante e
JOIN dbo.Apoderado ap ON ap.ApoderadoId = e.ApoderadoId
JOIN dbo.Contacto cp ON cp.ContactoId = ap.ContactoId
LEFT JOIN dbo.Suscripcion s ON s.EstudianteId = e.EstudianteId AND s.Estado = 'VIGENTE'
LEFT JOIN dbo.PeriodoServicio p ON p.SuscripcionId = s.SuscripcionId
 AND p.Inicio <= @Corte AND p.Fin > @Corte AND p.EstadoAcceso IN ('HABILITADO','CON_INCIDENCIA')
LEFT JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId = p.ModalidadPlanId
LEFT JOIN dbo.PlanServicio pl ON pl.PlanServicioId = mp.PlanServicioId
LEFT JOIN dbo.AutorizacionContacto ac ON ac.ContactoId = ap.ContactoId AND ac.Finalidad = 'REPORTES'
WHERE e.EtapaActual = 'CUSTOMER'
ORDER BY e.Codigo, ac.Canal;
GO

/* A06. Detectar incoherencias antes de usar datos para decidir.
   Dos resultados. Esperado: CERO filas en ambos con la demo sin alterar.
   Son diagnosticos de lectura; no reemplazan las pruebas de escritura del 03.
   El primero contrasta etapa con servicio habilitado. El segundo contrasta nivel
   guardado con MAX de sus señales. No valida por si solo toda regla de riesgo:
   si alguien cambia señal y evaluacion a BAJO a la vez, seguiria coincidiendo.
*/
PRINT N'A06 | Diagnostico de etapa y clasificacion';
DECLARE @Corte DATETIME2(0) = GETDATE();
SELECT e.Codigo, e.EtapaActual, N'Etapa y servicio habilitado no coinciden' AS Problema
FROM dbo.Estudiante e
CROSS APPLY (
    SELECT COUNT(*) AS ServiciosVigentes
    FROM dbo.Suscripcion s JOIN dbo.PeriodoServicio p ON p.SuscripcionId = s.SuscripcionId
    WHERE s.EstudianteId = e.EstudianteId AND s.Estado = 'VIGENTE'
      AND p.Inicio <= @Corte AND p.Fin > @Corte AND p.EstadoAcceso IN ('HABILITADO','CON_INCIDENCIA')
) x
WHERE (e.EtapaActual = 'CUSTOMER' AND x.ServiciosVigentes = 0)
   OR (e.EtapaActual <> 'CUSTOMER' AND x.ServiciosVigentes > 0)
   OR x.ServiciosVigentes > 1;
SELECT e.Codigo, er.EvaluacionRiesgoId, er.Estado, er.Nivel,
       x.MaxNivelSenales, N'Revisar coherencia entre clasificacion y señales' AS Problema
FROM dbo.EvaluacionRiesgo er
JOIN dbo.Estudiante e ON e.EstudianteId = er.EstudianteId
OUTER APPLY (
    SELECT MAX(CASE sr.Nivel WHEN 'ALTO' THEN 3 WHEN 'MEDIO' THEN 2 WHEN 'BAJO' THEN 1 END) AS MaxNivelSenales
    FROM dbo.SenalRiesgo sr WHERE sr.EvaluacionRiesgoId = er.EvaluacionRiesgoId
) x
WHERE (er.Estado = 'CLASIFICADA' AND (x.MaxNivelSenales IS NULL OR
       x.MaxNivelSenales <> CASE er.Nivel WHEN 'ALTO' THEN 3 WHEN 'MEDIO' THEN 2 WHEN 'BAJO' THEN 1 END))
   OR (er.Estado = 'PENDIENTE' AND er.Nivel IS NOT NULL)
ORDER BY e.Codigo, er.FechaEvaluacion;
GO

-- M07. Avance del temario UNT 2027, separado del rendimiento en pruebas.
SELECT e.Codigo,c.Curso,COUNT(*) Temas,COUNT(CASE WHEN p.Estado='COMPLETADA' THEN 1 END) Completados
FROM dbo.ProgresoTemaUNT p JOIN dbo.ContenidoUNT c ON c.ContenidoId=p.ContenidoId
JOIN dbo.Estudiante e ON e.EstudianteId=p.EstudianteId GROUP BY e.Codigo,c.Curso;
GO
SELECT ConsultaId,EstudianteId,Rol,Canal,Pregunta,Estado FROM dbo.ConsultaDueno WHERE Estado='PENDIENTE';
GO
