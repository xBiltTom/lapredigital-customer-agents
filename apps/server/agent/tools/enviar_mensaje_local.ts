import { defineTool } from "eve/tools";
import { z } from "zod";
import {
  herramientaPorModo,
  exigirHerramienta,
  autorizarAlumno,
} from "../../lib/seguridad/alcance-herramientas.ts";
import {
  validarContacto,
  mensajeLocal,
} from "../../lib/servicios/plataforma.ts";

export const herramienta = defineTool({
  description:
    "Envía a la bandeja de Mensajería un texto solicitado por el dueño, al estudiante o apoderado indicado. Valida plan, identidad y permisos de contacto. Si falta revisar narrativas, consulta riesgo e interpreta antes de reintentar. No se usa para responder al participante: sus respuestas se publican automáticamente.",
  inputSchema: z.object({
    estudianteId: z.number().int().positive().optional(),
    rol: z.enum(["ESTUDIANTE", "APODERADO"]),
    texto: z.string().trim().min(1).max(2000),
  }),
  async execute(b, ctx) {
    exigirHerramienta(ctx.session.auth.current, "dueno");
    const actor = await autorizarAlumno(
      ctx.session.auth.current,
      b.estudianteId,
    );
    await validarContacto(actor.owner, actor.estudianteId, b.rol);
    const r = await mensajeLocal(
      actor.estudianteId,
      b.rol,
      "MENSAJERIA",
      b.texto,
      "SALIENTE",
    );
    return {
      mensajeId: r.id,
      estado: "ENVIADO_CANAL_LOCAL",
      destinatario:
        b.rol === "APODERADO"
          ? actor.ficha.apoderado?.nombreCompleto
          : actor.ficha.estudiante.nombreCompleto,
    };
  },
});
export default herramientaPorModo("dueno", herramienta);
