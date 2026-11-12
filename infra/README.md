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
./scripts/dev npm run build:server
docker compose up --build -d --wait server
curl http://127.0.0.1:3000/eve/v1/health
docker compose stop server
```

Si tu UID/GID difiere de 1000, antes de invocar Compose directamente ejecutar `export LOCAL_UID=$(id -u)` y `export LOCAL_GID=$(id -g)`. El wrapper ya los calcula para sus comandos. Detener server antes de reinstalar dependencias: npm ci reemplaza node_modules, compartido con el proceso activo.

El servicio server hereda la toolchain, volúmenes y usuario de tools; usa el perfil app y se selecciona explícitamente con su nombre. Eve escucha en 0.0.0.0 dentro del contenedor y se publica exclusivamente en 127.0.0.1:3000 del host. Incluye init, chequeo de salud y 20 segundos de margen de parada. [Alcance y comandos](../apps/server/README.md).

La salud está disponible; crear sesiones devuelve 401 hasta T05. No se cargan variables de .env automáticamente ni se inicia SQL al arrancar. El Compose desactiva la telemetría opcional de Eve con EVE_TELEMETRY_DISABLED=1.

## Volúmenes y datos

- `lapredigital-customers_node_modules`: dependencias Linux del workspace, separadas del host.
- `lapredigital-customers_npm_cache`: caché npm; no es estado del negocio.
- `lapredigital-customers_eve_state`: estado .eve compartido por servidor y CLI; persistencia de un marcador comprobada al recrear el contenedor. La persistencia y ubicación efectiva del login se verifican en T05.
- El código y lockfile se escriben en el bind mount con el UID/GID del usuario.
- No se montan el socket de Docker, credenciales del host ni archivos .env como variables del contenedor de herramientas. El workspace de desarrollo sí es un montaje de código con escritura; no se presenta como sandbox de un modelo no confiable.

No ejecutar `docker system prune` o borrados globales para limpiar este proyecto. La eliminación de volúmenes de dependencias no reconstruye los datos, pero exige reinstalación. Los volúmenes de SQL Server son independientes y no se administran con este Compose.

## SQL Server existente

El contenedor `sql-server-local` ya funciona, publica el puerto 1433 al comprobarlo en T03 y no pertenece a este Compose. No se lo modifica, reinicia ni reemplaza. T07 comprobará conexión, identidad de aplicación y red. `127.0.0.1` dentro de un contenedor apunta a ese contenedor, no a SQL Server ni al host: la dirección final se resolverá al configurar la conexión.

Los scripts 01/02 no se ejecutan al construir o iniciar la aplicación. La configuración de recreación de SQL Server, sus volúmenes y America/Lima sigue pendiente de documentarse con detalle, sin alterar la instancia activa.

## Empaquetado y VPS

Este es el entorno de **desarrollo**, con código montado; no una imagen de producción terminada. T04 añade el servidor mínimo y T29 consolidará los targets de compilación/runtime, copias de artefactos, dependencias de producción y comandos para VPS. Salud y volumen de estado ya están configurados para desarrollo. Las imágenes finales no incluirán .env, .eve, tokens, .git, bases ni backups. La IA con suscripción de ChatGPT sigue limitada al acceso local documentado de Eve; una nube requiere revisar esa modalidad.
