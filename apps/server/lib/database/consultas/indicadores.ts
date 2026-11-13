// Corte mensual y numerador/denominador de C-2.1, C-2.2, C-2.3 y C-6.1, en ese orden.

// Fragmento compartido: el llamador fija @c y @inicio para todo su lote.
export const CONSULTAR_INDICADORES_MES = `
SELECT
  @inicio inicio,
  @c corte;

SELECT
  COALESCE(SUM(CONVERT(INT, Estrellas)), 0) numerador,
  COUNT(*) denominador
FROM
  dbo.Valoracion
WHERE
  Valida = 1
  AND FechaRespuesta >= @inicio
  AND FechaRespuesta <= @c;

SELECT
  COUNT(v.ValoracionId) numerador,
  COUNT(*) denominador
FROM
  dbo.SolicitudValoracion s
  LEFT JOIN dbo.Valoracion v ON v.SolicitudValoracionId = s.SolicitudValoracionId
  AND v.FechaRespuesta <= @c
WHERE
  s.FechaEmision >= @inicio
  AND s.FechaEmision <= @c;

SELECT
  COUNT(
    CASE
      WHEN Estado = 'RESUELTA'
      AND FechaResolucionDefinitiva <= @c THEN 1
    END
  ) numerador,
  COUNT(*) denominador
FROM
  dbo.CasoAtencion
WHERE
  Tipo = 'INCIDENCIA'
  AND Ambito IN ('SERVICIO', 'ACCESO')
  AND FechaAperturaOriginal >= @inicio
  AND FechaAperturaOriginal <= @c;

SELECT
  COUNT(
    CASE
      WHEN Estado IN ('ACEPTADA', 'APLICADA')
      AND FechaRespuesta <= @c THEN 1
    END
  ) numerador,
  COUNT(*) denominador
FROM
  dbo.PropuestaCambioPlan
WHERE
  FechaPresentacion >= @inicio
  AND FechaPresentacion <= @c;
`;

export const CALCULAR_INDICADORES_MES = `
DECLARE @c DATETIME2(0) = GETDATE(), @inicio DATETIME2(0);
SET @inicio = DATEFROMPARTS(YEAR(@c), MONTH(@c), 1);
${CONSULTAR_INDICADORES_MES}
`;
