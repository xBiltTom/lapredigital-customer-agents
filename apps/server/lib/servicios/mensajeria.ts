import { getPrisma } from '../database/prisma.ts';
import { getPool } from '../database/pool.ts';
import sql from 'mssql';
import { destinatario } from './plataforma.ts';
import { diagnostico } from '../academico/diagnostico.ts';
import {
  BUSCAR_AUTORIZACION,
  BUSCAR_BLOQUEO_CONTACTO,
} from '../database/consultas/plataforma.ts';

export type Hilo = {
  EstudianteId: number;
  ContactoId: number;
  Rol: 'ESTUDIANTE' | 'APODERADO';
};
// Prisma representa la hora SQL sin zona; se publica explícitamente con el offset peruano.
const fechaPeru = (date: Date) => date.toISOString().replace('Z', '-05:00');
function presentar<T extends { Fecha: Date; FechaEntrega: Date | null }>(m: T) {
  return {
    ...m,
    Fecha: fechaPeru(m.Fecha),
    FechaEntrega: m.FechaEntrega ? fechaPeru(m.FechaEntrega) : null,
  };
}
const filtro = (h: Hilo) => ({ ...h, Canal: 'MENSAJERIA' });

export async function listarHilos() {
  const p = getPrisma();
  // Una agrupación y una lectura conjunta; sin consultar cada hilo por separado.
  const grupos = await p.mensajeCanalLocal.groupBy({
    by: ['EstudianteId', 'ContactoId', 'Rol'],
    where: { Canal: 'MENSAJERIA' },
    _max: { MensajeLocalId: true },
    orderBy: { _max: { MensajeLocalId: 'desc' } },
    take: 200,
  });
  const ids = grupos.map((g) => g._max.MensajeLocalId!).filter(Boolean);
  const mensajes = await p.mensajeCanalLocal.findMany({
    where: { MensajeLocalId: { in: ids } },
    include: {
      contacto: { select: { NombreCompleto: true, Telefono: true } },
      estudiante: {
        select: {
          Codigo: true,
          contacto: { select: { NombreCompleto: true } },
        },
      },
    },
    orderBy: { MensajeLocalId: 'desc' },
  });
  return { items: mensajes.map(presentar), limite: 200 };
}
export async function leerHilo(h: Hilo, antes?: number) {
  const rows = await getPrisma().mensajeCanalLocal.findMany({
    where: {
      ...filtro(h),
      ...(antes ? { MensajeLocalId: { lt: antes } } : {}),
    },
    orderBy: { MensajeLocalId: 'desc' },
    take: 100,
  });
  return {
    items: rows.reverse().map(presentar),
    hayAnteriores: rows.length === 100,
  };
}
export async function responderManual(owner: number, h: Hilo, texto: string) {
  const p = getPrisma();
  if (
    !(await p.mensajeCanalLocal.findFirst({
      where: filtro(h),
      select: { MensajeLocalId: true },
    }))
  )
    throw new Error('El hilo no existe');
  if ((await destinatario(h.EstudianteId, h.Rol)) !== h.ContactoId)
    throw new Error(
      'El contacto ya no está vinculado; el hilo queda solo para consulta',
    );
  const d = await diagnostico(owner, h.EstudianteId);
  if (
    h.Rol === 'APODERADO' &&
    !d.ficha.prestaciones.some((x) => x.codigo === 'REPORTES_APODERADO')
  )
    throw new Error('El apoderado no tiene acceso vigente al portal');
  if (d.contexto.noContacto.length)
    throw new Error('Hay una petición de no contacto vigente');
  // Atención humana: no exige la prestación SEGUIMIENTO_IA, pero respeta revocaciones y no contacto.
  const pool = await getPool();
  const [bloqueos, autorizacion] = await Promise.all([
    pool
      .request()
      .input('e', sql.Int, h.EstudianteId)
      .query(BUSCAR_BLOQUEO_CONTACTO),
    pool
      .request()
      .input('c', sql.Int, h.ContactoId)
      .input(
        'f',
        sql.VarChar(15),
        h.Rol === 'APODERADO' ? 'REPORTES' : 'ACADEMICA',
      )
      .query(BUSCAR_AUTORIZACION),
  ]);
  if (bloqueos.recordset.length)
    throw new Error('Hay una solicitud de no contacto vigente');
  if (!autorizacion.recordset.length)
    throw new Error('El contacto no tiene autorización vigente');
  const mensaje = await p.mensajeCanalLocal.create({
    data: { ...filtro(h), Direccion: 'SALIENTE', Contenido: texto },
  });
  // Leer desde administración no confirma entrega: eso lo hace la bandeja del participante.
  return presentar(mensaje);
}
