// Lista cerrada del SQL canónico. El modelo no puede consultar otras bases o tablas.
export const tablasNegocio = [
  "PersonalInterno",
  "Contacto",
  "FormularioContacto",
  "Apoderado",
  "Estudiante",
  "AutorizacionContacto",
  "PlanServicio",
  "ModalidadPlan",
  "Prestacion",
  "PlanPrestacion",
  "Suscripcion",
  "PeriodoServicio",
  "Pago",
  "CambioEtapa",
  "BajaServicio",
  "Curso",
  "Tema",
  "RecursoAcademico",
  "RutaEstudio",
  "ActividadRuta",
  "DificultadAcademica",
  "RevisionRuta",
  "GrupoComparabilidad",
  "Evaluacion",
  "IntentoEvaluacion",
  "EventoUso",
  "Conversacion",
  "Mensaje",
  "AspectoValoracion",
  "SolicitudValoracion",
  "Valoracion",
  "CasoAtencion",
  "EventoCaso",
  "PoliticaRiesgo",
  "EvaluacionRiesgo",
  "SenalRiesgo",
  "Intervencion",
  "EventoIntervencion",
  "PropuestaCambioPlan",
  "InvitacionReferido",
  "Referido",
  "ContactoHistorial",
  "EstudianteHistorial",
  "AutorizacionContactoHistorial",
  "SuscripcionHistorial",
  "PeriodoServicioHistorial",
  "BajaServicioHistorial",
  "RutaEstudioHistorial",
  "ActividadRutaHistorial",
  "DificultadAcademicaHistorial",
  "RevisionRutaHistorial",
  "CasoAtencionHistorial",
  "IntervencionHistorial",
  "PropuestaCambioPlanHistorial",
  "ReferidoHistorial",
  "TemarioUNT",
  "ContenidoUNT",
  "ProgresoTemaUNT",
  "MensajeCanalLocal",
  "ConsultaDueno",
  "ProgresoTemaUNTHistorial",
  "AtencionMensaje",
] as const;

export type ColumnaNegocio = {
  tabla: string;
  columna: string;
  tipo: string;
  orden: number;
};
export type RelacionNegocio = {
  nombre: string;
  origen: string;
  columnaOrigen: string;
  destino: string;
  columnaDestino: string;
  orden: number;
};
export type CatalogoNegocio = {
  columnas: ColumnaNegocio[];
  relaciones: RelacionNegocio[];
};

export const SQL_CATALOGO_NEGOCIO = `
SELECT t.name tabla,c.name columna,ty.name tipo,c.column_id orden
FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id
JOIN sys.columns c ON c.object_id=t.object_id JOIN sys.types ty ON ty.user_type_id=c.user_type_id
WHERE s.name='dbo' ORDER BY t.name,c.column_id;
SELECT fk.name nombre,ot.name origen,oc.name columnaOrigen,dt.name destino,dc.name columnaDestino,fc.constraint_column_id orden
FROM sys.foreign_keys fk JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=fk.object_id
JOIN sys.tables ot ON ot.object_id=fc.parent_object_id JOIN sys.schemas os ON os.schema_id=ot.schema_id
JOIN sys.tables dt ON dt.object_id=fc.referenced_object_id JOIN sys.schemas ds ON ds.schema_id=dt.schema_id
JOIN sys.columns oc ON oc.object_id=ot.object_id AND oc.column_id=fc.parent_column_id
JOIN sys.columns dc ON dc.object_id=dt.object_id AND dc.column_id=fc.referenced_column_id
WHERE os.name='dbo' AND ds.name='dbo' ORDER BY fk.name,fc.constraint_column_id;`;
