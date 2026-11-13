// Lecturas del diagnóstico. El orden de los SELECT coincide con los recordsets de academico/diagnostico.ts.

export const CONSULTAR_DIAGNOSTICO = `
DECLARE @c DATETIME2(0) = GETDATE();

SELECT
  @c AS corte;

SELECT
  RutaEstudioId id,
  VersionNumero version,
  Vigente vigente
FROM
  dbo.RutaEstudio
WHERE
  EstudianteId = @id;

SELECT
  a.ActividadRutaId id,
  a.RutaEstudioId rutaId,
  rc.Titulo titulo,
  a.Estado estado,
  a.FechaPlanificada planificada,
  a.FechaLimite limite,
  a.FechaCompletada completada
FROM
  dbo.ActividadRuta a
  JOIN dbo.RutaEstudio r ON r.RutaEstudioId = a.RutaEstudioId
  JOIN dbo.RecursoAcademico rc ON rc.RecursoAcademicoId = a.RecursoAcademicoId
WHERE
  r.EstudianteId = @id
ORDER BY
  r.VersionNumero,
  a.Orden;

SELECT
  i.IntentoEvaluacionId id,
  e.GrupoComparabilidadId grupoId,
  g.Codigo grupo,
  g.Alcance alcance,
  g.Escala escala,
  g.Dificultad dificultad,
  i.FechaFin fecha,
  i.Aciertos aciertos,
  i.TotalPreguntas total
FROM
  dbo.IntentoEvaluacion i
  JOIN dbo.Evaluacion e ON e.EvaluacionId = i.EvaluacionId
  LEFT JOIN dbo.GrupoComparabilidad g ON g.GrupoComparabilidadId = e.GrupoComparabilidadId
WHERE
  i.EstudianteId = @id
  AND i.FechaFin <= @c;

SELECT
  TOP (1) EventoUsoId id,
  FechaEvento fecha
FROM
  dbo.EventoUso
WHERE
  EstudianteId = @id
  AND FechaEvento <= @c
ORDER BY
  FechaEvento DESC,
  EventoUsoId DESC;

SELECT
  COUNT(
    CASE
      WHEN FechaEvento >= DATEADD(DAY, -7, @c) THEN 1
    END
  ) recientes,
  COUNT(
    CASE
      WHEN FechaEvento < DATEADD(DAY, -7, @c) THEN 1
    END
  ) anteriores
FROM
  dbo.EventoUso
WHERE
  EstudianteId = @id
  AND FechaEvento >= DATEADD(DAY, -14, @c)
  AND FechaEvento <= @c;

SELECT
  CasoAtencionId id,
  Tipo tipo,
  Ambito ambito,
  Estado estado,
  FechaAperturaOriginal apertura,
  Descripcion descripcion
FROM
  dbo.CasoAtencion
WHERE
  EstudianteId = @id
  AND FechaAperturaOriginal <= @c;

SELECT
  DificultadAcademicaId id,
  FechaIdentificacion fecha,
  Estado estado,
  Descripcion descripcion
FROM
  dbo.DificultadAcademica
WHERE
  EstudianteId = @id
  AND FechaIdentificacion <= @c;

SELECT
  m.MensajeId id,
  m.FechaRecepcion fecha,
  m.Contenido contenido,
  m.IntencionExpresa intencion
FROM
  dbo.Mensaje m
  JOIN dbo.Conversacion c ON c.ConversacionId = m.ConversacionId
WHERE
  c.EstudianteId = @id
  AND m.Direccion = 'ENTRANTE'
  AND m.FechaRecepcion <= @c
ORDER BY
  m.FechaRecepcion,
  m.MensajeId;

SELECT
  v.ValoracionId id,
  v.FechaRespuesta fecha,
  v.Estrellas estrellas,
  v.Comentario comentario,
  a.Nombre aspecto
FROM
  dbo.Valoracion v
  JOIN dbo.SolicitudValoracion s ON s.SolicitudValoracionId = v.SolicitudValoracionId
  JOIN dbo.AspectoValoracion a ON a.AspectoValoracionId = s.AspectoValoracionId
WHERE
  s.EstudianteId = @id
  AND v.Valida = 1
  AND v.FechaRespuesta <= @c
ORDER BY v.ValoracionId;

SELECT
  a.Canal canal,
  a.Autorizado autorizado,
  a.FechaDecision fecha,
  a.Evidencia evidencia
FROM
  dbo.AutorizacionContacto a
  JOIN dbo.Estudiante e ON e.ContactoId = a.ContactoId
WHERE
  e.EstudianteId = @id
  AND a.Finalidad = 'ACADEMICA'
  AND a.FechaDecision <= @c;

SELECT
  IntervencionId id,
  Tipo tipo,
  Estado estado,
  Recomendacion recomendacion,
  Resultado resultado,
  FechaCreacion fecha,
  EvaluacionRiesgoId evaluacionId,
  RequiereAprobacion requiereAprobacion
FROM
  dbo.Intervencion
WHERE
  EstudianteId = @id
ORDER BY
  FechaCreacion DESC,
  IntervencionId DESC;

SELECT
  rv.RevisionRutaId id,
  rv.RutaEstudioId rutaId,
  rv.Motivo motivo,
  rv.Estado estado,
  rv.Recomendacion recomendacion,
  rv.Resultado resultado
FROM
  dbo.RevisionRuta rv
  JOIN dbo.RutaEstudio r ON r.RutaEstudioId = rv.RutaEstudioId
WHERE
  r.EstudianteId = @id;

SELECT
  TOP (1) EvaluacionRiesgoId id,
  FechaEvaluacion fecha,
  Estado estado,
  Nivel nivel,
  VersionReglas versionReglas
FROM
  dbo.EvaluacionRiesgo
WHERE
  EstudianteId = @id
  AND FechaEvaluacion <= @c
ORDER BY
  FechaEvaluacion DESC,
  EvaluacionRiesgoId DESC;
`;

export const CONSULTAR_TEMARIO_DIAGNOSTICO = `
SELECT
  c.ContenidoId id,
  c.Curso curso,
  c.Tema tema,
  c.Subtemas subtemas,
  COALESCE(p.Estado, 'PENDIENTE') estado,
  p.Origen origen
FROM
  dbo.ContenidoUNT c
  LEFT JOIN dbo.ProgresoTemaUNT p ON p.ContenidoId = c.ContenidoId
  AND p.EstudianteId = @e
ORDER BY
  c.ContenidoId
`;
