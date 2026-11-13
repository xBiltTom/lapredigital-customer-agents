import { defineChannel, GET, POST } from "eve/channels";
import { z } from "zod";
import { dueno } from "../../lib/seguridad/identidad.ts";
import { getPrisma } from "../../lib/database/prisma.ts";
import {
  listarPersonas,
  guardarEstudiante,
  guardarApoderado,
} from "../../lib/administracion/personas.ts";
import { catalogo, guardarRecurso } from "../../lib/administracion/catalogo.ts";
import {
  listarRutas,
  publicarRuta,
  agregarActividad,
  listarCasos,
  abrirCaso,
  atenderCaso,
} from "../../lib/administracion/academico.ts";
const idSchema = z.coerce.number().int().positive().max(2147483647);
// Prisma convierte sus decimales a texto mediante toJSON, sin perder precisión.
const json = (data: unknown, status = 200) =>
  Response.json(JSON.parse(JSON.stringify(data)), {
    status,
    headers: { "cache-control": "no-store" },
  });
function error(e: unknown) {
  if (e instanceof z.ZodError)
    return json({ error: e.issues.map((x) => x.message).join(". ") }, 400);
  const code = (e as { code?: string })?.code;
  if (code === "P2002")
    return json({ error: "Ese código o vínculo ya está registrado." }, 409);
  if (code === "P2025") return json({ error: "Registro inexistente." }, 404);
  return json(
    {
      error:
        e instanceof Error && !code
          ? e.message
          : "No se pudo completar la operación. Revisa los datos.",
    },
    409,
  );
}
export default defineChannel({
  routes: [
    GET("/api/admin/:recurso", async (request, { params }) => {
      if (!(await dueno(request)))
        return json({ error: "Acceso requerido" }, 401);
      try {
        const u = new URL(request.url),
          buscar = (u.searchParams.get("buscar") ?? "").slice(0, 160),
          pagina = z.coerce
            .number()
            .int()
            .min(1)
            .max(10000)
            .parse(u.searchParams.get("pagina") ?? 1),
          r = params.recurso;
        if (r === "estudiantes" || r === "apoderados")
          return json(await listarPersonas(r, buscar, pagina));
        if (r === "rutas") return json(await listarRutas());
        if (r === "casos")
          return json(
            await listarCasos(buscar, pagina, {
              tipo: u.searchParams.get("tipo") || undefined,
              ambito: u.searchParams.get("ambito") || undefined,
              estado: u.searchParams.get("estado") || undefined,
            }),
          );
        if (r === "opciones") {
          const p = getPrisma();
          return json({
            estudiantes: await p.estudiante.findMany({
              select: {
                EstudianteId: true,
                Codigo: true,
                contacto: { select: { NombreCompleto: true } },
              },
              orderBy: { Codigo: "asc" },
              take: 500,
            }),
            apoderados: await p.apoderado.findMany({
              include: { contacto: true },
              take: 500,
            }),
            temas: await p.tema.findMany({
              include: { curso: true },
              orderBy: { TemaId: "asc" },
            }),
            recursos: await p.recursoAcademico.findMany({
              where: { Activo: true },
              orderBy: { Titulo: "asc" },
              take: 500,
            }),
          });
        }
        if (
          ["cursos", "temas", "recursos", "planes", "temas-recursos"].includes(
            r,
          )
        )
          return json(await catalogo(r, buscar, pagina));
        return json({ error: "Vista inexistente" }, 404);
      } catch (e) {
        return error(e);
      }
    }),
    POST("/api/admin/:recurso/:id", async (request, { params }) => {
      const owner = await dueno(request);
      if (!owner) return json({ error: "Acceso requerido" }, 401);
      try {
        const body = await request.json(),
          r = params.recurso,
          id = params.id === "nuevo" ? null : idSchema.parse(params.id);
        if (r === "estudiantes") return json(await guardarEstudiante(id, body));
        if (r === "apoderados") return json(await guardarApoderado(id, body));
        if (r === "recursos") return json(await guardarRecurso(id, body));
        if (r === "rutas" && id === null)
          return json(await publicarRuta(owner.id, body));
        if (r === "actividades" && id === null)
          return json(await agregarActividad(body));
        if (r === "casos")
          return json(
            id === null
              ? await abrirCaso(owner.id, body)
              : await atenderCaso(owner.id, id, body),
          );
        return json({ error: "Operación no disponible" }, 404);
      } catch (e) {
        return error(e);
      }
    }),
  ],
});
