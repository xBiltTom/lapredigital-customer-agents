import { defineTool } from 'eve/tools';
import { z } from 'zod';

export default defineTool({
  description:
    'Comprueba que el agente puede llamar una herramienta local sin consultar estudiantes ni servicios externos.',
  inputSchema: z.object({}),
  execute() {
    return { estado: 'ok', fuente: 'prueba_local' };
  },
});
