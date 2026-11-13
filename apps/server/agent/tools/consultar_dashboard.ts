import { defineTool } from "eve/tools";
import { z } from "zod";
import {
  herramientaPorModo,
  autorizarHerramienta,
} from "../../lib/seguridad/alcance-herramientas.ts";
import { general } from "../../lib/servicios/plataforma.ts";
import { jsonSeguro } from "../../lib/academico/diagnostico.ts";

export const herramienta = defineTool({
  description:
    "Panorama de estudiantes, riesgo y consultas pendientes para priorizar en Dashboard. Incluye IDs para seleccionar al alumno. Para cifras agregadas a medida usa consultar_datos_negocio; para KPI oficiales consultar_indicadores.",
  inputSchema: z.object({
    buscar: z.string().max(100).optional(),
    riesgo: z.enum(["BAJO", "MEDIO", "ALTO", "PENDIENTE"]).optional(),
    pagina: z.number().int().min(1).default(1),
    limite: z.number().int().min(1).max(50).default(20),
  }),
  async execute(b, ctx) {
    const { owner } = await autorizarHerramienta(
      ctx.session.auth.current,
      "global",
    );
    const r = await general(owner);
    const alumnos = r.alumnos.filter(
      (e) =>
        (!b.buscar ||
          (e.nombre + " " + e.codigo)
            .toLowerCase()
            .includes(b.buscar.toLowerCase())) &&
        (!b.riesgo || e.riesgo === b.riesgo),
    );
    return jsonSeguro({
      definiciones: r.definiciones,
      total: alumnos.length,
      pagina: b.pagina,
      siguientePagina:
        alumnos.length > b.pagina * b.limite ? b.pagina + 1 : null,
      alumnos: alumnos.slice((b.pagina - 1) * b.limite, b.pagina * b.limite),
      consultasPendientes: r.consultas
        .filter((q) => q.Estado === "PENDIENTE")
        .slice(0, 20),
    });
  },
});
export default herramientaPorModo("global", herramienta);
