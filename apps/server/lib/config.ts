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
