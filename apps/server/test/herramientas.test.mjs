import test from "node:test";
import assert from "node:assert/strict";
import {
  permiteHerramienta,
  alumnoDelContexto,
} from "../lib/seguridad/alcance-herramientas.ts";
import {
  construirConsultaNegocio,
  consultaNegocioSchema,
} from "../lib/servicios/consultas-negocio.ts";
import { proyectarRendimiento } from "../lib/academico/rendimiento.ts";

const auth = (modo, extra = {}) => ({
  authenticator: "dueno-local",
  attributes: {
    personalInternoId: "1",
    estudianteId: "3",
    modo,
    rol: "ESTUDIANTE",
    canal: "MENSAJERIA",
    ...extra,
  },
});

test("el catálogo separa global, individual, participante, canal y análisis sin herramientas", () => {
  const permisos = [
    "lectura",
    "dueno",
    "global",
    "participante",
    "casos",
    "registros",
  ];
  const disponibles = (a) => permisos.filter((p) => permiteHerramienta(a, p));
  assert.deepEqual(disponibles(auth("global")), [
    "lectura",
    "dueno",
    "global",
    "casos",
  ]);
  assert.deepEqual(disponibles(auth("individual")), [
    "lectura",
    "dueno",
    "casos",
    "registros",
  ]);
  assert.deepEqual(disponibles(auth("participante")), [
    "lectura",
    "participante",
    "casos",
    "registros",
  ]);
  assert.deepEqual(disponibles(auth("participante", { canal: "ACADEMIA" })), [
    "lectura",
    "participante",
    "registros",
  ]);
  for (const a of [
    null,
    auth("otro"),
    auth("individual", { soloLectura: "true" }),
    auth("participante", { rol: "DUEÑO" }),
    { ...auth("global"), authenticator: "otro" },
  ])
    assert.deepEqual(disponibles(a), []);
  assert.throws(
    () => alumnoDelContexto(auth("participante"), 8),
    /Solo puedes/,
  );
  assert.throws(
    () => alumnoDelContexto(auth("global")),
    /Indica el estudiante/,
  );
  assert.equal(alumnoDelContexto(auth("global"), 8), 8);
});

const catalogo = {
  columnas: [
    { tabla: "Estudiante", columna: "EstudianteId", tipo: "int", orden: 1 },
    { tabla: "Estudiante", columna: "Codigo", tipo: "varchar", orden: 2 },
    { tabla: "Suscripcion", columna: "EstudianteId", tipo: "int", orden: 1 },
    { tabla: "Suscripcion", columna: "Estado", tipo: "varchar", orden: 2 },
    { tabla: "Pago", columna: "ImportePEN", tipo: "decimal", orden: 1 },
  ],
  relaciones: [
    {
      nombre: "FK_Suscripcion_Estudiante",
      origen: "Suscripcion",
      columnaOrigen: "EstudianteId",
      destino: "Estudiante",
      columnaDestino: "EstudianteId",
      orden: 1,
    },
  ],
};
const entrada = (b) =>
  consultaNegocioSchema.parse({
    accion: "CONSULTAR",
    tabla: "Estudiante",
    alias: "e",
    ...b,
  });

test("consultas de negocio parametrizan valores y rechazan campos, tablas o relaciones arbitrarias", () => {
  const ataque = "'; DELETE FROM dbo.Estudiante;--";
  const plan = construirConsultaNegocio(
    entrada({
      columnas: ["e.Codigo"],
      filtros: [{ campo: "e.Codigo", operador: "IGUAL", valor: ataque }],
    }),
    catalogo,
  );
  assert.ok(!plan.sql.includes(ataque));
  assert.equal(plan.parametros[0].valor, ataque);
  assert.throws(
    () =>
      construirConsultaNegocio(
        entrada({ columnas: ["e.Codigo;DELETE"] }),
        catalogo,
      ),
    /Campo no disponible/,
  );
  assert.throws(() => entrada({ tabla: "syslogins" }));
  assert.throws(
    () =>
      construirConsultaNegocio(
        entrada({ relaciones: [{ tabla: "Pago", alias: "p", desde: "e" }] }),
        catalogo,
      ),
    /claveForanea/,
  );
});

test("las relaciones se resuelven con claves del catálogo y las agregaciones conservan semántica", () => {
  const plan = construirConsultaNegocio(
    entrada({
      relaciones: [{ tabla: "Suscripcion", alias: "s", desde: "e" }],
      agruparPor: ["s.Estado"],
      medidas: [
        {
          operacion: "CONTAR_DISTINTOS",
          campo: "e.EstudianteId",
          alias: "cantidad",
        },
      ],
    }),
    catalogo,
  );
  assert.match(plan.sql, /\[e\]\.\[EstudianteId\]=\[s\]\.\[EstudianteId\]/);
  assert.match(plan.sql, /COUNT_BIG\(DISTINCT/);
  assert.match(plan.sql, /GROUP BY \[s\]\.\[Estado\]/);
  assert.throws(
    () =>
      construirConsultaNegocio(
        entrada({
          medidas: [{ operacion: "SUMAR", campo: "e.Codigo", alias: "total" }],
        }),
        catalogo,
      ),
    /numérico/,
  );
  assert.throws(
    () =>
      construirConsultaNegocio(
        entrada({ filtros: [{ campo: "e.Codigo", operador: "IGUAL" }] }),
        catalogo,
      ),
    /necesita un valor/,
  );
});

function diagnostico(intentos, mejoras) {
  return {
    estudianteId: 1,
    corte: new Date("2026-11-13T10:00:00-05:00"),
    inicio: new Date("2026-10-14T10:00:00-05:00"),
    ficha: {
      estudiante: {
        nombreCompleto: "Ana",
        carreraObjetivo: "Medicina",
        fechaExamen: null,
      },
      apoderado: { nombreCompleto: "Rosa" },
      servicioActual: { plan: "Plus" },
      prestaciones: [],
    },
    intentos,
    mejoras,
    actividades: [],
    ruta: null,
    cumplimiento: { planificadas: 0, completadas: 0, porcentaje: null },
    dificultades: [],
    uso: null,
    frecuencia: { recientes: 3, anteriores: 1 },
    temario: [{ estado: "COMPLETADA" }, { estado: "PENDIENTE" }],
    riesgo: { nivel: "ALTO", motivo: "PRIVADO" },
    mensajes: [{ contenido: "PRIVADO" }],
  };
}

test("rendimiento muestra resultados aunque no haya mejora comparable y excluye datos internos", () => {
  const d = diagnostico(
    [{ id: 1, fecha: new Date(), aciertos: 12, total: 20 }],
    [{ mejoraPP: null }],
  );
  const r = proyectarRendimiento(d, "APODERADO");
  assert.equal(r.nombreInterlocutor, "Rosa");
  assert.equal(r.evaluaciones.total, 1);
  assert.equal(r.evolucion.estado, "SIN_COMPARABILIDAD");
  assert.equal(r.cumplimiento.estado, "NO_APLICABLE");
  assert.deepEqual(r.temario, { total: 2, completados: 1 });
  assert.equal(r.actividad.frecuencia.ultimos7Dias, 3);
  assert.equal(r.actividad.frecuencia.sieteDiasAnteriores, 1);
  assert.ok(!JSON.stringify(r).includes("PRIVADO"));
  assert.equal(
    proyectarRendimiento(diagnostico([], []), "ESTUDIANTE").evaluaciones.estado,
    "SIN_REGISTROS",
  );
  assert.equal(
    proyectarRendimiento(diagnostico([], [{ mejoraPP: 15 }]), "ESTUDIANTE")
      .evolucion.estado,
    "CON_DATOS",
  );
});
