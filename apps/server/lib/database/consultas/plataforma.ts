// Consultas del dashboard, temario y canal local. Los parámetros se vinculan desde servicios/plataforma.ts.

export const CONSULTAR_TEMARIO = `
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

export const LISTAR_ESTUDIANTES = `
SELECT
  e.EstudianteId id,
  e.Codigo codigo,
  c.NombreCompleto nombre,
  e.EtapaActual etapa
FROM
  dbo.Estudiante e
  JOIN dbo.Contacto c ON c.ContactoId = e.ContactoId
ORDER BY
  e.Codigo
`;

export const LISTAR_CONSULTAS_DUENO = `
SELECT
  *
FROM
  dbo.ConsultaDueno
ORDER BY
  ConsultaId DESC
`;

export const BUSCAR_DESTINATARIO = `
SELECT
  e.ContactoId estudiante,
  a.ContactoId apoderado
FROM
  dbo.Estudiante e
  LEFT JOIN dbo.Apoderado a ON a.ApoderadoId = e.ApoderadoId
WHERE
  e.EstudianteId = @e
`;

export const BUSCAR_BLOQUEO_CONTACTO = `
SELECT
  1
FROM
  dbo.ConsultaDueno
WHERE
  EstudianteId = @e
  AND Pregunta LIKE 'NO_CONTACTO:%'
`;

export const BUSCAR_AUTORIZACION = `
SELECT
  1 ok
FROM
  dbo.AutorizacionContacto
WHERE
  ContactoId = @c
  AND Finalidad = @f
  AND Canal = 'PLATAFORMA'
  AND Autorizado = 1
  AND FechaDecision <= GETDATE()
`;

export const GUARDAR_MENSAJE_LOCAL = `
INSERT
  dbo.MensajeCanalLocal (
    EstudianteId,
    ContactoId,
    Rol,
    Canal,
    Direccion,
    Contenido,
    ConsultaId
  ) OUTPUT INSERTED.MensajeLocalId id
VALUES
  (@e, @c, @rol, @canal, @d, @texto, @q)
`;

export const LEER_BANDEJA = `
UPDATE dbo.MensajeCanalLocal
SET
  FechaEntrega = GETDATE()
WHERE
  EstudianteId = @e
  AND ContactoId = @c
  AND Canal = @canal
  AND Direccion = 'SALIENTE'
  AND FechaEntrega IS NULL
  AND @ack = 1;

SELECT
  *
FROM
  dbo.MensajeCanalLocal
WHERE
  EstudianteId = @e
  AND ContactoId = @c
  AND Canal = @canal
ORDER BY
  MensajeLocalId
`;

export const GUARDAR_CONSULTA_DUENO = `
INSERT
  dbo.ConsultaDueno (EstudianteId, ContactoId, Rol, Canal, Pregunta) OUTPUT INSERTED.ConsultaId id
VALUES
  (@e, @c, @r, @canal, @p)
`;
