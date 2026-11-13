import { PrismaClient } from "@prisma/client";
import { PrismaMssql } from "@prisma/adapter-mssql";
import { loadSqlConfig } from "../config.ts";

let client: PrismaClient | undefined;
// DATETIME2 no contiene zona. Prisma usa Date como representación de la hora SQL:
// useUTC evita desplazarla al copiar entre filas. Las escrituras de reloj usan GETDATE.
// Un cliente por proceso; la misma base y credenciales de aplicación que el SQL existente.
export function getPrisma() {
  if (!client) {
    const c = loadSqlConfig();
    const adapter = new PrismaMssql({
      server: c.SQLSERVER_HOST,
      port: c.SQLSERVER_PORT,
      database: c.SQLSERVER_DATABASE,
      user: c.SQLSERVER_USER,
      password: c.SQLSERVER_PASSWORD,
      options: {
        encrypt: c.SQLSERVER_ENCRYPT,
        trustServerCertificate: c.SQLSERVER_TRUST_SERVER_CERTIFICATE,
        useUTC: true,
      },
      pool: { max: 3, min: 0, idleTimeoutMillis: 30000 },
    });
    client = new PrismaClient({ adapter });
  }
  return client;
}
