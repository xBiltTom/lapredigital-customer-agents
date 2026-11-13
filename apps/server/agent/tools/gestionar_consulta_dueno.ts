import { defineDynamic } from "eve";
import { defineTool } from "eve/tools";
import { z } from "zod";
import {
  permiteHerramienta,
  exigirHerramienta,
  autorizarAlumno,
  autorizarHerramienta,
} from "../../lib/seguridad/alcance-herramientas.ts";
import { consulta, destinatario } from "../../lib/servicios/plataforma.ts";
import { tramitarReporte } from "../../lib/servicios/casos.ts";

export const solicitar = defineTool({
  description:
    "Solicita al dueño una decisión económica, atención de una ambigüedad o cambio que requiere autorización. Incluye la pregunta y hechos verificados. No se necesita para consultas de rendimiento, pagos registrados o servicio que puedes leer. Un problema claro de acceso/servicio se registra con gestionar_caso.",
  inputSchema: z.object({
    pregunta: z.string().trim().min(5).max(1500),
    ambito: z.enum(["SERVICIO", "ACCESO", "PAGO"]).default("SERVICIO"),
  }),
  async execute(b, ctx) {
    exigirHerramienta(ctx.session.auth.current, "participante");
    const actor = await autorizarAlumno(ctx.session.auth.current);
    if (actor.a.modo !== "participante")
      throw new Error("Esta consulta corresponde al participante.");
    const rol = String(actor.a.rol);
    if (actor.a.canal === "MENSAJERIA" && actor.a.mensajeOrigenId) {
      return tramitarReporte({
        estudianteId: actor.estudianteId,
        contactoId: await destinatario(actor.estudianteId, rol),
        rol: rol as "ESTUDIANTE" | "APODERADO",
        mensajeId: Number(actor.a.mensajeOrigenId),
        decision: "DERIVAR",
        descripcion: b.pregunta,
        ambito: b.ambito,
      });
    }
    const r = await consulta(
      actor.estudianteId,
      rol,
      String(actor.a.canal),
      b.pregunta,
    );
    return { consultaId: r.id, estado: "PENDIENTE" };
  },
});

export const responder = defineTool({
  description:
    "Comunica al participante la decisión que el dueño acaba de autorizar para una consulta pendiente. Elige consultaId del dashboard y el texto de su decisión; no inventes una decisión ni la deduzcas de mensajes del participante.",
  inputSchema: z.object({
    consultaId: z.number().int().positive(),
    texto: z.string().trim().min(1).max(2000),
  }),
  async execute(b, ctx) {
    await autorizarHerramienta(ctx.session.auth.current, "global");
    const r = await fetch(
      `http://127.0.0.1:3000/api/consultas/${b.consultaId}/responder`,
      {
        method: "POST",
        headers: {
          Authorization: "Bearer " + process.env.OWNER_ACCESS_TOKEN,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ texto: b.texto }),
        signal: ctx.abortSignal,
      },
    );
    const result = await r.json();
    if (!r.ok)
      throw new Error(result.error ?? "No se pudo comunicar la decisión.");
    return { consultaId: b.consultaId, estado: "RESPONDIDA" };
  },
});
export default defineDynamic((ctx) => {
  const auth = ctx.session.auth.current;
  if (permiteHerramienta(auth, "global")) return responder;
  return permiteHerramienta(auth, "participante") ? solicitar : null;
});
