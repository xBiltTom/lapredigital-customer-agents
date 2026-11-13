import { getPrisma } from '../database/prisma.ts';
import { responderManual } from './mensajeria.ts';
import { destinatario } from './plataforma.ts';

// Solo serializa filas Prisma: DATETIME2 representa la hora peruana sin zona.
export function fechasCaso(value: unknown): unknown {
  if (value instanceof Date) return value.toISOString().replace('Z', '-05:00');
  if (Array.isArray(value)) return value.map(fechasCaso);
  if (value && typeof value === 'object')
    return Object.fromEntries(
      Object.entries(value).map(([k, v]) => [k, fechasCaso(v)]),
    );
  return value;
}
export async function detalleCaso(id: number) {
  const p = getPrisma();
  const caso = await p.casoAtencion.findUniqueOrThrow({
    where: { CasoAtencionId: id },
  });
  const [eventos, origenes] = await Promise.all([
    p.eventoCaso.findMany({
      where: { CasoAtencionId: id },
      orderBy: [{ FechaEvento: 'asc' }, { EventoCasoId: 'asc' }],
    }),
    p.$queryRaw`SELECT m.MensajeLocalId,m.EstudianteId,m.ContactoId,m.Rol,m.Contenido,m.Fecha,c.NombreCompleto,c.Telefono FROM dbo.AtencionMensaje a JOIN dbo.MensajeCanalLocal m ON m.MensajeLocalId=a.MensajeLocalId JOIN dbo.Contacto c ON c.ContactoId=m.ContactoId WHERE a.CasoAtencionId=${id} ORDER BY m.MensajeLocalId`,
  ]);
  const estudiante = await p.estudiante.findUniqueOrThrow({
    where: { EstudianteId: caso.EstudianteId },
    include: { contacto: true },
  });
  return {
    caso,
    eventos,
    origenes: origenes as {
      MensajeLocalId: number;
      EstudianteId: number;
      ContactoId: number;
      Rol: 'ESTUDIANTE' | 'APODERADO';
      Contenido: string;
      Fecha: Date;
      NombreCompleto: string;
      Telefono: string | null;
    }[],
    estudiante: {
      codigo: estudiante.Codigo,
      nombre: estudiante.contacto.NombreCompleto,
    },
  };
}
export async function comunicarResolucion(
  owner: number,
  id: number,
  mensajeOrigenId: number,
) {
  const d = await detalleCaso(id);
  if (d.caso.Estado !== 'RESUELTA' || !d.caso.Resolucion)
    throw new Error('Primero registra la solución del caso');
  const origen = d.origenes.find((x) => x.MensajeLocalId === mensajeOrigenId);
  if (!origen) throw new Error('El contacto no pertenece a este caso');
  return responderManual(
    owner,
    {
      EstudianteId: origen.EstudianteId,
      ContactoId: origen.ContactoId,
      Rol: origen.Rol,
    },
    `Sobre tu caso #${id}: ${d.caso.Resolucion}`,
  );
}

type Reporte = {
  estudianteId: number;
  contactoId: number;
  rol: 'ESTUDIANTE' | 'APODERADO';
  mensajeId: number;
  decision: 'REGISTRAR' | 'DERIVAR';
  descripcion: string;
  ambito: 'SERVICIO' | 'ACCESO' | 'PAGO';
  casoId?: number;
  respuestaDueno?: boolean;
};
export async function tramitarReporte(d: Reporte) {
  if (d.decision === 'REGISTRAR' && d.ambito === 'PAGO')
    throw new Error(
      'Las decisiones económicas se derivan al dueño; no crear incidencia de servicio',
    );
  if ((await destinatario(d.estudianteId, d.rol)) !== d.contactoId)
    throw new Error('Cambió el contacto del reporte');
  const p = getPrisma();
  return p.$transaction(async (tx) => {
    // El bloqueo del mensaje hace idempotentes las llamadas repetidas de la herramienta.
    const [m] = await tx.$queryRaw<
      {
        EstudianteId: number;
        ContactoId: number;
        Rol: string;
        Canal: string;
        Direccion: string;
      }[]
    >`SELECT EstudianteId,ContactoId,Rol,Canal,Direccion FROM dbo.MensajeCanalLocal WITH(UPDLOCK,HOLDLOCK) WHERE MensajeLocalId=${d.mensajeId}`;
    if (
      !m ||
      m.EstudianteId !== d.estudianteId ||
      m.ContactoId !== d.contactoId ||
      m.Rol !== d.rol ||
      m.Canal !== 'MENSAJERIA' ||
      m.Direccion !== 'ENTRANTE'
    )
      throw new Error('El mensaje no pertenece al participante activo');
    const previo = await tx.atencionMensaje.findUnique({
      where: { MensajeLocalId: d.mensajeId },
    });
    if (previo?.CasoAtencionId)
      return { casoId: previo.CasoAtencionId, reutilizado: true };
    if (previo?.ConsultaId && (d.decision === 'DERIVAR' || !d.respuestaDueno))
      return {
        consultaId: previo.ConsultaId,
        pendienteDueno: true,
        reutilizado: true,
      };
    if (d.decision === 'DERIVAR') {
      const [q] = await tx.$queryRaw<
        { id: number }[]
      >`INSERT dbo.ConsultaDueno(EstudianteId,ContactoId,Rol,Canal,Pregunta) OUTPUT INSERTED.ConsultaId id VALUES(${d.estudianteId},${d.contactoId},${d.rol},'MENSAJERIA',${d.descripcion})`;
      await tx.atencionMensaje.create({
        data: { MensajeLocalId: d.mensajeId, ConsultaId: q!.id },
      });
      return { consultaId: q!.id, pendienteDueno: true };
    }
    let id = d.casoId;
    if (id) {
      const [c] = await tx.$queryRaw<{EstudianteId:number;Ambito:string;Tipo:string;Estado:string}[]>`SELECT EstudianteId,Ambito,Tipo,Estado FROM dbo.CasoAtencion WITH(UPDLOCK,HOLDLOCK) WHERE CasoAtencionId=${id}`;
      if (!c) throw new Error('Caso inexistente');
      if (
        c.EstudianteId !== d.estudianteId ||
        c.Ambito !== d.ambito ||
        c.Tipo !== 'INCIDENCIA' ||
        c.Estado === 'RESUELTA'
      )
        throw new Error(
          'El caso no es una incidencia abierta del mismo estudiante y ámbito',
        );
    } else {
      const [c] = await tx.$queryRaw<
        { id: number }[]
      >`DECLARE @nuevo TABLE(id INT); INSERT dbo.CasoAtencion(EstudianteId,Tipo,Ambito,Descripcion,FechaAperturaOriginal,Estado) OUTPUT INSERTED.CasoAtencionId INTO @nuevo VALUES(${d.estudianteId},'INCIDENCIA',${d.ambito},${d.descripcion},GETDATE(),'ABIERTA'); SELECT id FROM @nuevo`;
      id = c!.id;
    }
    const caso = await tx.casoAtencion.findUniqueOrThrow({
      where: { CasoAtencionId: id },
    });
    const detalle =
      `Reporte de ${d.rol === 'APODERADO' ? 'apoderado' : 'estudiante'} desde mensajería, mensaje #${d.mensajeId}: ${d.descripcion}`.slice(
        0,
        1000,
      );
    await tx.$executeRaw`INSERT dbo.EventoCaso(CasoAtencionId,FechaEvento,Estado,Detalle) VALUES(${id},GETDATE(),${caso.Estado},${detalle})`;
    if (previo)
      await tx.atencionMensaje.updateMany({
        where: { MensajeLocalId: d.mensajeId },
        data: { CasoAtencionId: id },
      });
    else
      await tx.atencionMensaje.create({
        data: { MensajeLocalId: d.mensajeId, CasoAtencionId: id },
      });
    return { casoId: id, estado: caso.Estado, registrado: true };
  });
}
export async function reportesParticipante(e: number, c: number, incluirResueltos = false) {
  return getPrisma()
    .$queryRaw<{ CasoAtencionId: number; Ambito: string; Estado: string; Reporte: string }[]>`SELECT TOP(50) ca.CasoAtencionId,ca.Ambito,ca.Estado,m.Contenido Reporte FROM dbo.AtencionMensaje a JOIN dbo.MensajeCanalLocal m ON m.MensajeLocalId=a.MensajeLocalId JOIN dbo.CasoAtencion ca ON ca.CasoAtencionId=a.CasoAtencionId WHERE m.EstudianteId=${e} AND m.ContactoId=${c} AND (${incluirResueltos}=1 OR ca.Estado<>'RESUELTA') ORDER BY m.MensajeLocalId DESC`;
}
