import { defineTool } from "eve/tools";
import { herramientaPorModo } from "../../lib/seguridad/alcance-herramientas.ts";
import {
  consultaNegocioSchema,
  consultarDatosNegocio,
} from "../../lib/servicios/consultas-negocio.ts";
import { jsonSeguro } from "../../lib/academico/diagnostico.ts";

export const herramienta = defineTool({
  description:
    "Solo Dashboard del dueño: consulta en vivo y solo lectura las tablas de negocio e historiales. CATALOGO enumera tablas; con tabla muestra columnas y claves foráneas. CONSULTAR admite columnas alias.Columna, relaciones verificadas (LEFT JOIN), filtros, agrupaciones y medidas. Ejemplo: tabla Pago, alias p, agruparPor [p.Estado], medidas [{operacion:CONTAR,alias:cantidad}]. Para notas de un alumno usa consultar_rendimiento; KPI oficiales consultar_indicadores. Nunca recibe SQL libre. Si se unen relaciones de varios registros usa CONTAR_DISTINTOS para no duplicar personas/pagos.",
  inputSchema: consultaNegocioSchema,
  async execute(b, ctx) {
    return jsonSeguro(await consultarDatosNegocio(ctx.session.auth.current, b));
  },
});
export default herramientaPorModo("global", herramienta);
