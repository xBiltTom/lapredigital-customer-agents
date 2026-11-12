# Estado y punto de continuación

Actualizado: 12 de noviembre de 2026. Documento de traspaso para otra sesión o agente.

## Próxima tarea

**T08 del [roadmap](ROADMAP.md): consultar perfil, servicio y prestaciones.** T07 conectó SQL Server con un usuario de aplicación de solo lectura sobre `dbo.Estudiante`. Leer el informe 7.1 y los cuatro scripts de `database/` antes de ampliar consultas; conceder únicamente los SELECT adicionales necesarios, paginar listados y validar la identidad activa en el backend. No cambiar de stack ni modificar el esquema sin evidencia.

## T07: conexión SQL de lectura

El usuario informó que creó y pobló `LaPreDigital_Customers` en SQL Server nativo de Windows. Esta sesión consultó por autenticación integrada local con `sqlcmd -S . -E`: 14 estudiantes, SQL Server con offset -05:00, modo mixto y cuenta administradora disponible solo localmente; la conexión integrada por TCP a `127.0.0.1` devolvió error de dominio no confiable. Desde Docker se confirmó conectividad TCP a `host.docker.internal:1433`. Se leyeron el informe 7.1, los cuatro scripts SQL y la revisión histórica antes de escribir la consulta de prueba. Los scripts 01/02/03/04 no se ejecutaron aquí y las 29 pruebas siguen siendo resultados históricos.

`scripts/provision-sql-app.ps1` creó en la instancia existente `lapredigital_app`, un usuario de base con `GRANT SELECT ON dbo.Estudiante` únicamente, y generó una contraseña fuerte guardada localmente en `.env` ignorado por Git; no se imprimió ni se guardó en el repositorio. `mssql` 12.7.14 y `@types/mssql` 12.3.0 están fijados en el lockfile. `apps/server/lib/database/pool.ts` abre un pool compartido solo cuando se lo solicita, lo reinicia tras fallo y expone cierre; el servidor Eve no conecta ni reconstruye SQL al arrancar. La configuración SQL se valida con Zod y rechaza cuentas distintas de `lapredigital_app` sin mostrar secretos.

Verificación real: `docker compose run --rm --no-deps --workdir /workspace/apps/server server npm run db:check` completó una consulta parametrizada por `Codigo='C001'`, comprobó reutilización y cierre del pool, SELECT permitido, INSERT/UPDATE/DELETE denegados mediante `HAS_PERMS_BY_NAME`, hora local de `GETDATE()` y offset -05:00 de `SYSDATETIMEOFFSET()`. Un puerto erróneo (`SQLSERVER_PORT=1`) terminó con error claro y código no cero sin imprimir contraseña. `npm ci` instaló 103 paquetes desde lockfile y auditó 105 sin vulnerabilidades reportadas; `typecheck`, 4 pruebas de configuración, `npm run check` y salud 200 de Eve pasaron. El contenedor de prueba del servidor se detuvo después.

Límites: no se ejecutaron las pruebas SQL exploratorias sobre esta instancia ni se usaron escrituras de negocio. No se verificó la serialización de columnas DATETIME2 de negocio: solo `GETDATE()` como texto y el offset del servidor. El usuario de aplicación todavía no tiene permisos para leer Contacto, Suscripcion ni las demás tablas que T08 necesitará; ampliar según consultas concretas. `build:server` conserva el EXDEV documentado; no afecta la prueba de conexión.

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

Existe la base OLTP en SQL Server nativo de Windows, sus scripts, la toolchain Docker y el backend mínimo apps/server con configuración Zod y pool SQL de lectura. El login local de ChatGPT y una herramienta fija funcionan en la TUI. No existen apps/web ni herramientas de negocio. Hay comandos de typecheck, build e inicio del servidor; el build actual tiene el fallo EXDEV descrito arriba en Windows. Las pruebas SQL del 03 siguen siendo históricas.

El host conserva Node v26.13.1 y npm 12.2.2. Node del proyecto se ejecuta en Docker: imagen oficial fijada por digest, Node 24.22.3 y npm 11.19.1. Usar `./scripts/dev npm run check`; el chequeo rechaza Node de otra versión. No se instaló ni cambió Node global.

## Validación de esta tarea

- Lectura del esquema/scripts, informe previo de validación y consultas actuales.
- git ls-remote respondió correctamente sobre el origen y no devolvió refs al inicio.
- Comparación byte por byte de los seis originales con T00 después de moverlos.
- Comprobación del workspace, enlaces Markdown locales, exclusiones de secretos y git diff --check.
- No se ejecutaron scripts SQL ni se modificó o reinició el contenedor en esta inicialización.
- El resultado de 29 pruebas SQL (24 OK/5 HALLAZGO), los 20 bloques y DBCC sin infracciones son verificaciones históricas de la revisión anterior. Las consultas añadidas después por el usuario no se declaran revalidadas.

## Pendientes reales

1. T08: implementar repositorios parametrizados para perfil y servicio. Conceder solo los SELECT adicionales requeridos por esas consultas y probar casos C006/C011/C013 sin mezclar estudiante con apoderado.
2. Corregir el fallo EXDEV del build entre el volumen `.eve` y `.output` al abordar el empaquetado de desarrollo; no exponer Docker al agente para eliminar el aviso de sandbox. Verificar persistencia del login real tras reiniciar antes de depender de ella.
3. Confirmar si los 2.000 créditos MiniMax son de API o de su aplicación; no consumirlos todavía.
4. Implementar política de contacto con aceptación inicial de términos y revocación posterior; el texto de términos y el registro público de usuarios no están implementados.
5. Cubrir en servicios los cinco huecos conocidos, manteniendo el esquema actual.

## Cómo actualizar este archivo después de una tarea

Indicar la tarea completada, qué se cambió, comandos/pruebas realmente ejecutados y resultado, qué no pudo verificarse y por qué, y el siguiente ID concreto con sus dependencias. Actualizar también su casilla/estado en ROADMAP.md y hacer un único commit de esa tarea. Conservar los hechos de negocio en CONTEXTO.md y las decisiones de diseño en ARQUITECTURA.md.
