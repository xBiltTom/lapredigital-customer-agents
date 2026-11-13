import { z } from 'zod';
import { getPrisma } from '../database/prisma.ts';

const horas = z.number().int().min(1).max(8760);
export const parametrosPolitica = z
  .object({
    InactividadMediaHoras: horas,
    InactividadAltaHoras: horas,
    IncidenciaMediaHoras: horas,
    IncidenciaAltaHoras: horas,
    VigenciaDias: z.number().int().min(1).max(30),
    MaxEstrellasInsatisfaccion: z.number().int().min(1).max(4),
  })
  .refine((v) => v.InactividadAltaHoras > v.InactividadMediaHoras, {
    message: 'La inactividad de riesgo alto debe superar la de riesgo medio',
  })
  .refine((v) => v.IncidenciaAltaHoras > v.IncidenciaMediaHoras, {
    message: 'El umbral alto de incidencias debe superar al medio',
  });
export const publicacionPolitica = parametrosPolitica.safeExtend({
  versionBase: z.string().min(1).max(20),
  Motivo: z.string().trim().min(5).max(500).optional(),
});
function presentar<T extends { FechaPublicacion: Date }>(p: T) {
  return {
    ...p,
    FechaPublicacion: p.FechaPublicacion.toISOString().replace('Z', '-05:00'),
  };
}
export async function politicaActual() {
  return presentar(
    await getPrisma().politicaRiesgo.findFirstOrThrow({
      orderBy: { Numero: 'desc' },
    }),
  );
}
export async function politicaVersion(version: string) {
  return presentar(
    await getPrisma().politicaRiesgo.findUniqueOrThrow({
      where: { VersionReglas: version },
    }),
  );
}
export async function historialPoliticas() {
  return (
    await getPrisma().politicaRiesgo.findMany({
      orderBy: { Numero: 'desc' },
      take: 100,
    })
  ).map(presentar);
}

export async function publicarPolitica(owner: number, entrada: unknown) {
  const d = publicacionPolitica.parse(entrada),
    p = getPrisma();
  return p.$transaction(async (tx) => {
    // Serializa las publicaciones y detecta formularios abiertos con una versión anterior.
    const [actual] = await tx.$queryRaw<
      { VersionReglas: string; Numero: number }[]
    >`SELECT TOP(1) VersionReglas,Numero FROM dbo.PoliticaRiesgo WITH(UPDLOCK,HOLDLOCK) ORDER BY Numero DESC`;
    if (!actual || actual.VersionReglas !== d.versionBase)
      throw new Error(
        'Las reglas cambiaron en otra sesión. Recarga antes de guardar.',
      );
    const iguales = await tx.politicaRiesgo.findUniqueOrThrow({
      where: { VersionReglas: actual.VersionReglas },
    });
    const { versionBase, Motivo, ...parametros } = d;
    if (
      Object.entries(parametros).every(
        ([k, v]) => iguales[k as keyof typeof iguales] === v,
      )
    )
      throw new Error('No hay cambios para guardar.');
    const motivo =
      Motivo ??
      Object.entries(parametros)
        .filter(([k, v]) => iguales[k as keyof typeof iguales] !== v)
        .map(([k, v]) => `${k}: ${iguales[k as keyof typeof iguales]} → ${v}`)
        .join('; ');
    const numero = actual.Numero + 1,
      version = `CUSTOMERS_${numero}`;
    await tx.$executeRaw`INSERT dbo.PoliticaRiesgo(VersionReglas,Numero,InactividadMediaHoras,InactividadAltaHoras,IncidenciaMediaHoras,IncidenciaAltaHoras,VigenciaDias,MaxEstrellasInsatisfaccion,CreadaPorId,Motivo) VALUES(${version},${numero},${d.InactividadMediaHoras},${d.InactividadAltaHoras},${d.IncidenciaMediaHoras},${d.IncidenciaAltaHoras},${d.VigenciaDias},${d.MaxEstrellasInsatisfaccion},${owner},${motivo})`;
    return presentar(
      await tx.politicaRiesgo.findUniqueOrThrow({
        where: { VersionReglas: version },
      }),
    );
  });
}
