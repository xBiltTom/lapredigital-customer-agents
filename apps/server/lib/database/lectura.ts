import sql from "mssql";
import { readFile } from "node:fs/promises";
import { parseEnv } from "node:util";
import { loadSqlConfig } from "../config.ts";

let pendiente: Promise<sql.ConnectionPool> | undefined;

// Pool independiente: jamás sustituir la cuenta lectora por la de escrituras.
export async function getReadOnlyPool() {
  if (!pendiente) {
    const config = loadSqlConfig();
    // En dev permite habilitar la cuenta sin cerrar la terminal del llavero.
    let local: Record<string, string | undefined> = {};
    try {
      local = parseEnv(await readFile("/workspace/.env", "utf8"));
    } catch (e) {
      if ((e as NodeJS.ErrnoException).code !== "ENOENT") throw e;
    }
    const user =
      process.env.SQLSERVER_READONLY_USER || local.SQLSERVER_READONLY_USER;
    const password =
      process.env.SQLSERVER_READONLY_PASSWORD ||
      local.SQLSERVER_READONLY_PASSWORD;
    if (user !== "lapredigital_reader" || !password)
      throw new Error(
        "Falta habilitar la cuenta de consultas del dueño: scripts/provision-sql-reader.",
      );
    const pool = new sql.ConnectionPool({
      server: config.SQLSERVER_HOST,
      port: config.SQLSERVER_PORT,
      database: config.SQLSERVER_DATABASE,
      user,
      password,
      options: {
        encrypt: config.SQLSERVER_ENCRYPT,
        trustServerCertificate: config.SQLSERVER_TRUST_SERVER_CERTIFICATE,
        useUTC: false,
      },
      pool: { max: 2, min: 0, idleTimeoutMillis: 30000 },
      connectionTimeout: 5000,
      requestTimeout: 5000,
    });
    pendiente = pool.connect().catch(() => {
      pendiente = undefined;
      throw new Error("No se pudo abrir la conexión SQL de solo lectura.");
    });
  }
  return pendiente;
}

export async function closeReadOnlyPool() {
  const actual = pendiente;
  pendiente = undefined;
  if (actual) await (await actual.catch(() => undefined))?.close();
}
