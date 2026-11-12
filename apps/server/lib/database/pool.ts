import sql from 'mssql';
import { loadSqlConfig } from '../config.ts';

let poolPromise: Promise<sql.ConnectionPool> | undefined;

export function getPool(): Promise<sql.ConnectionPool> {
  if (!poolPromise) {
    const config = loadSqlConfig();
    const pool = new sql.ConnectionPool({
      server: config.SQLSERVER_HOST,
      port: config.SQLSERVER_PORT,
      database: config.SQLSERVER_DATABASE,
      user: config.SQLSERVER_USER,
      password: config.SQLSERVER_PASSWORD,
      options: {
        encrypt: config.SQLSERVER_ENCRYPT,
        trustServerCertificate: config.SQLSERVER_TRUST_SERVER_CERTIFICATE,
        useUTC: false,
      },
      pool: { max: 3, min: 0, idleTimeoutMillis: 30_000 },
      connectionTimeout: 5_000,
      requestTimeout: 5_000,
    });
    poolPromise = pool.connect().catch((cause: unknown) => {
      poolPromise = undefined;
      throw new Error('No se pudo conectar a SQL Server. Revisa la instancia y el usuario de aplicación.', { cause });
    });
  }
  return poolPromise;
}

export async function closePool(): Promise<void> {
  const current = poolPromise;
  poolPromise = undefined;
  if (current) {
    const pool = await current.catch(() => undefined);
    if (pool) await pool.close();
  }
}
