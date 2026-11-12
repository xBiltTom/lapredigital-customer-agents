import { z } from 'zod';

const schema = z.object({
  TZ: z.literal('America/Lima'),
  AI_PROVIDER: z.literal('chatgpt'),
});

export function loadConfig(env: Record<string, string | undefined> = process.env) {
  const result = schema.safeParse(env);
  if (!result.success) {
    const names = result.error.issues.map((issue) => issue.path.join('.')).join(', ');
    throw new Error(`Configuración inválida o ausente: ${names}. Consulta .env.example.`);
  }
  return result.data;
}

const sqlSchema = z.object({
  SQLSERVER_HOST: z.string().trim().min(1),
  SQLSERVER_PORT: z.coerce.number().int().min(1).max(65535),
  SQLSERVER_DATABASE: z.literal('LaPreDigital_Customers'),
  SQLSERVER_USER: z.literal('lapredigital_app'),
  SQLSERVER_PASSWORD: z.string().min(1),
  SQLSERVER_ENCRYPT: z.enum(['true', 'false']).transform((value) => value === 'true'),
  SQLSERVER_TRUST_SERVER_CERTIFICATE: z.enum(['true', 'false']).transform((value) => value === 'true'),
});

export function loadSqlConfig(env: Record<string, string | undefined> = process.env) {
  const result = sqlSchema.safeParse(env);
  if (!result.success) {
    const names = result.error.issues.map((issue) => issue.path.join('.')).join(', ');
    throw new Error(`Configuración SQL inválida o ausente: ${names}. Consulta .env.example.`);
  }
  return result.data;
}
