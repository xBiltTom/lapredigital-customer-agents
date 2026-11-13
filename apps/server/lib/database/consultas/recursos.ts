// Proyecciones permitidas al agente. Los filtros se añaden en servicios/consultas.ts; aquí no entran valores del usuario.

export const consultasRecursos = {
  PAGOS: `
SELECT
  p.PagoId id,
  s.EstudianteId estudianteId,
  p.Tipo tipo,
  p.Estado estado,
  p.ImportePEN importePEN,
  p.Moneda moneda,
  p.Canal canal,
  COALESCE(p.FechaConfirmacion, p.FechaOperacion) fecha,
  p.FechaOperacion fechaOperacion,
  p.FechaConfirmacion confirmacion,
  p.PagoOriginalId pagoOriginalId,
  p.PagadorContactoId pagadorContactoId,
  pl.Nombre descripcion,
  ps.Inicio inicioPeriodo,
  ps.Fin finPeriodo
FROM
  dbo.Pago p
  JOIN dbo.PeriodoServicio ps ON ps.PeriodoServicioId = p.PeriodoServicioId
  JOIN dbo.Suscripcion s ON s.SuscripcionId = ps.SuscripcionId
  JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId = ps.ModalidadPlanId
  JOIN dbo.PlanServicio pl ON pl.PlanServicioId = mp.PlanServicioId
`,
  SERVICIO: `
SELECT
  ps.PeriodoServicioId id,
  s.EstudianteId estudianteId,
  ps.Tipo tipo,
  ps.EstadoAcceso estado,
  ps.ImporteExigiblePEN importePEN,
  ps.Inicio fecha,
  ps.Fin fin,
  ps.BecaPorcentaje becaPorcentaje,
  ps.PrecioAcordadoPEN precioAcordadoPEN,
  pl.Nombre descripcion,
  s.RenovacionAutomatica renovacionAutomatica,
  s.Estado estadoSuscripcion,
  s.SuscripcionId suscripcionId
FROM
  dbo.PeriodoServicio ps
  JOIN dbo.Suscripcion s ON s.SuscripcionId = ps.SuscripcionId
  JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId = ps.ModalidadPlanId
  JOIN dbo.PlanServicio pl ON pl.PlanServicioId = mp.PlanServicioId
`,
  ACTIVIDADES: `
SELECT
  a.ActividadRutaId id,
  r.EstudianteId estudianteId,
  a.Estado estado,
  rc.Tipo tipo,
  rc.Titulo descripcion,
  a.FechaPlanificada fecha,
  a.FechaLimite limite,
  a.FechaCompletada completada,
  r.VersionNumero versionRuta,
  r.Vigente rutaVigente
FROM
  dbo.ActividadRuta a
  JOIN dbo.RutaEstudio r ON r.RutaEstudioId = a.RutaEstudioId
  JOIN dbo.RecursoAcademico rc ON rc.RecursoAcademicoId = a.RecursoAcademicoId
`,
  EVALUACIONES: `
SELECT
  i.IntentoEvaluacionId id,
  i.EstudianteId estudianteId,
  e.Tipo tipo,
  e.Nombre descripcion,
  i.FechaFin fecha,
  i.Aciertos aciertos,
  i.TotalPreguntas totalPreguntas,
  CONVERT(
    DECIMAL(6, 2),
    100.0 * i.Aciertos / i.TotalPreguntas
  ) porcentaje,
  g.Codigo grupoComparabilidad,
  g.Alcance alcance,
  g.Escala escala,
  g.Dificultad dificultad
FROM
  dbo.IntentoEvaluacion i
  JOIN dbo.Evaluacion e ON e.EvaluacionId = i.EvaluacionId
  LEFT JOIN dbo.GrupoComparabilidad g ON g.GrupoComparabilidadId = e.GrupoComparabilidadId
`,
  INCIDENCIAS: `
SELECT
  CasoAtencionId id,
  EstudianteId estudianteId,
  Tipo tipo,
  Estado estado,
  Descripcion descripcion,
  FechaAperturaOriginal fecha,
  Ambito ambito,
  FechaLimite limite,
  FechaResolucionDefinitiva resolucionFecha,
  Resolucion resolucion
FROM
  dbo.CasoAtencion
`,
  VALORACIONES: `
SELECT
  v.ValoracionId id,
  s.EstudianteId estudianteId,
  a.Nombre tipo,
  COALESCE(v.Comentario, N'Sin comentario') descripcion,
  v.FechaRespuesta fecha,
  v.Estrellas estrellas
FROM
  dbo.Valoracion v
  JOIN dbo.SolicitudValoracion s ON s.SolicitudValoracionId = v.SolicitudValoracionId
  JOIN dbo.AspectoValoracion a ON a.AspectoValoracionId = s.AspectoValoracionId
WHERE
  v.Valida = 1
`,
};
