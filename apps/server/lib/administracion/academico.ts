import { z } from "zod";
import { getPrisma } from "../database/prisma.ts";
import { construirFiltroCasos } from "./filtros-casos.ts";
export async function listarRutas(estudianteId?: number) {
  const p = getPrisma();
  return {
    items: await p.rutaEstudio.findMany({
      where: estudianteId ? { EstudianteId: estudianteId } : {},
      include: { actividades: true },
      orderBy: [{ EstudianteId: "asc" }, { VersionNumero: "desc" }],
      take: 100,
    }),
    revisiones: await p.revisionRuta.findMany({
      where: { Estado: "PENDIENTE" },
      orderBy: { FechaIdentificacion: "asc" },
      take: 100,
    }),
  };
}
export const rutaSchema = z.object({
  EstudianteId: z.number().int().positive(),
  Objetivo: z.string().trim().min(1).max(350),
  FechaExamenObjetivo: z
    .union([z.iso.date(), z.literal(""), z.null()])
    .transform((v) => (v ? new Date(v + "T00:00:00Z") : null)),
  copiarActividades: z.boolean().default(true),
});
// Publicar crea versión; las anteriores permanecen como evidencia del seguimiento.
export async function publicarRuta(owner: number, entrada: unknown) {
  const d = rutaSchema.parse(entrada);
  const p = getPrisma();
  return p.$transaction(async (tx) => {
    await tx.estudiante.findUniqueOrThrow({
      where: { EstudianteId: d.EstudianteId },
    });
    const anterior = await tx.rutaEstudio.findFirst({
      where: { EstudianteId: d.EstudianteId, Vigente: true },
      include: { actividades: true },
    });
    const max = await tx.rutaEstudio.aggregate({
      where: { EstudianteId: d.EstudianteId },
      _max: { VersionNumero: true },
    });
    const version = (max._max.VersionNumero ?? 0) + 1;
    await tx.rutaEstudio.updateMany({
      where: { EstudianteId: d.EstudianteId, Vigente: true },
      data: { Vigente: false },
    });
    await tx.$executeRaw`INSERT dbo.RutaEstudio(EstudianteId,VersionNumero,Objetivo,FechaExamenObjetivo,Inicio,Vigente,ActualizadaPorId,FechaActualizacion) VALUES(${d.EstudianteId},${version},${d.Objetivo},${d.FechaExamenObjetivo},GETDATE(),1,${owner},GETDATE())`;
    const nueva = await tx.rutaEstudio.findUniqueOrThrow({
      where: {
        EstudianteId_VersionNumero: {
          EstudianteId: d.EstudianteId,
          VersionNumero: version,
        },
      },
    });
    if (d.copiarActividades && anterior?.actividades.length) {
      await tx.actividadRuta.createMany({
        data: anterior.actividades.map(
          ({ ActividadRutaId, RutaEstudioId, FechaRegistro, ...a }) => ({
            ...a,
            RutaEstudioId: nueva.RutaEstudioId,
          }),
        ),
      });
    }
    if (anterior)
      await tx.$executeRaw`UPDATE dbo.RevisionRuta SET Estado='REVISADA',RevisadaPorId=${owner},FechaRevision=GETDATE(),Resultado=N'Nueva versión publicada por el dueño',RutaResultanteId=${nueva.RutaEstudioId} WHERE RutaEstudioId=${anterior.RutaEstudioId} AND Estado='PENDIENTE'`;
    return { id: nueva.RutaEstudioId, version };
  });
}
export const actividadSchema = z
  .object({
    RutaEstudioId: z.number().int().positive(),
    RecursoAcademicoId: z.number().int().positive(),
    FechaPlanificada: z.iso.date().transform((v) => new Date(v + "T00:00:00Z")),
    FechaLimite: z.iso.date().transform((v) => new Date(v + "T23:59:59Z")),
  })
  .refine((v) => v.FechaLimite >= v.FechaPlanificada, {
    message: "El límite no puede ser anterior a la planificación",
  });
export async function agregarActividad(entrada: unknown) {
  const d = actividadSchema.parse(entrada),
    p = getPrisma();
  return p.$transaction(async (tx) => {
    const r = await tx.rutaEstudio.findUniqueOrThrow({
      where: { RutaEstudioId: d.RutaEstudioId },
    });
    if (!r.Vigente)
      throw new Error("Solo se asignan actividades a una ruta vigente");
    await tx.recursoAcademico.findFirstOrThrow({
      where: { RecursoAcademicoId: d.RecursoAcademicoId, Activo: true },
    });
    const m = await tx.actividadRuta.aggregate({
      where: { RutaEstudioId: d.RutaEstudioId },
      _max: { Orden: true },
    });
    await tx.actividadRuta.createMany({
      data: [{ ...d, Orden: (m._max.Orden ?? 0) + 1, Estado: "PENDIENTE" }],
    });
    return { ok: true };
  });
}
export async function listarCasos(
  buscar: string,
  pagina: number,
  filtros: unknown = {},
) {
  const p = getPrisma();
  const where = construirFiltroCasos(buscar, filtros);
  return {
    items: await p.casoAtencion.findMany({
      where,
      orderBy: { FechaAperturaOriginal: "desc" },
      skip: (pagina - 1) * 20,
      take: 20,
    }),
    total: await p.casoAtencion.count({ where }),
    pagina,
  };
}
export const casoSchema = z.object({
  EstudianteId: z.number().int().positive(),
  Tipo: z.enum(["CONSULTA", "INCIDENCIA"]),
  Ambito: z.enum(["SERVICIO", "ACCESO"]),
  Descripcion: z.string().trim().min(1).max(1500),
});
export async function abrirCaso(owner: number, entrada: unknown) {
  const d = casoSchema.parse(entrada);
  const p = getPrisma();
  return p.$transaction(async (tx) => {
    await tx.estudiante.findUniqueOrThrow({
      where: { EstudianteId: d.EstudianteId },
    });
    const rows = await tx.$queryRaw<
      { id: number }[]
    >`DECLARE @nuevo TABLE(id INT); INSERT dbo.CasoAtencion(EstudianteId,Tipo,Ambito,Descripcion,FechaAperturaOriginal,Estado,ResponsableId) OUTPUT INSERTED.CasoAtencionId INTO @nuevo VALUES(${d.EstudianteId},${d.Tipo},${d.Ambito},${d.Descripcion},GETDATE(),'ABIERTA',${owner}); SELECT id FROM @nuevo`;
    const id = rows[0]!.id;
    await tx.$executeRaw`INSERT dbo.EventoCaso(CasoAtencionId,FechaEvento,Estado,Detalle,ResponsableId) VALUES(${id},GETDATE(),'ABIERTA',N'Caso registrado por administración',${owner})`;
    return { id };
  });
}
export const atenderCasoSchema = z.object({
  Estado: z.enum(["EN_ATENCION", "RESUELTA", "REABIERTA"]),
  Detalle: z.string().trim().min(1).max(1000),
  EstadoAnterior: z.enum(["ABIERTA","EN_ATENCION","RESUELTA","REABIERTA"]).optional(),
});
export async function atenderCaso(owner: number, id: number, entrada: unknown) {
  const d = atenderCasoSchema.parse(entrada),
    p = getPrisma();
  return p.$transaction(async (tx) => {
    const [c] = await tx.$queryRaw<{Ambito:string;Estado:string}[]>`SELECT Ambito,Estado FROM dbo.CasoAtencion WITH(UPDLOCK,HOLDLOCK) WHERE CasoAtencionId=${id}`;
    if (!c) throw new Error("Caso inexistente");
    if (d.EstadoAnterior && c.Estado !== d.EstadoAnterior) throw new Error("El caso cambió. Actualiza antes de continuar.");
    if (c.Ambito === "PAGO")
      throw new Error(
        "Los casos económicos solo se consultan; corresponden a PAYERS",
      );
    if (d.Estado === "REABIERTA" && c.Estado !== "RESUELTA")
      throw new Error("Solo se reabren casos resueltos");
    if (c.Estado === "RESUELTA" && d.Estado !== "REABIERTA")
      throw new Error("Debe reabrir el caso antes de atenderlo");
    await tx.$executeRaw`UPDATE dbo.CasoAtencion SET Estado=${d.Estado},ResponsableId=${owner},FechaResolucionDefinitiva=CASE WHEN ${d.Estado}='RESUELTA' THEN GETDATE() ELSE NULL END,Resolucion=CASE WHEN ${d.Estado}='RESUELTA' THEN ${d.Detalle} ELSE NULL END WHERE CasoAtencionId=${id}`;
    await tx.$executeRaw`INSERT dbo.EventoCaso(CasoAtencionId,FechaEvento,Estado,Detalle,ResponsableId) VALUES(${id},GETDATE(),${d.Estado},${d.Detalle},${owner})`;
    return { id };
  });
}
