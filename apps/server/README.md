# Backend mínimo de Eve (T04)

Node 24 en Docker, Eve **1.0.0-rc.10**, AI SDK **7.0.137**, Zod **4.6.7**. Las versiones directas y transitivas están fijadas en el package-lock.json raíz. Eve es una versión candidata; cualquier actualización requiere verificar compatibilidad.

Desde la raíz del repositorio:

```bash
./scripts/dev npm ci
./scripts/dev npm run typecheck
docker compose up --build -d server
curl http://127.0.0.1:3000/eve/v1/health
docker compose logs --tail 40 server
docker compose stop server
```

Detener el servidor antes de repetir npm ci. Si tu UID/GID difiere de 1000, exportar LOCAL_UID y LOCAL_GID como explica [infraestructura](../../infra/README.md).

`dev:server` ejecuta Eve sin UI ni extensiones predeterminadas. `build:server` compila con Eve y `start:server` inicia el resultado compilado; este último debe ejecutarse desde el mismo volumen de estado donde se hizo el build, con el servicio dev detenido. El servidor solo se publica en 127.0.0.1:3000. Todavía no existe frontend.

`lib/config.ts` valida al cargar el agente `TZ=America/Lima` y `AI_PROVIDER=chatgpt`. Compose suministra ambos valores; `.env.example` es una referencia y no se carga automáticamente. Para comprobar la configuración sin invocar al modelo: `./scripts/dev npm test --workspace=@lapredigital/server`. En un host Windows con el volumen `.eve` separado, `build:server` puede fallar con EXDEV al mover el resultado a `.output`; el servidor de desarrollo sí pasó el chequeo de salud. El build correcto queda pendiente de resolver.

## T07: SQL Server local

La instancia actual es SQL Server nativo de Windows en 1433. En este equipo se ejecutó una vez `scripts/provision-sql-app.ps1` desde PowerShell con la cuenta administradora local: creó `lapredigital_app` con permiso SELECT solo sobre `dbo.Estudiante` y escribió la credencial generada en `.env`, que Git excluye. El script se detiene sin sobrescribir un `.env` o un login previo. En otra instalación, configurar el usuario y `.env` localmente siguiendo `.env.example`; nunca usar `sa` ni copiar la contraseña al navegador o al chat.

Compose pasa las variables SQL del `.env` únicamente al servicio `server`, con `host.docker.internal` para llegar al host desde Docker. El pool de `lib/database/pool.ts` es compartido y se conecta únicamente al invocar `getPool()`. `closePool()` lo cierra; el comando manual de verificación llama ambos y no hace escrituras:

```text
docker compose run --rm --no-deps --workdir /workspace/apps/server server npm run db:check
```

Comprueba C001 con SQL parametrizado, SELECT sobre `dbo.Estudiante`, ausencia de permisos DML y la hora SQL de Perú. Si no hay conexión, devuelve un error claro sin imprimir el secreto. T08 ampliará solo los permisos de lectura necesarios para consultas de perfil y servicio. No se expone una herramienta SQL al modelo ni un endpoint de base de datos.

## Alcance actual

- GET /eve/v1/health responde 200 con ok: true.
- Eve usa `localDev()` para permitir sesiones desde el contenedor durante `eve dev`; las peticiones desde Windows mediante el puerto publicado reciben 401 en esta instalación.
- agent/agent.ts selecciona chatgpt(), pero no inicia login ni hace llamadas por arrancar o compilar. El modelo efectivo que muestra eve info es configuración; no demuestra acceso a ese modelo.
- `defaultTools: false` deja solo la herramienta local `comprobar_conexion`. No se ofrece bash, archivos ni SQL al modelo.
- No hay conexión SQL, tareas programadas ni comunicaciones reales. La lógica del Agente Académico está pendiente.

El volumen eve_state conserva apps/server/.eve y es compartido por CLI y servidor. Para el `/login` interactivo, `scripts/eve-local` inicia D-Bus y un llavero Linux desbloqueado con una contraseña local; sus archivos cifrados residen en el volumen `keyring_state`. Recuerda esa contraseña para sesiones posteriores. No copiar tokens desde el host ni borrar estos volúmenes al reinstalar dependencias. El login real y una llamada real al modelo funcionaron; solo se comprobó la persistencia del llavero con un valor ficticio, no la del login real tras reiniciar.

## T05: login local verificado

`comprobar_conexion` devuelve `{ estado: 'ok', fuente: 'prueba_local' }` sin entradas ni acceso a SQL. El usuario completó `/login` y la TUI llamó la herramienta y respondió con su resultado; `eve traces show` confirmó `execute_tool comprobar_conexion` y dos pasos del modelo `gpt-6-luna-fast`. `localDev()` permite sesiones desde el contenedor durante el desarrollo: en Docker Desktop/Windows, una petición al puerto publicado desde Windows recibió 401, mientras que una petición local dentro del contenedor obtuvo 200. Antes de iniciar sesión, `eve remote connect --print` dentro del contenedor falló con `The model connection is unavailable`.

Con el servidor detenido y cualquier sesión anterior de Eve cerrada con `/exit`, abrir una terminal interactiva en el host (CMD o PowerShell) y ejecutar:

```text
docker compose run --build --rm --no-deps --service-ports --env SSH_TTY=1 --workdir /workspace/apps/server server sh /workspace/scripts/eve-local /workspace/node_modules/.bin/eve dev --host 0.0.0.0 --port 3000 --no-default-extensions
```

Primero, introducir la contraseña del llavero local, distinta de la de ChatGPT; la terminal oculta lo escrito. Luego, en Eve, escribir `/login` y elegir **ChatGPT Subscription** si no está conectada. `SSH_TTY=1` activa el inicio con código de dispositivo de esta versión de Eve: abrir en el navegador la dirección que indique Eve e introducir allí el código, sin compartirlo. Este modo evita el callback `localhost:1455` que Eve abre dentro del contenedor y al que el navegador de Windows no puede acceder. Puede requerir habilitar device code authorization en ChatGPT Settings > Security. Para repetir la prueba, pedir: «Comprueba la conexión con la herramienta y dime qué devuelve». Detener la terminal con `/exit` al terminar. El servicio `server` estándar no inicia este llavero interactivo: esta receta es para la prueba local de T05.

Eve puede advertir que no tiene proveedor de sandbox al compilar. No existen herramientas que requieran ese proveedor; el fallo EXDEV descrito arriba es independiente del aviso. No montar el socket Docker para eliminarlo.

## Documentación usada de la versión instalada

Dentro del contenedor, desde /workspace:

- node_modules/eve/docs/README.md
- node_modules/eve/docs/getting-started.mdx
- node_modules/eve/docs/agent-config.md
- node_modules/eve/docs/concepts/built-in-tools.md
- node_modules/eve/docs/guides/auth-and-route-protection.md
- node_modules/eve/docs/guides/deployment/self-hosting/index.md
- node_modules/eve/docs/reference/cli/index.md

Para inspeccionar la configuración sin invocar al modelo: `./scripts/dev sh -ec 'cd apps/server; ../../node_modules/.bin/eve info --json'`. El diagnóstico se ejecutó sin errores ni advertencias. Los comandos de compilación/tipos y salud son verificaciones técnicas; no validan reglas del negocio ni autenticación.
