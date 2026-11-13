import { defineTool } from 'eve/tools';
import { z } from 'zod';
import {
  detalleCaso,
  fechasCaso,
  tramitarReporte,
  reportesParticipante,
} from '../../lib/servicios/casos.ts';
import { destinatario } from '../../lib/servicios/plataforma.ts';
import { identidadHerramienta } from '../../lib/seguridad/identidad.ts';
export default defineTool({
  description:
    'CONSULTAR: dueño lee caso e historial; participante consulta sus reportes abiertos. REGISTRAR: participante reporta incidencia clara de acceso/servicio de su mensaje actual; vincula a casoId solo si es el mismo problema abierto. DERIVAR: solicita decisión del dueño en el chat global ante ambigüedad, reclamo sensible o decisión económica. No resuelve casos ni cambia accesos. Evita duplicados del mismo mensaje.',
  inputSchema: z.object({
    accion: z.enum(['CONSULTAR', 'REGISTRAR', 'DERIVAR']),
    casoId: z.number().int().positive().optional(),
    ambito: z.enum(['SERVICIO', 'ACCESO', 'PAGO']).default('SERVICIO'),
    descripcion: z.string().trim().min(1).max(1500).optional(),
  }),
  async execute(b, ctx) {
    const auth = ctx.session.auth.current,
      a = auth?.attributes;
    if (a?.modo === 'participante') {
      const e = Number(a.estudianteId),
        rol = z.enum(['ESTUDIANTE', 'APODERADO']).parse(a.rol),
        c = await destinatario(e, rol);
      if (a.canal !== 'MENSAJERIA')
        throw new Error('Los reportes de servicio se atienden por mensajería');
      if (b.accion === 'CONSULTAR')
        return fechasCaso(await reportesParticipante(e, c));
      if (!b.descripcion)
        throw new Error('Describe el reporte o la decisión que necesitas');
      return tramitarReporte({
        estudianteId: e,
        contactoId: c,
        rol,
        mensajeId: z.coerce.number().int().positive().parse(a.mensajeOrigenId),
        decision: b.accion,
        descripcion: b.descripcion,
        ambito: b.ambito,
        casoId: b.casoId,
        respuestaDueno: !!a.respuestaDueno,
      });
    }
    if (b.accion !== 'CONSULTAR')
      throw new Error(
        'El dueño registra y resuelve desde Consultas e incidencias',
      );
    const id = Number(a?.casoId ?? b.casoId);
    if (!Number.isSafeInteger(id) || id < 1)
      throw new Error('Selecciona un caso');
    const d = await detalleCaso(id);
    if (a?.modo === 'global') {
      if (auth?.authenticator !== 'dueno-local')
        throw new Error('Identidad requerida');
    } else {
      const actor = identidadHerramienta(auth);
      if (
        d.caso.EstudianteId !== actor.estudianteId ||
        (a?.casoId && b.casoId && Number(a.casoId) !== b.casoId)
      )
        throw new Error('Caso fuera del contexto seleccionado');
    }
    return fechasCaso(d);
  },
});
