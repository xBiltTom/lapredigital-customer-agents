import { z } from "zod";
import { getPrisma } from "../database/prisma.ts";
const texto = (max: number) => z.string().trim().min(1).max(max);
const opcional = (max: number) =>
  z
    .string()
    .trim()
    .max(max)
    .transform((v) => v || null)
    .nullable();
export const contactoSchema = z.object({
  NombreCompleto: texto(160),
  Correo: z
    .union([z.email(), z.literal(""), z.null()])
    .transform((v) => v || null),
  Telefono: opcional(25),
});
export const estudianteSchema = contactoSchema
  .extend({
    Codigo: texto(20),
    UniversidadObjetivo: texto(150),
    CarreraObjetivo: opcional(120),
    FechaExamen: z
      .union([z.iso.date(), z.literal(""), z.null()])
      .transform((v) => (v ? new Date(v + "T00:00:00Z") : null)),
    DisponibilidadSemanalHoras: z.number().min(0).max(168).nullable(),
    ApoderadoId: z.number().int().positive().nullable(),
    Parentesco: opcional(30),
  })
  .refine(
    (v) => (v.ApoderadoId === null ? v.Parentesco === null : !!v.Parentesco),
    { message: "El parentesco debe acompañar al vínculo del apoderado" },
  );
export async function listarPersonas(
  tipo: "estudiantes" | "apoderados",
  buscar: string,
  pagina: number,
) {
  const p = getPrisma();
  const where = {
    OR: [
      { Codigo: { contains: buscar } },
      { contacto: { NombreCompleto: { contains: buscar } } },
    ],
  };
  if (tipo === "estudiantes") {
    const filtro = where;
    const [items, total] = await Promise.all([
      p.estudiante.findMany({
        where: filtro,
        include: { contacto: true, apoderado: { include: { contacto: true } } },
        orderBy: { Codigo: "asc" },
        skip: (pagina - 1) * 20,
        take: 20,
      }),
      p.estudiante.count({ where: filtro }),
    ]);
    return {
      items: items.map((x) => ({
        ...x,
        FechaExamen: x.FechaExamen?.toISOString().slice(0, 10) ?? null,
      })),
      total,
      pagina,
    };
  }
  const filtro = { contacto: { NombreCompleto: { contains: buscar } } };
  const [items, total] = await Promise.all([
    p.apoderado.findMany({
      where: filtro,
      include: {
        contacto: true,
        estudiantes: {
          select: {
            EstudianteId: true,
            Codigo: true,
            contacto: { select: { NombreCompleto: true } },
          },
        },
      },
      orderBy: { ApoderadoId: "asc" },
      skip: (pagina - 1) * 20,
      take: 20,
    }),
    p.apoderado.count({ where: filtro }),
  ]);
  return { items, total, pagina };
}
export async function guardarApoderado(id: number | null, entrada: unknown) {
  const data = contactoSchema.parse(entrada);
  const p = getPrisma();
  return p.$transaction(async (tx) => {
    if (id) {
      const a = await tx.apoderado.findUniqueOrThrow({
        where: { ApoderadoId: id },
      });
      await tx.contacto.updateMany({
        where: { ContactoId: a.ContactoId },
        data,
      });
      return { id };
    }
    const c = await tx.contacto.create({
      data: { ...data, CanalOrigen: "ADMINISTRACION" },
    });
    const a = await tx.apoderado.create({ data: { ContactoId: c.ContactoId } });
    return { id: a.ApoderadoId };
  });
}
export async function guardarEstudiante(id: number | null, entrada: unknown) {
  const data = estudianteSchema.parse(entrada);
  const { NombreCompleto, Correo, Telefono, ...academico } = data;
  const p = getPrisma();
  return p.$transaction(async (tx) => {
    if (academico.ApoderadoId)
      await tx.apoderado.findUniqueOrThrow({
        where: { ApoderadoId: academico.ApoderadoId },
      });
    if (!id) {
      const c = await tx.contacto.create({
        data: {
          NombreCompleto,
          Correo,
          Telefono,
          CanalOrigen: "ADMINISTRACION",
        },
      });
      const e = await tx.estudiante.create({
        data: { ...academico, ContactoId: c.ContactoId, EtapaActual: "LEAD" },
      });
      return { id: e.EstudianteId };
    }
    const anterior = await tx.estudiante.findUniqueOrThrow({
      where: { EstudianteId: id },
    });
    await tx.contacto.updateMany({
      where: { ContactoId: anterior.ContactoId },
      data: { NombreCompleto, Correo, Telefono },
    });
    // updateMany evita OUTPUT directo en tablas con triggers de historial de SQL Server.
    await tx.estudiante.updateMany({
      where: { EstudianteId: id },
      data: academico,
    });
    const cambioObjetivo =
      anterior.CarreraObjetivo !== academico.CarreraObjetivo ||
      anterior.UniversidadObjetivo !== academico.UniversidadObjetivo;
    const cambioFecha =
      anterior.FechaExamen?.toISOString().slice(0, 10) !==
      academico.FechaExamen?.toISOString().slice(0, 10);
    if (cambioObjetivo || cambioFecha) {
      const ruta = await tx.rutaEstudio.findFirst({
        where: { EstudianteId: id, Vigente: true },
      });
      if (ruta) {
        const motivo = cambioObjetivo
          ? "CAMBIO_OBJETIVO"
          : "CAMBIO_FECHA_EXAMEN";
        const pendiente = await tx.revisionRuta.findFirst({
          where: {
            RutaEstudioId: ruta.RutaEstudioId,
            Estado: "PENDIENTE",
            Motivo: motivo,
          },
        });
        if (!pendiente)
          await tx.$executeRaw`INSERT dbo.RevisionRuta(RutaEstudioId,Motivo,FechaIdentificacion,Estado) VALUES(${ruta.RutaEstudioId},${motivo},GETDATE(),'PENDIENTE')`;
      }
    }
    return { id };
  });
}
