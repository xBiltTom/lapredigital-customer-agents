import sql from 'mssql';
import { getPool } from './pool.ts';

export async function obtenerDuenoActivo(personalInternoId: number) {
  if (!Number.isSafeInteger(personalInternoId) || personalInternoId < 1)
    return null;
  const pool = await getPool();
  const { recordset } = await pool
    .request()
    .input('personalInternoId', sql.Int, personalInternoId)
    .query(`SELECT PersonalInternoId FROM dbo.PersonalInterno
            WHERE PersonalInternoId = @personalInternoId AND Rol = N'DUEÑO' AND Activo = 1`);
  return recordset.length === 1
    ? { personalInternoId: recordset[0].PersonalInternoId as number }
    : null;
}
