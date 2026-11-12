import sql from 'mssql';
import { getPool } from './pool.ts';

export const TAMANO_PAGINA_MAX = 50;
export const TAMANO_PAGINA_PREDETERMINADO = 20;

// Se construye en el backend a partir de la sesión verificada. No aceptar desde JSON.
export type IdentidadActiva =
  | { contactoId: number; personalInternoId?: never }
  | { personalInternoId: number; contactoId?: never };

export type OpcionesListado = { pagina?: number; tamano?: number };

export type ResumenEstudiante = {
  estudianteId: number;
  codigo: string;
  nombreCompleto: string;
  correo: string | null;
  etapaActual: string;
  carreraObjetivo: string | null;
};

export type PaginaEstudiantes = {
  items: ResumenEstudiante[];
  total: number;
  pagina: number;
  tamano: number;
  paginas: number;
};

export type Periodo = {
  suscripcionId: number;
  estadoSuscripcion: string;
  renovacionAutomatica: boolean;
  fechaContratacion: Date;
  periodoServicioId: number;
  tipo: string;
  inicio: Date;
  fin: Date;
  estadoAcceso: string;
  becaPorcentaje: number;
  importeExigiblePEN: number;
  plan: string;
  meses: number;
  cobrosConfirmados: number;
  importeCobradoPEN: number;
  operacionesCorrectivas: number;
  fechaBaja: Date | null;
  tipoBaja: string | null;
  motivoComunicado: string | null;
  elegibleReactivacion: boolean | null;
  esActual: boolean;
};

export type FichaEstudiante = {
  estudiante: {
    estudianteId: number;
    codigo: string;
    nombreCompleto: string;
    correo: string | null;
    telefono: string | null;
    etapaActual: string;
    universidadObjetivo: string;
    carreraObjetivo: string | null;
    fechaExamen: Date | null;
    disponibilidadSemanalHoras: number | null;
    parentesco: string | null;
    fechaRegistro: Date;
  };
  apoderado: {
    contactoId: number;
    nombreCompleto: string;
    correo: string | null;
    telefono: string | null;
  } | null;
  servicioActual: Periodo | null;
  historial: Periodo[];
  prestaciones: { codigo: string; descripcion: string }[];
};

export function normalizarPagina(opciones: OpcionesListado = {}) {
  const pagina = opciones.pagina ?? 1;
  const tamano = opciones.tamano ?? TAMANO_PAGINA_PREDETERMINADO;
  if (!Number.isInteger(pagina) || pagina < 1) {
    throw new Error('La página debe ser un entero mayor o igual a 1.');
  }
  if (!Number.isInteger(tamano) || tamano < 1 || tamano > TAMANO_PAGINA_MAX) {
    throw new Error(`El tamaño de página debe ser un entero entre 1 y ${TAMANO_PAGINA_MAX}.`);
  }
  return { pagina, tamano, offset: (pagina - 1) * tamano };
}

function validarIdentidad(identidad: IdentidadActiva) {
  const id = identidad.personalInternoId ?? identidad.contactoId;
  if (typeof id !== 'number' || !Number.isSafeInteger(id) || id < 1 ||
      (identidad.contactoId !== undefined && identidad.personalInternoId !== undefined)) {
    throw new Error('La identidad activa no es válida.');
  }
}

function validarEstudianteId(estudianteId: number) {
  if (!Number.isInteger(estudianteId) || estudianteId < 1) {
    throw new Error('El identificador del estudiante no es válido.');
  }
}

const accesoIdentidad = `(EXISTS (
  SELECT 1 FROM dbo.PersonalInterno pi
  WHERE pi.PersonalInternoId = @personalInternoId AND pi.Rol = N'DUEÑO' AND pi.Activo = 1
) OR e.ContactoId = @contactoId OR EXISTS (
  SELECT 1 FROM dbo.Apoderado ap
  JOIN dbo.Suscripcion s ON s.EstudianteId = e.EstudianteId AND s.Estado = 'VIGENTE'
  JOIN dbo.PeriodoServicio ps ON ps.SuscripcionId = s.SuscripcionId
  JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId = ps.ModalidadPlanId
  JOIN dbo.PlanPrestacion pp ON pp.PlanServicioId = mp.PlanServicioId
  JOIN dbo.Prestacion pr ON pr.PrestacionId = pp.PrestacionId AND pr.Codigo = 'REPORTES_APODERADO'
  WHERE ap.ApoderadoId = e.ApoderadoId AND ap.ContactoId = @contactoId
    AND ps.Inicio <= GETDATE() AND ps.Fin > GETDATE()
    AND ps.EstadoAcceso IN ('HABILITADO', 'CON_INCIDENCIA')
))`;

export async function listarEstudiantes(
  identidad: IdentidadActiva,
  opciones: OpcionesListado = {},
): Promise<PaginaEstudiantes> {
  validarIdentidad(identidad);
  const { pagina, tamano, offset } = normalizarPagina(opciones);
  const pool = await getPool();

  const totalResult = await pool.request()
    .input('contactoId', sql.Int, identidad.contactoId ?? null)
    .input('personalInternoId', sql.Int, identidad.personalInternoId ?? null)
    .query(`SELECT COUNT(*) AS Total FROM dbo.Estudiante e WHERE ${accesoIdentidad}`);
  const total = Number(totalResult.recordset[0].Total);

  const { recordset } = await pool.request()
    .input('contactoId', sql.Int, identidad.contactoId ?? null)
    .input('personalInternoId', sql.Int, identidad.personalInternoId ?? null)
    .input('offset', sql.Int, offset)
    .input('tamano', sql.Int, tamano)
    .query(`SELECT e.EstudianteId, e.Codigo, e.EtapaActual, e.CarreraObjetivo,
                   c.NombreCompleto, c.Correo
            FROM dbo.Estudiante e
            JOIN dbo.Contacto c ON c.ContactoId = e.ContactoId
            WHERE ${accesoIdentidad}
            ORDER BY e.Codigo
            OFFSET @offset ROWS FETCH NEXT @tamano ROWS ONLY`);

  return {
    items: recordset.map((row) => ({
      estudianteId: row.EstudianteId,
      codigo: row.Codigo,
      nombreCompleto: row.NombreCompleto,
      correo: row.Correo,
      etapaActual: row.EtapaActual,
      carreraObjetivo: row.CarreraObjetivo,
    })),
    total,
    pagina,
    tamano,
    paginas: Math.ceil(total / tamano),
  };
}

export async function obtenerFichaEstudiante(
  identidad: IdentidadActiva,
  estudianteId: number,
): Promise<FichaEstudiante | null> {
  validarIdentidad(identidad);
  validarEstudianteId(estudianteId);
  const pool = await getPool();

  const perfilResult = await pool.request()
    .input('contactoId', sql.Int, identidad.contactoId ?? null)
    .input('personalInternoId', sql.Int, identidad.personalInternoId ?? null)
    .input('estudianteId', sql.Int, estudianteId)
    .query(`SELECT e.EstudianteId, e.Codigo, e.EtapaActual, e.UniversidadObjetivo,
                   e.CarreraObjetivo, e.FechaExamen, e.DisponibilidadSemanalHoras,
                   e.Parentesco, e.FechaRegistro,
                   ec.ContactoId, ec.NombreCompleto, ec.Correo, ec.Telefono,
                   ac.ContactoId AS ApoderadoContactoId, ac.NombreCompleto AS ApoderadoNombre,
                   ac.Correo AS ApoderadoCorreo, ac.Telefono AS ApoderadoTelefono
            FROM dbo.Estudiante e
            JOIN dbo.Contacto ec ON ec.ContactoId = e.ContactoId
            LEFT JOIN dbo.Apoderado ap ON ap.ApoderadoId = e.ApoderadoId
            LEFT JOIN dbo.Contacto ac ON ac.ContactoId = ap.ContactoId
            WHERE e.EstudianteId = @estudianteId AND ${accesoIdentidad}`);

  if (perfilResult.recordset.length === 0) return null;
  const perfil = perfilResult.recordset[0];

  const periodosResult = await pool.request()
    .input('estudianteId', sql.Int, estudianteId)
    .query(`SELECT s.SuscripcionId, s.Estado AS EstadoSuscripcion, s.RenovacionAutomatica,
                   s.FechaContratacion, p.PeriodoServicioId, p.Tipo, p.Inicio, p.Fin,
                   p.EstadoAcceso, p.BecaPorcentaje, p.ImporteExigiblePEN,
                   pl.PlanServicioId, pl.Nombre AS PlanNombre, mp.Meses,
                   CASE WHEN s.Estado = 'VIGENTE' AND p.Inicio <= GETDATE() AND p.Fin > GETDATE()
                              AND p.EstadoAcceso IN ('HABILITADO','CON_INCIDENCIA')
                        THEN 1 ELSE 0 END AS VigenteAhora,
                   ISNULL(pg.CobrosConfirmados, 0) AS CobrosConfirmados,
                   ISNULL(pg.ImporteCobradoPEN, 0) AS ImporteCobradoPEN,
                   ISNULL(pg.OperacionesCorrectivas, 0) AS OperacionesCorrectivas,
                   b.FechaBaja, b.Tipo AS TipoBaja, b.MotivoComunicado, b.ElegibleReactivacion
            FROM dbo.Suscripcion s
            JOIN dbo.PeriodoServicio p ON p.SuscripcionId = s.SuscripcionId
            JOIN dbo.ModalidadPlan mp ON mp.ModalidadPlanId = p.ModalidadPlanId
            JOIN dbo.PlanServicio pl ON pl.PlanServicioId = mp.PlanServicioId
            LEFT JOIN dbo.BajaServicio b ON b.PeriodoServicioId = p.PeriodoServicioId
            LEFT JOIN (
                SELECT PeriodoServicioId,
                       COUNT(CASE WHEN Tipo = 'COBRO' AND Estado = 'CONFIRMADO' THEN 1 END) AS CobrosConfirmados,
                       SUM(CASE WHEN Tipo = 'COBRO' AND Estado = 'CONFIRMADO' THEN ImportePEN ELSE 0 END) AS ImporteCobradoPEN,
                       COUNT(CASE WHEN Tipo <> 'COBRO' AND Estado = 'CONFIRMADO' THEN 1 END) AS OperacionesCorrectivas
                FROM dbo.Pago
                GROUP BY PeriodoServicioId
            ) pg ON pg.PeriodoServicioId = p.PeriodoServicioId
            WHERE s.EstudianteId = @estudianteId
            ORDER BY p.Inicio DESC, p.PeriodoServicioId DESC`);

  const filas = periodosResult.recordset.map((row) => ({
    suscripcionId: row.SuscripcionId,
    estadoSuscripcion: row.EstadoSuscripcion,
    renovacionAutomatica: Boolean(row.RenovacionAutomatica),
    fechaContratacion: row.FechaContratacion,
    periodoServicioId: row.PeriodoServicioId,
    tipo: row.Tipo,
    inicio: row.Inicio,
    fin: row.Fin,
    estadoAcceso: row.EstadoAcceso,
    becaPorcentaje: row.BecaPorcentaje,
    importeExigiblePEN: row.ImporteExigiblePEN,
    plan: row.PlanNombre,
    meses: row.Meses,
    cobrosConfirmados: Number(row.CobrosConfirmados),
    importeCobradoPEN: Number(row.ImporteCobradoPEN),
    operacionesCorrectivas: Number(row.OperacionesCorrectivas),
    fechaBaja: row.FechaBaja,
    tipoBaja: row.TipoBaja,
    motivoComunicado: row.MotivoComunicado,
    elegibleReactivacion: row.ElegibleReactivacion === null ? null : Boolean(row.ElegibleReactivacion),
    esActual: false,
    vigenteAhora: Boolean(row.VigenteAhora),
    planServicioId: row.PlanServicioId,
  }));

  const filaActual = filas.find((fila) => fila.vigenteAhora) ?? null;
  const periodos: Periodo[] = filas.map(({ vigenteAhora, planServicioId, ...periodo }) => ({
    ...periodo,
    esActual: periodo.periodoServicioId === filaActual?.periodoServicioId,
  }));
  const servicioActual = periodos.find(
    (periodo) => periodo.periodoServicioId === filaActual?.periodoServicioId,
  ) ?? null;
  const historial = periodos.filter(
    (periodo) => periodo.periodoServicioId !== filaActual?.periodoServicioId,
  );

  let prestaciones: { codigo: string; descripcion: string }[] = [];
  if (filaActual) {
    const prestacionesResult = await pool.request()
      .input('planServicioId', sql.Int, filaActual.planServicioId)
      .query(`SELECT pr.Codigo, pr.Descripcion
              FROM dbo.PlanPrestacion pp
              JOIN dbo.Prestacion pr ON pr.PrestacionId = pp.PrestacionId
              WHERE pp.PlanServicioId = @planServicioId
              ORDER BY pr.Codigo`);
    prestaciones = prestacionesResult.recordset.map((row) => ({
      codigo: row.Codigo,
      descripcion: row.Descripcion,
    }));
  }

  return {
    estudiante: {
      estudianteId: perfil.EstudianteId,
      codigo: perfil.Codigo,
      nombreCompleto: perfil.NombreCompleto,
      correo: perfil.Correo,
      telefono: perfil.Telefono,
      etapaActual: perfil.EtapaActual,
      universidadObjetivo: perfil.UniversidadObjetivo,
      carreraObjetivo: perfil.CarreraObjetivo,
      fechaExamen: perfil.FechaExamen,
      disponibilidadSemanalHoras: perfil.DisponibilidadSemanalHoras,
      parentesco: perfil.Parentesco,
      fechaRegistro: perfil.FechaRegistro,
    },
    apoderado: perfil.ApoderadoContactoId === null ? null : {
      contactoId: perfil.ApoderadoContactoId,
      nombreCompleto: perfil.ApoderadoNombre,
      correo: perfil.ApoderadoCorreo,
      telefono: perfil.ApoderadoTelefono,
    },
    servicioActual,
    historial,
    prestaciones,
  };
}
