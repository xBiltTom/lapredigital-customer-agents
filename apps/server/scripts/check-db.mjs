import sql from 'mssql';
import { getPool, closePool } from '../lib/database/pool.ts';

try {
  const pool = await getPool();
  if (await getPool() !== pool) throw new Error('El pool SQL no se reutilizó.');
  const { recordset } = await pool.request()
    .input('codigo', sql.VarChar(20), 'C001')
    .query(`SELECT EstudianteId, Codigo,
                   CONVERT(varchar(19), GETDATE(), 126) AS HoraPeru,
                   DATEPART(TZOFFSET, SYSDATETIMEOFFSET()) AS OffsetMinutos
            FROM dbo.Estudiante WHERE Codigo = @codigo`);
  if (recordset.length !== 1) throw new Error('No se encontró el estudiante de referencia C001.');
  const row = recordset[0];
  if (row.OffsetMinutos !== -300) throw new Error('SQL Server no está en la zona horaria de Perú (-05:00).');
  const { recordset: permissions } = await pool.request().query(`SELECT
    HAS_PERMS_BY_NAME(N'dbo.Estudiante', N'OBJECT', N'SELECT') AS Leer,
    HAS_PERMS_BY_NAME(N'dbo.Estudiante', N'OBJECT', N'INSERT') AS Insertar,
    HAS_PERMS_BY_NAME(N'dbo.Estudiante', N'OBJECT', N'UPDATE') AS Actualizar,
    HAS_PERMS_BY_NAME(N'dbo.Estudiante', N'OBJECT', N'DELETE') AS Borrar`);
  const allowed = permissions[0];
  if (allowed.Leer !== 1 || allowed.Insertar !== 1 || allowed.Actualizar !== 0 || allowed.Borrar !== 0) {
    throw new Error('Se esperaban lectura, alta de perfiles y actualización limitada por columnas; nunca borrado.');
  }
  console.log(`Conexión y permisos administrativos limitados correctos: ${row.Codigo}, hora SQL ${row.HoraPeru} (-05:00).`);
} catch (error) {
  console.error(error instanceof Error ? error.message : 'Error inesperado al verificar SQL Server.');
  process.exitCode = 1;
} finally {
  await closePool();
}
