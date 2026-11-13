import {
  CONSULTAR_TEMARIO,
  LISTAR_ESTUDIANTES,
  LISTAR_CONSULTAS_DUENO,
  BUSCAR_DESTINATARIO,
  BUSCAR_BLOQUEO_CONTACTO,
  BUSCAR_AUTORIZACION,
  GUARDAR_MENSAJE_LOCAL,
  LEER_BANDEJA,
  GUARDAR_CONSULTA_DUENO,
} from '../database/consultas/plataforma.ts';
import sql from 'mssql';
import { getPool } from '../database/pool.ts';
import { indicadoresCustomers } from './indicadores.ts';
import { diagnostico } from '../academico/diagnostico.ts';
// Lee el catálogo y el avance del alumno; no modifica la ruta académica.
export async function curriculum(e: number) {
  const p = await getPool();
  return (await p.request().input('e', sql.Int, e).query(CONSULTAR_TEMARIO))
    .recordset;
}
// Arma el dashboard: diagnóstico de cada alumno, KPI y consultas pendientes del dueño.
export async function general(owner: number) {
  const p = await getPool();
  const rows = (await p.request().query(LISTAR_ESTUDIANTES)).recordset;
  const alumnos = [];
  for (const r of rows) {
    const d = await diagnostico(owner, r.id);
    const avance = await curriculum(r.id);
    alumnos.push({
      ...r,
      servicioActivo: r.etapa === 'CUSTOMER' && !!d.ficha.servicioActual,
      riesgo: d.riesgo.nivel ?? 'PENDIENTE',
      completados: avance.filter((x) => x.estado === 'COMPLETADA').length,
      total: avance.length,
      cumplimiento: d.cumplimiento.porcentaje,
      incidencias: d.casos.filter((c) => c.estado !== 'RESUELTA').length,
    });
  }
  return {
    indicadores: await indicadoresCustomers(owner),
    definiciones: {
      completados:
        'Temas completados del temario UNT 2027, no actividades de ruta ni dominio demostrado',
      cumplimiento:
        'Porcentaje de actividades completadas de la ruta vigente en ventana de 30 días; tiene otro alcance que el temario',
      incidencias:
        'Casos de atención no resueltos; incluye consultas, no solo incidencias',
    },
    alumnos,
    consultas: (await p.request().query(LISTAR_CONSULTAS_DUENO)).recordset,
  };
}
// Resuelve el contacto real del alumno o su apoderado antes de leer/enviar mensajes.
export async function destinatario(e: number, rol: string) {
  const p = await getPool();
  const r = (
    await p.request().input('e', sql.Int, e).query(BUSCAR_DESTINATARIO)
  ).recordset[0];
  const id = rol === 'APODERADO' ? r?.apoderado : r?.estudiante;
  if (!id) throw new Error('Destinatario no disponible');
  return Number(id);
}
// Comprueba servicio, plan, no contacto y autorización antes de un envío proactivo.
export async function validarContacto(owner: number, e: number, rol: string) {
  const bloqueos = await (await getPool())
    .request()
    .input('e', sql.Int, e)
    .query(BUSCAR_BLOQUEO_CONTACTO);
  if (bloqueos.recordset.length)
    throw new Error('Solicitud de no contacto local vigente');
  const d = await diagnostico(owner, e);
  if (!d.ficha.servicioActual) throw new Error('Sin servicio vigente');
  if (
    rol === 'APODERADO' &&
    !d.ficha.prestaciones.some((p) => p.codigo === 'REPORTES_APODERADO')
  )
    throw new Error('El plan no incluye reportes al apoderado');
  if (d.contexto.noContacto.length) throw new Error('Petición de no contacto');
  if (d.narrativaPendiente)
    throw new Error('Revisar las interacciones antes de iniciar contacto');
  if (!d.ficha.prestaciones.some((p) => p.codigo === 'SEGUIMIENTO_IA'))
    throw new Error('Plan sin seguimiento IA');
  const contacto = await destinatario(e, rol);
  const p = await getPool();
  const r = await p
    .request()
    .input('c', sql.Int, contacto)
    .input('f', sql.VarChar(15), rol === 'APODERADO' ? 'REPORTES' : 'ACADEMICA')
    .query(BUSCAR_AUTORIZACION);
  if (!r.recordset.length)
    throw new Error('Sin autorización de contacto vigente');
  return contacto;
}
// Guarda un mensaje del transporte local. Registrar envío no confirma entrega.
export async function mensajeLocal(
  e: number,
  rol: string,
  canal: string,
  texto: string,
  direccion: string,
  consulta: number | null = null,
) {
  const contacto = await destinatario(e, rol);
  return (
    await (await getPool())
      .request()
      .input('e', sql.Int, e)
      .input('c', sql.Int, contacto)
      .input('rol', sql.VarChar(10), rol)
      .input('canal', sql.VarChar(12), canal)
      .input('texto', sql.NVarChar(2000), texto.slice(0, 2000))
      .input('d', sql.VarChar(10), direccion)
      .input('q', sql.Int, consulta)
      .query(GUARDAR_MENSAJE_LOCAL)
  ).recordset[0];
}
// Devuelve el hilo. Solo la lectura desde la bandeja del participante confirma recepción.
export async function bandeja(
  e: number,
  rol: string,
  canal: string,
  confirmarEntrega = false,
) {
  const c = await destinatario(e, rol);
  const p = await getPool();
  return (
    await p
      .request()
      .input('e', sql.Int, e)
      .input('c', sql.Int, c)
      .input('canal', sql.VarChar(12), canal)
      .input('ack', sql.Bit, confirmarEntrega)
      .query(LEER_BANDEJA)
  ).recordset;
}
// Deja una pregunta pendiente para que el dueño la resuelva desde el dashboard.
export async function consulta(
  e: number,
  rol: string,
  canal: string,
  pregunta: string,
) {
  const c = await destinatario(e, rol);
  return (
    await (await getPool())
      .request()
      .input('e', sql.Int, e)
      .input('c', sql.Int, c)
      .input('r', sql.VarChar(10), rol)
      .input('canal', sql.VarChar(12), canal)
      .input('p', sql.NVarChar(2000), pregunta)
      .query(GUARDAR_CONSULTA_DUENO)
  ).recordset[0];
}
