import type { diagnostico } from "./diagnostico.ts";

type Diagnostico = Awaited<ReturnType<typeof diagnostico>>;

// Proyección académica compartida. Ningún mensaje privado ni riesgo llega al participante.
export function proyectarRendimiento(d: Diagnostico, rol: string) {
  const intentos = [...d.intentos].sort(
    (a, b) => +b.fecha - +a.fecha || b.id - a.id,
  );
  const actividades = d.actividades.filter((a) => a.rutaId === d.ruta?.id);
  return {
    estudianteId: d.estudianteId,
    nombreEstudiante: d.ficha.estudiante.nombreCompleto,
    nombreInterlocutor:
      rol === "APODERADO"
        ? d.ficha.apoderado?.nombreCompleto
        : d.ficha.estudiante.nombreCompleto,
    corte: d.corte,
    plan: d.ficha.servicioActual?.plan ?? null,
    servicio: d.ficha.servicioActual
      ? {
          inicio: d.ficha.servicioActual.inicio,
          fin: d.ficha.servicioActual.fin,
        }
      : null,
    prestaciones: d.ficha.prestaciones.map((p) => p.codigo),
    objetivo: {
      carrera: d.ficha.estudiante.carreraObjetivo,
      fechaExamen: d.ficha.estudiante.fechaExamen,
    },
    ruta: d.ruta,
    cumplimiento: {
      ...d.cumplimiento,
      desde: d.inicio,
      hasta: d.corte,
      estado: d.cumplimiento.porcentaje === null ? "NO_APLICABLE" : "CON_DATOS",
    },
    evaluaciones: {
      estado: intentos.length ? "CON_DATOS" : "SIN_REGISTROS",
      total: intentos.length,
      recientes: intentos.slice(0, 5),
      masResultados: intentos.length > 5,
    },
    evolucion: {
      estado: d.mejoras.some((m) => m.mejoraPP !== null)
        ? "CON_DATOS"
        : intentos.length
          ? "SIN_COMPARABILIDAD"
          : "SIN_REGISTROS",
      alcance:
        "Primer y último intento de cada grupo comparable hasta el corte; no limitado a 30 días",
      grupos: d.mejoras,
    },
    actividades: {
      total: actividades.length,
      pendientes: actividades
        .filter((a) => !["COMPLETADA", "CANCELADA"].includes(a.estado))
        .sort((a, b) => +a.limite - +b.limite)
        .slice(0, 8),
    },
    dificultades: d.dificultades
      .filter((x) => x.estado !== "SUPERADA")
      .slice(0, 10),
    actividad: {
      ultima: d.uso,
      frecuencia: {
        ultimos7Dias: d.frecuencia.recientes,
        sieteDiasAnteriores: d.frecuencia.anteriores,
        unidad:
          "registros de actividad; no equivale a días activos ni sesiones",
      },
    },
    temario: {
      total: d.temario.length,
      completados: d.temario.filter((t) => t.estado === "COMPLETADA").length,
    },
    fuentes: [
      "IntentoEvaluacion",
      "GrupoComparabilidad",
      "RutaEstudio",
      "ActividadRuta",
      "DificultadAcademica",
      "EventoUso",
      "ProgresoTemaUNT",
    ],
  };
}

export function proyectarRiesgo(d: Diagnostico) {
  return {
    estudianteId: d.estudianteId,
    nombre: d.ficha.estudiante.nombreCompleto,
    corte: d.corte,
    riesgo: d.riesgo,
    reglas: d.reglas,
    versionReglas: d.versionReglas,
    huella: d.huella,
    narrativaPendiente: d.narrativaPendiente,
    contexto: d.contexto,
    mensajes: d.mensajes,
    valoraciones: d.valoraciones,
    casos: d.casos,
    dificultades: d.dificultades,
    uso: d.uso,
    seguimiento: d.seguimiento,
    evaluacionGuardada: d.evaluacionGuardada,
    acciones: d.acciones,
  };
}
