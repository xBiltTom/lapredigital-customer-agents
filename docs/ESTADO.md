# Estado y punto de continuación

Actualizado: 12 de noviembre de 2026. Documento de traspaso para otra sesión o agente.

## Próxima tarea

**T05 del [roadmap](ROADMAP.md): verificar el login local de ChatGPT y una herramienta inocua.** T06 dejó lista la configuración mínima del servidor. El usuario debe efectuar `/login` en una terminal interactiva de Eve; T07 puede avanzar de manera independiente si el login sigue pendiente. No cambiar de stack ni modificar el esquema SQL.

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

Existe la base OLTP, sus scripts, la toolchain Docker y el backend mínimo apps/server con configuración Zod. No existen apps/web, mssql instalado, herramientas de negocio ni autenticación de modelo probada. Hay comandos de typecheck, build e inicio del servidor; el build actual tiene el fallo EXDEV descrito arriba en Windows. Las pruebas SQL siguen siendo históricas.

El host conserva Node v26.13.1 y npm 12.2.2. Node del proyecto se ejecuta en Docker: imagen oficial fijada por digest, Node 24.22.3 y npm 11.19.1. Usar `./scripts/dev npm run check`; el chequeo rechaza Node de otra versión. No se instaló ni cambió Node global.

## Validación de esta tarea

- Lectura del esquema/scripts, informe previo de validación y consultas actuales.
- git ls-remote respondió correctamente sobre el origen y no devolvió refs al inicio.
- Comparación byte por byte de los seis originales con T00 después de moverlos.
- Comprobación del workspace, enlaces Markdown locales, exclusiones de secretos y git diff --check.
- No se ejecutaron scripts SQL ni se modificó o reinició el contenedor en esta inicialización.
- El resultado de 29 pruebas SQL (24 OK/5 HALLAZGO), los 20 bloques y DBCC sin infracciones son verificaciones históricas de la revisión anterior. Las consultas añadidas después por el usuario no se declaran revalidadas.

## Pendientes reales

1. Confirmar el plan de ChatGPT y probar /login con la versión instalada de Eve (T05). Mantener el login fuera de Git y probar una herramienta inocua. Verificar la persistencia del almacén de secretos en el contenedor antes de depender de ella.
2. Corregir el fallo EXDEV del build entre el volumen `.eve` y `.output` al abordar el empaquetado de desarrollo; no exponer Docker al agente para eliminar el aviso de sandbox.
3. Confirmar si los 2.000 créditos MiniMax son de API o de su aplicación; no consumirlos todavía.
4. Comprobar el puerto SQL publicado y configurar el usuario de aplicación en T07. `.env.example` no contiene credenciales SQL ni una conexión provisionada.
5. Implementar política de contacto con aceptación inicial de términos y revocación posterior; el texto de términos y el registro público de usuarios no están implementados.
6. Cubrir en servicios los cinco huecos conocidos, manteniendo el esquema actual.

## Cómo actualizar este archivo después de una tarea

Indicar la tarea completada, qué se cambió, comandos/pruebas realmente ejecutados y resultado, qué no pudo verificarse y por qué, y el siguiente ID concreto con sus dependencias. Actualizar también su casilla/estado en ROADMAP.md y hacer un único commit de esa tarea. Conservar los hechos de negocio en CONTEXTO.md y las decisiones de diseño en ARQUITECTURA.md.
