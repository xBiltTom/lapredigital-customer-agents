import { defineTool } from "eve/tools";
import { defineDynamic } from "eve";
import { z } from "zod";
import {
  detalleCaso,
  fechasCaso,
  tramitarReporte,
  reportesParticipante,
} from "../../lib/servicios/casos.ts";
import { destinatario } from "../../lib/servicios/plataforma.ts";
import { consultarBase } from "../../lib/servicios/consultas.ts";
import { jsonSeguro } from "../../lib/academico/diagnostico.ts";
import {
  permiteHerramienta,
  exigirHerramienta,
  autorizarAlumno,
  autorizarHerramienta,
} from "../../lib/seguridad/alcance-herramientas.ts";

const entradaCaso = z.object({
  accion: z.enum(["CONSULTAR", "REGISTRAR"]),
  estudianteId: z.number().int().positive().optional(),
  casoId: z.number().int().positive().optional(),
  ambito: z.enum(["SERVICIO", "ACCESO", "PAGO"]).default("SERVICIO"),
  descripcion: z.string().trim().min(1).max(1500).optional(),
  estado: z
    .enum(["ABIERTA", "EN_ATENCION", "RESUELTA", "REABIERTA"])
    .optional(),
  pagina: z.number().int().min(1).max(10000).default(1),
});

export const herramienta = defineTool({
  description:
    "CONSULTAR: lista casos o lee casoId con historial; el participante solo ve sus reportes y estado público. REGISTRAR: participante de Mensajería registra un fallo claro de acceso/servicio de su mensaje actual, o añade el reporte al mismo caso abierto. Una dificultad de estudio no es una incidencia. Para decisiones o dudas sensibles usa gestionar_consulta_dueno. El dueño atiende/resuelve desde la aplicación.",
  inputSchema: entradaCaso,
  async execute(b, ctx) {
    const auth = ctx.session.auth.current;
    const a = exigirHerramienta(auth, "casos");
    if (a.modo === "participante") {
      const actor = await autorizarAlumno(auth, b.estudianteId);
      const rol = z.enum(["ESTUDIANTE", "APODERADO"]).parse(a.rol);
      const contactoId = await destinatario(actor.estudianteId, rol);
      if (b.accion === "CONSULTAR") {
        const reportes = await reportesParticipante(
          actor.estudianteId,
          contactoId,
          true,
        );
        const filtrados = reportes.filter(
          (r) =>
            (!b.casoId || r.CasoAtencionId === b.casoId) &&
            (!b.estado || r.Estado === b.estado),
        );
        return fechasCaso({
          cobertura:
            "Hasta los 50 reportes propios más recientes; no incluye notas internas",
          pagina: b.pagina,
          siguientePagina:
            filtrados.length > b.pagina * 10 ? b.pagina + 1 : null,
          reportes: filtrados.slice((b.pagina - 1) * 10, b.pagina * 10),
        });
      }
      if (!b.descripcion) throw new Error("Describe el problema reportado.");
      return tramitarReporte({
        estudianteId: actor.estudianteId,
        contactoId,
        rol,
        mensajeId: z.coerce.number().int().positive().parse(a.mensajeOrigenId),
        decision: "REGISTRAR",
        descripcion: b.descripcion,
        ambito: b.ambito,
        casoId: b.casoId,
        respuestaDueno: !!a.respuestaDueno,
      });
    }
    await autorizarHerramienta(auth, "dueno");
    if (b.accion !== "CONSULTAR")
      throw new Error(
        "El dueño registra y resuelve desde Consultas e incidencias.",
      );
    if (b.casoId) {
      const d = await detalleCaso(b.casoId);
      if (a.modo !== "global" && d.caso.EstudianteId !== Number(a.estudianteId))
        throw new Error("Caso fuera de esta conversación.");
      if (b.estudianteId && d.caso.EstudianteId !== b.estudianteId)
        throw new Error("El caso no corresponde al estudiante indicado.");
      return fechasCaso(d);
    }
    return jsonSeguro(
      await consultarBase(auth, {
        recurso: "INCIDENCIAS",
        estudianteId: b.estudianteId,
        estado: b.estado,
        orden: "RECIENTE",
        pagina: b.pagina,
        limite: 20,
      }),
    );
  },
});
const lecturaDueno = defineTool({
  description:
    "Lista casos o consulta su detalle e historial. El dueño atiende, registra y resuelve desde Consultas e incidencias.",
  inputSchema: entradaCaso.extend({
    accion: z.literal("CONSULTAR"),
  }),
  execute: herramienta.execute,
});

export default defineDynamic((ctx) => {
  const auth = ctx.session.auth.current;
  if (!permiteHerramienta(auth, "casos")) return null;
  return auth?.attributes?.modo === "participante" ? herramienta : lecturaDueno;
});
