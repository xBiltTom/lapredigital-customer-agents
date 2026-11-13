// Verificación focalizada: escrituras exclusivamente en la base aislada del MVP.
import assert from "node:assert/strict";
import { getPrisma } from "../lib/database/prisma.ts";
import {
  guardarEstudiante,
  guardarApoderado,
} from "../lib/administracion/personas.ts";
import { guardarRecurso } from "../lib/administracion/catalogo.ts";
import {
  publicarRuta,
  agregarActividad,
  abrirCaso,
  atenderCaso,
} from "../lib/administracion/academico.ts";
if (process.env.SQLSERVER_DATABASE !== "LaPreDigital_Customers_MvpTest")
  throw new Error("Esta comprobación solo escribe en MvpTest.");
const p = getPrisma();
try {
  const guardian = await guardarApoderado(null, {
    NombreCompleto: "Apoderado verificación admin",
    Correo: "",
    Telefono: "999000111",
  });
  const profile = {
    NombreCompleto: "Estudiante verificación admin",
    Correo: "estudiante@example.test",
    Telefono: "999000222",
    Codigo: "ADMIN-CHECK",
    UniversidadObjetivo: "Universidad Nacional de Trujillo",
    CarreraObjetivo: "Sistemas",
    FechaExamen: "2027-03-15",
    DisponibilidadSemanalHoras: 12,
    ApoderadoId: guardian.id,
    Parentesco: "PADRE",
  };
  const student = await guardarEstudiante(null, profile);
  assert.equal(
    (
      await p.estudiante.findUniqueOrThrow({
        where: { EstudianteId: student.id },
      })
    ).EtapaActual,
    "LEAD",
  );
  const route = await publicarRuta(1, {
    EstudianteId: student.id,
    Objetivo: "Preparación UNT",
    FechaExamenObjetivo: "2027-03-15",
    copiarActividades: false,
  });
  await guardarEstudiante(student.id, {
    ...profile,
    CarreraObjetivo: "Medicina",
  });
  assert.equal(
    await p.revisionRuta.count({
      where: { RutaEstudioId: route.id, Estado: "PENDIENTE" },
    }),
    1,
  );
  const resource = await guardarRecurso(null, {
    TemaId: 1,
    Titulo: "Recurso verificación admin",
    Tipo: "PDF",
    Ubicacion: "https://example.test/material.pdf",
    DuracionEstimadaMin: 30,
    Activo: true,
  });
  await guardarRecurso(resource.id, {
    TemaId: 1,
    Titulo: "Recurso verificación admin",
    Tipo: "PDF",
    Ubicacion: "",
    DuracionEstimadaMin: 30,
    Activo: true,
  });
  await agregarActividad({
    RutaEstudioId: route.id,
    RecursoAcademicoId: resource.id,
    FechaPlanificada: "2026-11-14",
    FechaLimite: "2026-11-15",
  });
  const next = await publicarRuta(1, {
    EstudianteId: student.id,
    Objetivo: "Preparación actualizada",
    FechaExamenObjetivo: "2027-03-15",
    copiarActividades: true,
  });
  assert.equal(next.version, 2);
  assert.equal(
    await p.rutaEstudio.count({
      where: { EstudianteId: student.id, Vigente: true },
    }),
    1,
  );
  assert.equal(
    await p.actividadRuta.count({ where: { RutaEstudioId: next.id } }),
    1,
  );
  const dates =
    await p.$queryRaw`SELECT CONVERT(varchar(19),FechaPlanificada,126) fecha FROM dbo.ActividadRuta WHERE RutaEstudioId=${next.id}`;
  assert.equal(dates[0].fecha, "2026-11-14T00:00:00");
  const incident = await abrirCaso(1, {
    EstudianteId: student.id,
    Tipo: "INCIDENCIA",
    Ambito: "SERVICIO",
    Descripcion: "Consulta de verificación administrativa",
  });
  const opening = (
    await p.casoAtencion.findUniqueOrThrow({
      where: { CasoAtencionId: incident.id },
    })
  ).FechaAperturaOriginal;
  await atenderCaso(1, incident.id, {
    Estado: "EN_ATENCION",
    Detalle: "Revisión iniciada",
  });
  await atenderCaso(1, incident.id, {
    Estado: "RESUELTA",
    Detalle: "Atención concluida",
  });
  await atenderCaso(1, incident.id, {
    Estado: "REABIERTA",
    Detalle: "El estudiante requiere nueva revisión",
  });
  const c = await p.casoAtencion.findUniqueOrThrow({
    where: { CasoAtencionId: incident.id },
  });
  assert.equal(c.FechaAperturaOriginal.toISOString(), opening.toISOString());
  assert.equal(c.FechaResolucionDefinitiva, null);
  assert.equal(
    await p.eventoCaso.count({ where: { CasoAtencionId: incident.id } }),
    4,
  );
  console.log(
    "OK: perfiles/vínculos, recursos, revisión y versión de ruta, fechas, actividades y ciclo de incidencia. Solo MvpTest.",
  );
} finally {
  await p.$disconnect();
}
