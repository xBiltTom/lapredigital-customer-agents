import { defineDynamic } from "eve";
import { obtenerDuenoActivo } from "../database/identidad.ts";
import { obtenerFichaEstudiante } from "../database/estudiantes.ts";
import { getPool } from "../database/pool.ts";
import sql from "mssql";

export type AuthHerramienta = {
  authenticator?: string;
  attributes?: Readonly<Record<string, string | readonly string[]>>;
} | null;
export type AccesoHerramienta =
  | "lectura"
  | "dueno"
  | "global"
  | "participante"
  | "casos"
  | "registros";

// La misma regla decide visibilidad y ejecución. Ocultar una herramienta no basta.
export function permiteHerramienta(
  auth: AuthHerramienta,
  acceso: AccesoHerramienta,
) {
  const a = auth?.attributes;
  if (auth?.authenticator !== "dueno-local" || a?.soloLectura === "true")
    return false;
  const owner = Number(a?.personalInternoId);
  if (!Number.isSafeInteger(owner) || owner < 1) return false;
  if (!["global", "individual", "participante"].includes(String(a?.modo)))
    return false;
  if (
    a?.modo !== "global" &&
    (!Number.isSafeInteger(Number(a?.estudianteId)) ||
      Number(a?.estudianteId) < 1)
  )
    return false;
  if (
    a?.modo === "participante" &&
    (!["ESTUDIANTE", "APODERADO"].includes(String(a.rol)) ||
      !["ACADEMIA", "MENSAJERIA"].includes(String(a.canal)))
  )
    return false;
  if (acceso === "global") return a?.modo === "global";
  if (acceso === "dueno") return a?.modo !== "participante";
  if (acceso === "participante") return a?.modo === "participante";
  if (acceso === "registros") return a?.modo !== "global";
  if (acceso === "casos")
    return a?.modo !== "participante" || a.canal === "MENSAJERIA";
  return true;
}

export function exigirHerramienta(
  auth: AuthHerramienta,
  acceso: AccesoHerramienta,
) {
  if (!permiteHerramienta(auth, acceso))
    throw new Error(
      "Esta operación no corresponde al contexto de la conversación.",
    );
  return auth!.attributes!;
}

export function herramientaPorModo<T>(
  acceso: AccesoHerramienta,
  herramienta: T,
) {
  return defineDynamic((ctx) =>
    permiteHerramienta(ctx.session.auth.current, acceso) ? herramienta : null,
  );
}

export async function autorizarHerramienta(
  auth: AuthHerramienta,
  acceso: AccesoHerramienta,
) {
  const a = exigirHerramienta(auth, acceso);
  const owner = Number(a.personalInternoId);
  if (!(await obtenerDuenoActivo(owner)))
    throw new Error("La identidad del dueño ya no está activa.");
  return { a, owner };
}

export function alumnoDelContexto(auth: AuthHerramienta, solicitado?: number) {
  const a = exigirHerramienta(auth, "lectura");
  const e = a.modo === "global" ? solicitado : Number(a.estudianteId);
  if (!Number.isSafeInteger(e) || Number(e) < 1)
    throw new Error("Indica el estudiante que quieres consultar.");
  if (a.modo !== "global" && solicitado !== undefined && solicitado !== e)
    throw new Error(
      "Solo puedes consultar al estudiante de esta conversación.",
    );
  return e!;
}

export async function autorizarAlumno(
  auth: AuthHerramienta,
  solicitado?: number,
) {
  const estudianteId = alumnoDelContexto(auth, solicitado);
  const { a, owner } = await autorizarHerramienta(auth, "lectura");
  const ficha = await obtenerFichaEstudiante(
    { personalInternoId: owner },
    estudianteId,
  );
  if (!ficha) throw new Error("El estudiante no está disponible.");
  if (a.modo === "participante") {
    if (
      a.rol === "APODERADO" &&
      !ficha.prestaciones.some((p) => p.codigo === "REPORTES_APODERADO")
    )
      throw new Error("El plan vigente no concede acceso al apoderado.");
    // Sesiones nuevas incorporan el contacto firmado. Las antiguas siguen ligadas al alumno/rol.
    if (a.contactoId) {
      const r = await (await getPool())
        .request()
        .input("e", sql.Int, estudianteId)
        .query(
          "SELECT e.ContactoId estudiante,a.ContactoId apoderado FROM dbo.Estudiante e LEFT JOIN dbo.Apoderado a ON a.ApoderadoId=e.ApoderadoId WHERE e.EstudianteId=@e",
        );
      if (
        Number(a.contactoId) !==
        Number(
          r.recordset[0]?.[a.rol === "APODERADO" ? "apoderado" : "estudiante"],
        )
      )
        throw new Error(
          "Cambió la identidad vinculada. Abre nuevamente tu acceso.",
        );
    }
  }
  return { a, owner, estudianteId, ficha };
}
