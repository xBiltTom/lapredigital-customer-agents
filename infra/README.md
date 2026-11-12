# Entorno local con Docker

## Toolchain Node (T03)

Requisitos del host: Docker Engine, plugin `docker compose`, Git y un shell POSIX. No hace falta Node/npm en el host. Ejecutar desde la raíz:

```bash
./scripts/dev node --version
./scripts/dev npm --version
./scripts/dev npm run check
./scripts/dev sh
```

El wrapper resuelve la raíz, usa el UID/GID del usuario y ejecuta `docker compose run --build --rm --no-deps tools`. La primera ejecución construye la imagen; las siguientes reutilizan sus capas. Invocar sin sudo. Si el UID/GID cambia entre equipos, reconstruir la imagen y usar volúmenes nuevos de ese entorno con propietario adecuado; los volúmenes existentes no se reasignan silenciosamente.

[Node.Dockerfile](docker/Node.Dockerfile) fija la imagen oficial `node:24-bookworm-slim` por digest. Versiones comprobadas: Node **24.22.3**, npm **11.19.1**, Debian Bookworm. `.nvmrc`, engines y el chequeo del workspace requieren Node 24; `engine-strict` evita instalar dependencias accidentalmente con otra versión. Una actualización de imagen es un cambio deliberado y debe verificarse.

El servicio `tools` está bajo el perfil `tools`; se invoca explícitamente, no queda ejecutándose en segundo plano ni publica puertos. Usa `init: true` para señales y un usuario sin privilegios. El código se monta desde el workspace para desarrollo. Los paquetes se instalan con el npm del contenedor, desde la raíz del workspace, y comparten un único package-lock.json.

## Servidor Eve (T04)

```bash
./scripts/dev npm ci
./scripts/dev npm run typecheck
docker compose up --build -d --wait server
curl http://127.0.0.1:3000/eve/v1/health
docker compose stop server
```

Si tu UID/GID difiere de 1000, antes de invocar Compose directamente ejecutar `export LOCAL_UID=$(id -u)` y `export LOCAL_GID=$(id -g)`. El wrapper ya los calcula para sus comandos. Detener server antes de reinstalar dependencias: npm ci reemplaza node_modules, compartido con el proceso activo.

El servicio server hereda la toolchain, volúmenes y usuario de tools; usa el perfil app y se selecciona explícitamente con su nombre. Eve escucha en 0.0.0.0 dentro del contenedor y se publica exclusivamente en 127.0.0.1:3000 del host. Incluye init, chequeo de salud y 20 segundos de margen de parada. [Alcance y comandos](../apps/server/README.md).

La salud es pública. B01 exige token del dueño desde el host y valida DUEÑO activo en SQL; la TUI interna puede usar localDev solo durante desarrollo y se resuelve al mismo dueño. El servidor estándar no desbloquea el llavero: ./scripts/chat-local abre la TUI y el servidor con el mismo D-Bus/llavero. Compose carga SQL y acceso del dueño desde .env para server; tools no recibe esos secretos. El pool conecta al solicitar datos/autenticación, no para salud. Telemetría opcional desactivada con EVE_TELEMETRY_DISABLED=1.

## Volúmenes y datos

- `lapredigital-customers_node_modules`: dependencias Linux del workspace, separadas del host.
- `lapredigital-customers_npm_cache`: caché npm; no es estado del negocio.
- `lapredigital-customers_eve_state`: estado .eve compartido por servidor y CLI; persistencia de un marcador comprobada al recrear el contenedor. La preferencia de proveedor no equivale a credenciales del modelo.
- `lapredigital-customers_keyring_state`: llavero Linux cifrado utilizado por `/login` interactivo en T05; se desbloquea con la contraseña local al invocar `scripts/eve-local`. Se verificó persistencia con un valor ficticio, no del login real tras reiniciar. No borrar este volumen al reinstalar npm.
- El código y lockfile se escriben en el bind mount con el UID/GID del usuario.
- No se montan el socket de Docker, credenciales del host ni archivos .env como variables del contenedor de herramientas. El workspace de desarrollo sí es un montaje de código con escritura; no se presenta como sandbox de un modelo no confiable.

No ejecutar `docker system prune` o borrados globales para limpiar este proyecto. La eliminación de volúmenes de dependencias no reconstruye los datos, pero exige reinstalación. Los volúmenes de SQL Server son independientes y no se administran con este Compose.

## SQL Server existente

B01 configuró CachyOS con scripts/provision-sql-app: cuenta lapredigital_app de lectura, .env privado y dueño local. Compose añade host-gateway y db:check/db:t08/db:b01 pasan contra sql-server-local existente. No se recreó la base ni se ejecutaron 01/02; credenciales de cada equipo permanecen locales. infra/sql/app-read-permissions.sql es el conjunto común de permisos de los scripts Linux/Windows, con SELECT de PersonalInterno y sin DML.

En el entorno histórico CachyOS, `sql-server-local` era un contenedor independiente que publicaba 1433. Compose de este proyecto no lo modifica ni lo reemplaza. `127.0.0.1` dentro de un contenedor apunta a ese contenedor, no al host ni a SQL Server.

En el entorno Windows de T07, el motor es el servicio local **MSSQLSERVER**, no un contenedor; atiende en el puerto 1433 y mantiene hora peruana (-05:00). Docker lo alcanza por `host.docker.internal:1433`. Se creó una identidad SQL independiente con SELECT de lectura para perfil y servicio (T08) y contraseña local ignorada por Git; en `Pago` solo puede leer cuatro columnas. Ver [conexión y prueba](../apps/server/README.md). La cuenta administrativa Windows solo funciona desde el host por conexión local (`-S .`), no como credencial del backend. El servidor Eve arranca sin abrir conexiones SQL.

Los scripts 01/02 no se ejecutan al construir o iniciar la aplicación. La configuración de recreación de SQL Server, sus volúmenes y America/Lima sigue pendiente de documentarse con detalle, sin alterar la instancia activa.

## Empaquetado y VPS

Este es el entorno de **desarrollo**, con código montado; no una imagen de producción terminada. B01 corrigió EXDEV: build:server prepara las fuentes mínimas y compila dentro de .eve/packaged, en el volumen Docker. start:server ya pasó salud y autenticación con el resultado compilado. No guardar .output en el host ni recompilar mientras ese servidor está en uso. B08 consolidará imagen/runtime, artefactos, dependencias de producción y comandos para VPS. La imagen final no incluirá .env, estado privado de .eve, tokens, .git, bases ni backups. La suscripción ChatGPT sigue limitada al acceso local documentado de Eve; nube requiere revisar esa modalidad.
