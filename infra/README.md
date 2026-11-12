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

La salud está disponible; `localDev()` permite sesiones desde el contenedor en `eve dev`, pero desde Windows el puerto publicado devolvió 401. El login real se verificó con la TUI lanzada mediante `scripts/eve-local` (ver [receta](../apps/server/README.md)); el servicio server estándar no desbloquea el llavero. No se cargan variables de .env automáticamente ni se inicia SQL al arrancar. El Compose desactiva la telemetría opcional de Eve con EVE_TELEMETRY_DISABLED=1.

## Volúmenes y datos

- `lapredigital-customers_node_modules`: dependencias Linux del workspace, separadas del host.
- `lapredigital-customers_npm_cache`: caché npm; no es estado del negocio.
- `lapredigital-customers_eve_state`: estado .eve compartido por servidor y CLI; persistencia de un marcador comprobada al recrear el contenedor. La preferencia de proveedor no equivale a credenciales del modelo.
- `lapredigital-customers_keyring_state`: llavero Linux cifrado utilizado por `/login` interactivo en T05; se desbloquea con la contraseña local al invocar `scripts/eve-local`. Se verificó persistencia con un valor ficticio, no del login real tras reiniciar. No borrar este volumen al reinstalar npm.
- El código y lockfile se escriben en el bind mount con el UID/GID del usuario.
- No se montan el socket de Docker, credenciales del host ni archivos .env como variables del contenedor de herramientas. El workspace de desarrollo sí es un montaje de código con escritura; no se presenta como sandbox de un modelo no confiable.

No ejecutar `docker system prune` o borrados globales para limpiar este proyecto. La eliminación de volúmenes de dependencias no reconstruye los datos, pero exige reinstalación. Los volúmenes de SQL Server son independientes y no se administran con este Compose.

## SQL Server existente

R01 volvió a CachyOS y encendió sql-server-local: base ONLINE, 14 estudiantes, hora -05:00. No están provisionados aquí .env ni lapredigital_app; host.docker.internal da ENOTFOUND desde Docker. El backend responde salud, pero su conexión SQL requiere B01. Los resultados Windows siguientes no se trasladan automáticamente entre equipos; no ejecutar scripts de creación/población para resolver configuración.

En el entorno histórico CachyOS, `sql-server-local` era un contenedor independiente que publicaba 1433. Compose de este proyecto no lo modifica ni lo reemplaza. `127.0.0.1` dentro de un contenedor apunta a ese contenedor, no al host ni a SQL Server.

En el entorno Windows de T07, el motor es el servicio local **MSSQLSERVER**, no un contenedor; atiende en el puerto 1433 y mantiene hora peruana (-05:00). Docker lo alcanza por `host.docker.internal:1433`. Se creó una identidad SQL independiente con SELECT de lectura para perfil y servicio (T08) y contraseña local ignorada por Git; en `Pago` solo puede leer cuatro columnas. Ver [conexión y prueba](../apps/server/README.md). La cuenta administrativa Windows solo funciona desde el host por conexión local (`-S .`), no como credencial del backend. El servidor Eve arranca sin abrir conexiones SQL.

Los scripts 01/02 no se ejecutan al construir o iniciar la aplicación. La configuración de recreación de SQL Server, sus volúmenes y America/Lima sigue pendiente de documentarse con detalle, sin alterar la instancia activa.

## Empaquetado y VPS

Este es el entorno de **desarrollo**, con código montado; no una imagen de producción terminada. B01 corregirá EXDEV del build entre .eve y .output, reproducido también en Linux. B08 (antes T29) consolidará targets de compilación/runtime, artefactos, dependencias de producción y comandos para VPS. Salud y volumen de estado ya están configurados para desarrollo. Las imágenes finales no incluirán .env, .eve, tokens, .git, bases ni backups. La IA con suscripción de ChatGPT sigue limitada al acceso local documentado de Eve; una nube requiere revisar esa modalidad.
