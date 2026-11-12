# Estado y punto de continuación

Actualizado: 12 de noviembre de 2026. Documento de traspaso para otra sesión o agente.

## Próxima tarea

**B01 del [roadmap reorganizado](ROADMAP.md): acceso local, conexión y build utilizables.** El usuario pidió revisar el trabajo y reducir sobreingeniería. T00–T08 son nueve tareas hechas; T09 no está implementada en HEAD/origin revisados y ahora se integra en B02. La ejecución independiente de T09–T32 se sustituye por ocho bloques y cinco extensiones posteriores. Una tarea activa equivale a un commit.

## R01: revisión y arranque en CachyOS

Ver [revisión y hallazgos](REVISION_T08_Y_PLAN.md). No se implementaron correcciones del backend en esta revisión. Se encendió sql-server-local, se instalaron las dependencias del lockfile con el servidor detenido y se levantó server con Compose. Ambos servicios quedaron encendidos; no existe frontend todavía. GET http://127.0.0.1:3000/eve/v1/health devuelve 200 y ok: true.

Ejecución actual: npm ci (103 instalados/105 auditados, cero vulnerabilidades reportadas), check, typecheck y las siete pruebas existentes correctos. build:server reproduce EXDEV también en Linux al mover entre .eve y .output: no es solo Windows. Consultas administrativas de lectura dentro del contenedor confirman base ONLINE, 14 estudiantes, hora -05:00, C001 en META_UNT y ausencia del usuario lapredigital_app.

Este equipo no tiene .env; db:check falla por SQLSERVER_USER/SQLSERVER_PASSWORD ausentes y host.docker.internal da ENOTFOUND desde Docker. Se verificó disponibilidad de SQL Server, **no** integración SQL de la app. No se creó login ni se alteraron permisos/datos. db:t08 y una llamada real del modelo no se ejecutaron de nuevo. El volumen keyring_state se creó aquí al preparar Docker; no asumir que contiene el login realizado en Windows.

B01 debe resolver conexión local y build, definir el contexto del dueño y comprobar el acceso al canal/llavero. La condición de T08 acepta apoderados por vínculo sin exigir Meta UNT Plus; no exponerla sin comprobar REPORTES_APODERADO vigente. No construir ahora un portal de apoderados o un sistema completo de usuarios. B06 hará seleccionable la base aislada de integración: el z.literal actual bloquea un nombre distinto del OLTP activo.

Esta sección es el estado vigente. Las secciones T03–T08 siguientes conservan evidencia histórica de sus respectivos equipos; las frases «actual» dentro de ellas no describen necesariamente este CachyOS. Los SQL, incluidos los cambios personales del 04, se conservaron. Sin ejecución de 01/02/03/04, consumo MiniMax ni mensajes reales.

## T08: perfil, servicio y prestaciones

`apps/server/lib/database/estudiantes.ts` añade dos operaciones de solo lectura: listado paginado por identidad activa (1–50 elementos, total y páginas) y ficha por estudiante. La identidad es un `contactoId` que valida el backend; un estudiante ve su propia ficha y un apoderado solo las de sus estudiantes vinculados. Una instrucción del chat no cambia ese identificador. La ficha separa `servicioActual` (suscripción `VIGENTE`, periodo que cubre `GETDATE()` y acceso `HABILITADO`/`CON_INCIDENCIA`) del `historial`, e incluye contactos, apoderado, periodos con cobros confirmados y operaciones correctivas, baja y prestaciones del plan actual. C013 se devuelve como LEAD sin servicio ni prestaciones.

`scripts/grant-sql-read.ps1` amplió los permisos de `lapredigital_app`: SELECT de tabla sobre Estudiante, Contacto, Apoderado, Suscripcion, PeriodoServicio, ModalidadPlan, PlanServicio, Prestacion, PlanPrestacion y BajaServicio; en Pago solo `PeriodoServicioId`, `Tipo`, `Estado` e `ImportePEN`. No hay DML ni `sa`. `scripts/provision-sql-app.ps1` incluye el mismo conjunto para instalaciones nuevas. No se modificaron tablas, datos ni los scripts 01/02.

Verificación real: `docker compose run --rm --no-deps --workdir /workspace/apps/server server npm run db:t08` comprobó paginación sin duplicados con el apoderado compartido de C003/C005, C006 con beca 100 % e importe exigible 0 sin pagos, C011 con dos episodios (REACTIVACION vigente y periodo anterior FINALIZADO), C013 LEAD sin servicio, ficha de C001 denegada a la identidad de ese apoderado, rechazo de páginas fuera de rango, SELECT permitido y DML denegado en las tablas del repositorio, y acceso denegado a `Pago.CodigoOperacion`. `typecheck`, 7 pruebas y `npm run check` pasaron.

Límites: los repositorios aún no se exponen como herramientas del agente ni como endpoint; la identidad real y las sesiones se integran en T16/T20. No se paginan todavía los periodos históricos ni se probaron volúmenes grandes. El corte del servicio usa `GETDATE()`, coherente con las consultas de referencia; la serialización de fechas queda a cargo de la capa que consuma estos datos.

## T07: conexión SQL de lectura

El usuario informó que creó y pobló `LaPreDigital_Customers` en SQL Server nativo de Windows. Esta sesión consultó por autenticación integrada local con `sqlcmd -S . -E`: 14 estudiantes, SQL Server con offset -05:00, modo mixto y cuenta administradora disponible solo localmente; la conexión integrada por TCP a `127.0.0.1` devolvió error de dominio no confiable. Desde Docker se confirmó conectividad TCP a `host.docker.internal:1433`. Se leyeron el informe 7.1, los cuatro scripts SQL y la revisión histórica antes de escribir la consulta de prueba. Los scripts 01/02/03/04 no se ejecutaron aquí y las 29 pruebas siguen siendo resultados históricos.

`scripts/provision-sql-app.ps1` creó en la instancia existente `lapredigital_app`, un usuario de base con `GRANT SELECT ON dbo.Estudiante` únicamente, y generó una contraseña fuerte guardada localmente en `.env` ignorado por Git; no se imprimió ni se guardó en el repositorio. `mssql` 12.7.14 y `@types/mssql` 12.3.0 están fijados en el lockfile. `apps/server/lib/database/pool.ts` abre un pool compartido solo cuando se lo solicita, lo reinicia tras fallo y expone cierre; el servidor Eve no conecta ni reconstruye SQL al arrancar. La configuración SQL se valida con Zod y rechaza cuentas distintas de `lapredigital_app` sin mostrar secretos.

Verificación real: `docker compose run --rm --no-deps --workdir /workspace/apps/server server npm run db:check` completó una consulta parametrizada por `Codigo='C001'`, comprobó reutilización y cierre del pool, SELECT permitido, INSERT/UPDATE/DELETE denegados mediante `HAS_PERMS_BY_NAME`, hora local de `GETDATE()` y offset -05:00 de `SYSDATETIMEOFFSET()`. Un puerto erróneo (`SQLSERVER_PORT=1`) terminó con error claro y código no cero sin imprimir contraseña. `npm ci` instaló 103 paquetes desde lockfile y auditó 105 sin vulnerabilidades reportadas; `typecheck`, 4 pruebas de configuración, `npm run check` y salud 200 de Eve pasaron. El contenedor de prueba del servidor se detuvo después.

Límites: no se ejecutaron las pruebas SQL exploratorias sobre esta instancia ni se usaron escrituras de negocio. No se verificó la serialización de columnas DATETIME2 de negocio: solo `GETDATE()` como texto y el offset del servidor. T08 amplió después los SELECT de perfil y servicio; ver su sección. `build:server` conserva el EXDEV documentado; no afecta la prueba de conexión.

## T05: login local y herramienta inocua

El usuario completó `/login` de **ChatGPT Subscription** en Eve 1.0.0-rc.10 desde Docker Desktop/Windows. La TUI llamó `comprobar_conexion` y devolvió `{ "estado": "ok", "fuente": "prueba_local" }`; después presentó una respuesta real. `eve traces show` confirmó `execute_tool comprobar_conexion` entre dos pasos reales del modelo `gpt-6-luna-fast` (389 tokens de entrada y 40 de salida registrados). Esta es una prueba del acceso local y de la herramienta fija, no de datos académicos, SQL ni despliegue.

Se añadió solo la herramienta fija sin entradas ni servicios externos y `localDev()` para sesiones del servidor de desarrollo. `eve info --json` informó `ready`, cero diagnósticos y únicamente `comprobar_conexion`. GET /eve/v1/info desde dentro del contenedor devolvió 200; las peticiones al puerto publicado desde Windows devolvieron 401 con `localDev()`. `eve remote connect --print` antes del login falló sin invocar el modelo: `The model connection is unavailable. Run /login to reconnect.` No hubo tokens, códigos OAuth ni contraseñas en Git.

El primer `/login` falló por ausencia de Secret Service. Se instaló D-Bus, GNOME Keyring y `libsecret-tools` en la imagen Node, y `scripts/eve-local` arranca una sesión interactiva con llavero cifrado en el volumen `keyring_state`, separado del workspace. El navegador de Windows no llega al callback OAuth `localhost:1455` del contenedor; `SSH_TTY=1` activa el flujo de dispositivo de la versión instalada. El usuario habilitó el inicio de dispositivo en ChatGPT y completó el login. Con un valor ficticio se comprobó almacenamiento/lectura y recuperación después de recrear el contenedor usando un volumen temporal que fue eliminado; **no se comprobó todavía la persistencia del login real después de reiniciar**. Ver [la receta](../apps/server/README.md).

Límites de T05: la TUI interactiva siguió en ejecución durante esa prueba y el usuario salió antes de reinstalar dependencias en T07. El `server` estándar no arranca el llavero desbloqueado, por lo que un chat desde Windows o un proceso separado aún requiere integración y autenticación propias (T20). El build `EXDEV` documentado en T06 sigue pendiente; el login local no lo resuelve. SQL se conectó posteriormente en T07; el panel y las herramientas de negocio permanecen pendientes.

## Trabajo completado en esta inicialización

- T00: repositorio Git inicializado en main con los archivos originales; origin configurado a git@github.com:xBiltTom/lapredigital-customer-agents.git. El remoto existía y estaba vacío al comprobarlo.
- T01: archivos organizados, configuración npm/editor/Git y comprobación del workspace. Los seis archivos originales se movieron sin cambiar sus bytes, incluidas las consultas personales recientes del 04.
- T02: roadmap con tareas por commit, contexto, arquitectura, instrucciones para agentes y punto de continuación.

Commits previos identificables: T00 = 513d0c9; T01 = 9059457; T02 = d308ea6; T03 = 381cd70. El hash de T04 y el estado de publicación se consultan en `git log -5 --oneline`, `git status -sb` y `git branch -vv`; no se escribe el hash de un commit dentro de sí mismo.

## T03: entorno Node aislado en Docker

Decisión del usuario: aislar Node y preparar el proyecto para empaquetar en un VPS. Se añadió compose.yaml, infra/docker/Node.Dockerfile fijado por digest, .dockerignore y scripts/dev con UID/GID del usuario. Dependencias y caché quedan en volúmenes; no se montó el socket Docker. Ver infra/README.md para comandos y límites.

Verificación: Node 24.22.3 y npm 11.19.1, usuario no root, zona America/Lima y chequeo del workspace dentro de Docker. El Compose no declara SQL Server y no se ejecutó SQL ni se reinició el contenedor existente. La imagen final para VPS se completa en T29; el entorno actual monta código para desarrollo.

## T04: backend mínimo de Eve

Se creó apps/server manualmente, sin Git anidado, con Eve 1.0.0-rc.10, AI SDK 7.0.137, Zod 4.6.7, TypeScript 7.0.2 y tipos Node 24.19.2. Versiones exactas y package-lock.json raíz. Se leyeron las docs instaladas de configuración, herramientas, canales/auth, CLI y self-hosting; consultar apps/server/README.md.

El servicio server hereda la toolchain y corre sin root, con salud y puerto 127.0.0.1:3000. CLI y servidor comparten eve_state para apps/server/.eve; dependencias y caché siguen en volúmenes separados. No se montaron credenciales del host ni socket Docker. La telemetría opcional de Eve está desactivada en Compose.

agent.ts selecciona chatgpt(), pero no hay login, respuesta ni herramienta de negocio probados. defaultTools: false deja el manifiesto sin herramientas. El canal usa auth: []: la salud es pública y las sesiones se rechazan hasta T05. No relajar este cierre sin definir el acceso local según las docs de la versión instalada.

Verificación ejecutada:

- npm ci: instalación reproducible desde lockfile, 29 paquetes instalados; auditoría npm de 31 paquetes con cero vulnerabilidades reportadas.
- npm run typecheck y npm run build:server: correctos dentro de Docker.
- npm run check: estructura y enlaces locales correctos; no es una prueba del agente.
- eve info --json: status ready, cero errores/advertencias y tools: []; el modelo observado es una selección de configuración, no prueba de disponibilidad.
- GET /eve/v1/health: 200, ok: true. POST /eve/v1/session: 401 sin llamar al modelo.
- Parada, arranque y recreación del contenedor server; salud y marcador .eve conservados. Marcador de prueba eliminado después. Usuario del proceso: UID 1000.
- Compose válido, git diff --check y comparación de los cuatro SQL contra su versión preservada; sin cambios de esquema ni ejecución SQL.

Límites: Eve es una versión candidata. El build advierte que no existe proveedor de sandbox; pasa y no hay herramientas que lo necesiten. No se conectó SQL ni se consumió MiniMax. El login de ChatGPT, su ubicación efectiva y persistencia, el acceso desde la CLI a través de Docker y una llamada real siguen pendientes de T05. No copiar tokens del host ni asumir que el volumen .eve cubre ubicaciones de credenciales aún no verificadas.

## T06: configuración mínima validada

Se añadió `apps/server/lib/config.ts` con Zod para exigir `TZ=America/Lima` y `AI_PROVIDER=chatgpt`, y se llama desde el agente. Compose suministra esas variables a CLI y servidor; `.env.example` deja de mostrar puertos y credenciales SQL como si estuvieran implementados. El puerto de desarrollo sigue fijado en 127.0.0.1:3000. No hay conexión a SQL ni variables secretas de aplicación en uso.

Verificación ejecutada en Docker desde Windows: `npm test --workspace=@lapredigital/server` (3/3), `npm run typecheck`, `npm run check` y `eve info --json` (ready, cero errores o advertencias). Sin `AI_PROVIDER`, `eve info` falló con `Configuración inválida o ausente: AI_PROVIDER` sin imprimir el entorno. `docker compose up --build -d --wait server` llegó a healthy y GET /eve/v1/health devolvió `ok: true`; el servidor se detuvo después. No se probaron sesiones de modelo ni se ejecutó SQL.

El `npm ci` de esta sesión instaló 29 paquetes y reportó cero vulnerabilidades. En esta máquina, `npm run build:server` compila Nitro pero falla en el paso final `EXDEV` al mover el resultado de `.eve/builds` (volumen Docker) a `.output` (montaje del proyecto). Es un problema del empaquetado de desarrollo pendiente; no confundir la compilación parcial con un build correcto. Las docs instaladas de Eve indican que `/login` usa una terminal interactiva y guarda OAuth/credenciales en el almacén de secretos del sistema, no en el proyecto ni necesariamente en el volumen `.eve`. La ubicación efectiva en este contenedor y el login real continúan sin verificarse (T05); no se copiaron tokens.

## Qué existe y qué falta

Existe la base OLTP en SQL Server nativo de Windows, sus scripts, la toolchain Docker y el backend mínimo apps/server con configuración Zod, pool SQL de lectura y repositorios de perfil/servicio. El login local de ChatGPT y una herramienta fija funcionan en la TUI. No existen apps/web ni herramientas de negocio expuestas al modelo. Hay comandos de typecheck, build e inicio del servidor; el build actual tiene el fallo EXDEV descrito arriba en Windows. Las pruebas SQL del 03 siguen siendo históricas.

El host conserva Node v26.13.1 y npm 12.2.2. Node del proyecto se ejecuta en Docker: imagen oficial fijada por digest, Node 24.22.3 y npm 11.19.1. Usar `./scripts/dev npm run check`; el chequeo rechaza Node de otra versión. No se instaló ni cambió Node global.

## Validación de esta tarea

- Lectura del esquema/scripts, informe previo de validación y consultas actuales.
- git ls-remote respondió correctamente sobre el origen y no devolvió refs al inicio.
- Comparación byte por byte de los seis originales con T00 después de moverlos.
- Comprobación del workspace, enlaces Markdown locales, exclusiones de secretos y git diff --check.
- No se ejecutaron scripts SQL ni se modificó o reinició el contenedor en esta inicialización.
- El resultado de 29 pruebas SQL (24 OK/5 HALLAZGO), los 20 bloques y DBCC sin infracciones son verificaciones históricas de la revisión anterior. Las consultas añadidas después por el usuario no se declaran revalidadas.

## Pendientes reales

1. B01: configurar usuario SQL/.env/red en este CachyOS sin reconstruir el OLTP; definir acceso local del dueño y no habilitar acceso familiar sin prestación.
2. B01: corregir EXDEV (reproducido en Linux y Windows) y verificar el canal/llavero del proceso real; no montar Docker ni copiar tokens. B02 reúne después progreso, riesgo y políticas.
3. Confirmar si los 2.000 créditos MiniMax son de API o de su aplicación; no consumirlos todavía.
4. Implementar política de contacto con aceptación inicial de términos y revocación posterior; el texto de términos y el registro público de usuarios no están implementados.
5. Cubrir en servicios los cinco huecos conocidos, manteniendo el esquema actual.

## Cómo actualizar este archivo después de una tarea

Indicar la tarea completada, qué se cambió, comandos/pruebas realmente ejecutados y resultado, qué no pudo verificarse y por qué, y el siguiente ID concreto con sus dependencias. Actualizar también su casilla/estado en ROADMAP.md y hacer un único commit de esa tarea. Conservar los hechos de negocio en CONTEXTO.md y las decisiones de diseño en ARQUITECTURA.md.
