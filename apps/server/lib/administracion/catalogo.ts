import { z } from "zod";
import { getPrisma } from "../database/prisma.ts";
export const recursoSchema = z.object({
  TemaId: z.number().int().positive(),
  Titulo: z.string().trim().min(1).max(180),
  Tipo: z.enum([
    "TEXTO",
    "PDF",
    "VIDEO",
    "EJERCICIO",
    "EJEMPLO_RESUELTO",
    "EXAMEN_DESARROLLADO",
    "EVALUACION",
    "SIMULACRO",
  ]),
  Ubicacion: z
    .union([
      z.url().refine((v) => /^https?:\/\//i.test(v), "Solo enlaces HTTP/HTTPS"),
      z.literal(""),
      z.null(),
    ])
    .transform((v) => v || null),
  DuracionEstimadaMin: z.number().int().positive().max(32767).nullable(),
  Activo: z.boolean(),
});
export async function catalogo(tipo: string, buscar: string, pagina: number) {
  const p = getPrisma();
  if (tipo === "cursos") {
    return {
      items: await p.contenidoUNT.groupBy({
        by: ["Curso"],
        _count: { ContenidoId: true },
        orderBy: { Curso: "asc" },
      }),
      total: await p.contenidoUNT.count(),
    };
  }
  if (tipo === "temas") {
    return {
      items: await p.contenidoUNT.findMany({
        where: {
          OR: [{ Curso: { contains: buscar } }, { Tema: { contains: buscar } }],
        },
        orderBy: { ContenidoId: "asc" },
      }),
    };
  }
  if (tipo === "recursos") {
    const where = { Titulo: { contains: buscar } };
    return {
      items: await p.recursoAcademico.findMany({
        where,
        include: { tema: { include: { curso: true } } },
        orderBy: { RecursoAcademicoId: "desc" },
        skip: (pagina - 1) * 20,
        take: 20,
      }),
      total: await p.recursoAcademico.count({ where }),
      pagina,
    };
  }
  if (tipo === "temas-recursos")
    return {
      items: await p.tema.findMany({
        include: { curso: true },
        orderBy: { TemaId: "asc" },
      }),
    };
  if (tipo === "planes") {
    const [items, suscripciones] = await Promise.all([
      p.planServicio.findMany({
        include: { modalidades: true },
        orderBy: { Nivel: "asc" },
      }),
      p.suscripcion.findMany({
        include: {
          periodos: { include: { pagos: true }, orderBy: { Inicio: "desc" } },
        },
        orderBy: { SuscripcionId: "desc" },
        take: 100,
      }),
    ]);
    return { items, suscripciones };
  }
  throw new Error("Catálogo no disponible");
}
export async function guardarRecurso(id: number | null, entrada: unknown) {
  const data = recursoSchema.parse(entrada),
    p = getPrisma();
  if (id) {
    const r = await p.recursoAcademico.updateMany({
      where: { RecursoAcademicoId: id },
      data,
    });
    if (!r.count) throw new Error("Recurso inexistente");
    return { id };
  }
  return { id: (await p.recursoAcademico.create({ data })).RecursoAcademicoId };
}
