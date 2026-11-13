import { defineTool } from "eve/tools";
import { z } from "zod";
import { indicadoresCustomers } from "../../lib/servicios/indicadores.ts";
import { jsonSeguro } from "../../lib/academico/diagnostico.ts";
import {
  herramientaPorModo,
  exigirHerramienta,
} from "../../lib/seguridad/alcance-herramientas.ts";
export const herramienta = defineTool({
  description:
    "Consulta los mismos KPI CUSTOMERS del dashboard: C-2.1 satisfacción, C-2.2 respuestas a valoraciones, C-2.3 resolución de incidencias y C-6.1 aceptación de cambios de plan. Devuelve corte, periodo, numerador, denominador, fórmula, fuentes y semáforo del informe. Avance provisional del mes en curso; solo dueño en dashboard global.",
  inputSchema: z.object({}),
  async execute(_, ctx) {
    exigirHerramienta(ctx.session.auth.current, "global");
    const a = ctx.session.auth.current;
    if (a?.authenticator !== "dueno-local" || a.attributes?.modo !== "global")
      throw new Error("Indicadores globales reservados al dashboard del dueño");
    return jsonSeguro(
      await indicadoresCustomers(Number(a.attributes.personalInternoId)),
    );
  },
});
export default herramientaPorModo("global", herramienta);
