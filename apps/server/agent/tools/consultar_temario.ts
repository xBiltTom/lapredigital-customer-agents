import { defineTool } from "eve/tools";
import { z } from "zod";
import {
  herramientaPorModo,
  autorizarAlumno,
} from "../../lib/seguridad/alcance-herramientas.ts";
import { curriculum } from "../../lib/servicios/plataforma.ts";
import { jsonSeguro } from "../../lib/academico/diagnostico.ts";

export const herramienta = defineTool({
  description:
    "Catálogo y progreso por tema UNT. Filtra por curso, tema o estado y pagina. Completado indica avance declarado, no una nota ni dominio académico. Para rendimiento usa consultar_rendimiento.",
  inputSchema: z.object({
    estudianteId: z.number().int().positive().optional(),
    curso: z.string().max(100).optional(),
    buscar: z.string().max(150).optional(),
    estado: z.enum(["PENDIENTE", "EN_CURSO", "COMPLETADA"]).optional(),
    pagina: z.number().int().min(1).max(10000).default(1),
    limite: z.number().int().min(1).max(50).default(15),
  }),
  async execute(b, ctx) {
    const actor = await autorizarAlumno(
      ctx.session.auth.current,
      b.estudianteId,
    );
    const normalizar = (s: string) =>
      s
        .normalize("NFD")
        .replace(/\p{Diacritic}/gu, "")
        .toLowerCase();
    const temas = (await curriculum(actor.estudianteId)).filter(
      (t) =>
        (!b.curso || normalizar(t.curso).includes(normalizar(b.curso))) &&
        (!b.buscar ||
          normalizar(t.tema + " " + t.subtemas).includes(
            normalizar(b.buscar),
          )) &&
        (!b.estado || t.estado === b.estado),
    );
    return jsonSeguro({
      estudianteId: actor.estudianteId,
      total: temas.length,
      pagina: b.pagina,
      siguientePagina: temas.length > b.pagina * b.limite ? b.pagina + 1 : null,
      temas: temas.slice((b.pagina - 1) * b.limite, b.pagina * b.limite),
    });
  },
});
export default herramientaPorModo("lectura", herramienta);
