import {
  CONSULTAR_TEMARIO,
  BUSCAR_DESTINATARIO,
  BUSCAR_BLOQUEO_CONTACTO,
  BUSCAR_AUTORIZACION,
  GUARDAR_MENSAJE_LOCAL,
  LEER_BANDEJA,
  GUARDAR_CONSULTA_DUENO,
} from '../database/consultas/plataforma.ts';
import sql from 'mssql';
import { getPool } from '../database/pool.ts';
import { resumenDashboard } from './dashboard.ts';
import { diagnostico } from '../academico/diagnostico.ts';
// Lee el catálogo y el avance del alumno; no modifica la ruta académica.
export async function curriculum(e: number) {
  const p = await getPool();
  return (await p.request().input('e', sql.Int, e).query(CONSULTAR_TEMARIO))
    .recordset;
}
// API y herramienta global comparten la lectura optimizada por lotes.
export const general = resumenDashboard;
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

// Contexto del agente: una ventana acotada, sin confirmar entrega ni leer todo el hilo.
export async function hiloReciente(e: number, rol: string, canal: string) {
  const contacto = await destinatario(e, rol);
  const r = await (await getPool()).request()
    .input('e', sql.Int, e)
    .input('c', sql.Int, contacto)
    .input('canal', sql.VarChar(12), canal)
    .query(`SELECT TOP(12) MensajeLocalId,Direccion,Contenido,Fecha
      FROM dbo.MensajeCanalLocal WHERE EstudianteId=@e AND ContactoId=@c AND Canal=@canal
      ORDER BY MensajeLocalId DESC`);
  return r.recordset.reverse();
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
