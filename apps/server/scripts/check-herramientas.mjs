// Verificación dirigida: no prepara ni reconstruye SQL; solo acepta la base aislada.
import assert from "node:assert/strict";
import { readdir } from "node:fs/promises";
if (process.env.SQLSERVER_DATABASE !== "LaPreDigital_Customers_MvpTest")
  throw new Error("Usar solo LaPreDigital_Customers_MvpTest.");
const { getPool, closePool } = await import("../lib/database/pool.ts");
const { getReadOnlyPool, closeReadOnlyPool } = await import(
  "../lib/database/lectura.ts"
);
const { consultarDatosNegocio, consultaNegocioSchema } = await import(
  "../lib/servicios/consultas-negocio.ts"
);
const { herramienta: rendimiento } = await import(
  "../agent/tools/consultar_rendimiento.ts"
);
const { herramienta: registros } = await import(
  "../agent/tools/consultar_registros.ts"
);
const owner = {
  authenticator: "dueno-local",
  attributes: {
    personalInternoId: process.env.OWNER_PERSONAL_ID,
    modo: "global",
  },
};
const authAlumno = (e) => ({
  ...owner,
  attributes: {
    ...owner.attributes,
    modo: "participante",
    estudianteId: String(e),
    rol: "ESTUDIANTE",
    canal: "MENSAJERIA",
  },
});
const ctx = (auth) => ({ session: { auth: { current: auth } } });
try {
  const pool = await getPool();
  const alumnos = (
    await pool
      .request()
      .query(
        "SELECT EstudianteId id,Codigo codigo FROM dbo.Estudiante WHERE Codigo IN('C001','C004','C007')",
      )
  ).recordset;
  assert.equal(alumnos.length, 3);
  for (const e of alumnos) {
    const r = await rendimiento.execute({}, ctx(authAlumno(e.id)));
    assert.equal(r.nombreInterlocutor, r.nombreEstudiante);
    assert.ok(!Object.hasOwn(r, "riesgo") && !Object.hasOwn(r, "mensajes"));
    if (e.codigo === "C001")
      assert.ok(
        r.evolucion.grupos.some((g) => Math.abs(g.mejoraPP - 15) < 1e-6),
      );
    if (e.codigo === "C004") {
      assert.equal(r.evaluaciones.estado, "CON_DATOS");
      assert.equal(r.evolucion.estado, "SIN_COMPARABILIDAD");
    }
    if (e.codigo === "C007")
      assert.equal(r.evaluaciones.estado, "SIN_REGISTROS");
    console.log(e.codigo, r.evaluaciones.estado, r.evolucion.estado);
  }
  const ana = alumnos.find((e) => e.codigo === "C001");
  await assert.rejects(
    rendimiento.execute({ estudianteId: ana.id + 1 }, ctx(authAlumno(ana.id))),
    /Solo puedes/,
  );
  const datos = registros.inputSchema.parse({
    recurso: "EVALUACIONES",
    pagina: 100,
  });
  const vacia = await registros.execute(datos, ctx(authAlumno(ana.id)));
  assert.equal(vacia.registros.length, 0);
  assert.ok(vacia.total >= 2);
  const pago = await registros.execute(
    registros.inputSchema.parse({ recurso: "PAGOS" }),
    ctx(authAlumno(ana.id)),
  );
  assert.ok(
    pago.registros.every((r) => !Object.hasOwn(r, "pagadorContactoId")),
  );
  const futuro = await pool
    .request()
    .query(
      "SELECT TOP(1) s.EstudianteId e FROM dbo.PeriodoServicio p JOIN dbo.Suscripcion s ON s.SuscripcionId=p.SuscripcionId WHERE p.Inicio>GETDATE()",
    );
  if (futuro.recordset[0]) {
    const servicio = await registros.execute(
      registros.inputSchema.parse({ recurso: "SERVICIO", orden: "RECIENTE" }),
      ctx(authAlumno(futuro.recordset[0].e)),
    );
    assert.ok(servicio.registros.some((p) => new Date(p.fecha) > new Date()));
    console.log("Servicio futuro consultable");
  }
  const leer = (b) =>
    consultarDatosNegocio(owner, consultaNegocioSchema.parse(b));
  const catalogo = await leer({ accion: "CATALOGO", tabla: "Suscripcion" });
  assert.ok(catalogo.relaciones.some((r) => r.destino === "Estudiante"));
  const conteo = await leer({
    accion: "CONSULTAR",
    tabla: "Estudiante",
    medidas: [{ operacion: "CONTAR", alias: "cantidad" }],
  });
  assert.ok(Number(conteo.registros[0].cantidad) >= 14);
  const unidos = await leer({
    accion: "CONSULTAR",
    tabla: "Suscripcion",
    alias: "s",
    relaciones: [{ tabla: "Estudiante", alias: "e", desde: "s" }],
    columnas: ["e.Codigo", "s.Estado"],
    limite: 3,
  });
  assert.equal(unidos.registros.length, 3);
  const grupos = await leer({
    accion: "CONSULTAR",
    tabla: "Pago",
    alias: "p",
    agruparPor: ["p.Estado"],
    medidas: [{ operacion: "SUMAR", campo: "p.ImportePEN", alias: "importe" }],
  });
  assert.ok(grupos.registros.length > 0);
  await assert.rejects(
    consultarDatosNegocio(
      authAlumno(ana.id),
      consultaNegocioSchema.parse({ accion: "CATALOGO" }),
    ),
    /contexto/,
  );
  const lector = await getReadOnlyPool();
  await assert.rejects(
    lector
      .request()
      .query("UPDATE dbo.Contacto SET NombreCompleto=NombreCompleto WHERE 1=0"),
    (e) => e.number === 229,
  );
  console.log(
    "Consultas, agregaciones, relaciones y denegación SQL de escritura correctas",
  );

  // El repositorio usa transacción propia. Una exterior permite comprobar reintentos
  // reales y revertir tanto consultas como bloqueos de contacto en MvpTest.
  const sql = (await import("mssql")).default;
  const { GUARDAR_CONSULTA_DUENO } = await import(
    "../lib/database/consultas/plataforma.ts"
  );
  const contacto = (
    await pool
      .request()
      .input("e", ana.id)
      .query("SELECT ContactoId id FROM dbo.Estudiante WHERE EstudianteId=@e")
  ).recordset[0].id;
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const guardar = async (texto) =>
      (
        await new sql.Request(tx)
          .input("e", ana.id)
          .input("c", contacto)
          .input("r", "ESTUDIANTE")
          .input("canal", "ACADEMIA")
          .input("p", texto)
          .query(GUARDAR_CONSULTA_DUENO)
      ).recordset[0].id;
    const pregunta = "Verificación M30 " + Date.now();
    assert.equal(await guardar(pregunta), await guardar(pregunta));
    const bloqueo = "NO_CONTACTO: " + pregunta;
    const idBloqueo = await guardar(bloqueo);
    await new sql.Request(tx)
      .input("id", idBloqueo)
      .query(
        "UPDATE dbo.ConsultaDueno SET Estado='RESPONDIDA' WHERE ConsultaId=@id",
      );
    assert.equal(await guardar(bloqueo), idBloqueo);
  } finally {
    await tx.rollback();
  }
  console.log(
    "Reintentos de consulta y no contacto verificados; transacción revertida",
  );

  // Eve rc.10 guarda el resolver dinámico en un símbolo. Solo lo inspecciona esta prueba.
  const disponibles = async (auth) => {
    const lista = [];
    for (const file of await readdir(
      new URL("../agent/tools/", import.meta.url),
    )) {
      if (!file.endsWith(".ts")) continue;
      const { default: dynamic } = await import(
        new URL("../agent/tools/" + file, import.meta.url)
      );
      const resolver = Object.getOwnPropertySymbols(dynamic)
        .map((s) => dynamic[s])
        .find((v) => typeof v === "function");
      assert.ok(resolver, file + " debe ser dinámica");
      if (await resolver(ctx(auth))) lista.push(file.slice(0, -3));
    }
    return lista.sort();
  };
  const participante = await disponibles(authAlumno(ana.id));
  assert.deepEqual(participante, [
    "consultar_registros",
    "consultar_rendimiento",
    "consultar_temario",
    "gestionar_caso",
    "gestionar_consulta_dueno",
    "registrar_no_contacto",
  ]);
  assert.deepEqual(
    await disponibles({
      ...owner,
      attributes: {
        ...owner.attributes,
        modo: "individual",
        estudianteId: String(ana.id),
        soloLectura: "true",
      },
    }),
    [],
  );
  console.log("Catálogo real del participante:", participante.join(", "));
} finally {
  const { getPrisma } = await import("../lib/database/prisma.ts");
  await getPrisma().$disconnect();
  await closePool();
  await closeReadOnlyPool();
}
