import { defineTool } from "eve/tools";
import { z } from "zod";
import {
  herramientaPorModo,
  exigirHerramienta,
  autorizarAlumno,
} from "../../lib/seguridad/alcance-herramientas.ts";
import { consulta } from "../../lib/servicios/plataforma.ts";

export const herramienta = defineTool({
  description:
    "Registra la petición expresa del participante de dejar de recibir seguimiento proactivo y la comunica al responsable. Conserva el acceso contratado y permite atender preguntas entrantes. No se usa para inferir cancelación ni cambiar renovación.",
  inputSchema: z.object({ peticion: z.string().trim().min(1).max(1500) }),
  async execute({ peticion }, ctx) {
    exigirHerramienta(ctx.session.auth.current, "participante");
    const actor = await autorizarAlumno(ctx.session.auth.current);
    const r = await consulta(
      actor.estudianteId,
      String(actor.a.rol),
      String(actor.a.canal),
      "NO_CONTACTO: " + peticion,
    );
    return {
      consultaId: r.id,
      seguimientoProactivo: "BLOQUEADO",
      servicio: "CONSERVA_VIGENCIA_CONTRATADA",
    };
  },
});
export default herramientaPorModo("participante", herramienta);
