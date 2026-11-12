# Backend local de Eve

Eve 1.0.0-rc.10, AI SDK 7.0.137, Zod 4.6.7 y mssql 12.7.14, fijados en el lockfile raíz. Node 24 corre en Docker. No existe frontend ni herramienta académica todavía.

## Desarrollo y SQL

Desde la raíz del proyecto:

~~~bash
# Solo al clonar/cambiar lockfile, con procesos del servidor detenidos:
./scripts/dev npm ci
# Solo primera preparación de CachyOS, con sql-server-local ya encendido:
./scripts/provision-sql-app
docker compose up --build -d --wait server
curl http://127.0.0.1:3000/eve/v1/health
~~~

El aprovisionamiento crea lapredigital_app con SELECT y genera .env privado con contraseña, ID del dueño activo existente y token local aleatorio. Rechaza sobrescribir .env o un login previo. No ejecuta 01/02 ni cambia tablas/datos. SQL ya existente conserva America/Lima.

Windows mantiene scripts/provision-sql-app.ps1 para instalación nueva y scripts/grant-sql-read.ps1 para permisos. Comparten infra/sql/app-read-permissions.sql con Linux. En instalaciones Windows que ya tienen .env/login, no repetir aprovisionamiento: conceder lectura de PersonalInterno con el script de grants y configurar OWNER_PERSONAL_ID/OWNER_ACCESS_TOKEN localmente según .env.example. Estos ajustes Windows no se ejecutaron en CachyOS.

Compose pasa variables SQL y del dueño solo a server; host.docker.internal se resuelve en Linux mediante host-gateway. El pool abre al solicitar datos o validar al dueño, no al arrancar la salud. .env.example es documentación, no una credencial.

~~~bash
docker compose run --rm --no-deps --workdir /workspace/apps/server server npm run db:check
docker compose run --rm --no-deps --workdir /workspace/apps/server server npm run db:t08
docker compose run --rm --no-deps --workdir /workspace/apps/server server npm run db:b01
./scripts/dev npm test --workspace=@lapredigital/server
./scripts/dev npm run typecheck
./scripts/dev npm run check
~~~

db:t08 comprueba perfil/servicio, beca, reactivación y apoderado compartido. db:b01 verifica dueño activo, denegación a soporte/personal inexistente y acceso familiar condicionado a REPORTES_APODERADO vigente. No realizan DML.

## Acceso local

Salud es pública. Desde el host, los canales de Eve exigen Authorization: Bearer con el token privado configurado; solo representa al dueño activo de OWNER_PERSONAL_ID. El servidor revalida rol DUEÑO y Activo en SQL, ignorando IDs enviados en el body. El dueño tiene allowAgentInfo para consultar la configuración operativa; no puede reemplazar herramientas mediante stubs.

La TUI de Eve dentro del contenedor puede acceder mediante localDev durante desarrollo y se resuelve al mismo dueño validado. No sirve en eve start ni admite conexiones externas como locales. Un Bearer erróneo no tiene ese fallback. Un origen web externo se rechaza; las futuras APIs del panel deben reutilizar el contexto autenticado.

IdentidadActiva del repositorio es un objeto **interno** del backend, no un contrato que se acepte desde JSON. Conserva acceso propio del estudiante y acceso familiar solo con servicio vigente y REPORTES_APODERADO. No existe aún un portal familiar ni una autenticación de alumnos.

## Modelo y llavero

~~~bash
./scripts/chat-local
~~~

El comando detiene server para liberar 3000, ejecuta scripts/eve-local y abre Eve en la terminal. Elegir/desbloquear la contraseña local del llavero y completar /login → ChatGPT Subscription. SSH_TTY=1 activa el flujo de dispositivo de esta versión; seguir en el navegador la dirección indicada por Eve. Mantener esa terminal abierta mientras se utiliza el modelo: el proceso del servidor hereda su D-Bus/llavero desbloqueado. Salir con /exit.

B01 verificó una respuesta real y comprobar_conexion por API autenticada en CachyOS, con dos pasos del modelo y la ejecución registrada de la herramienta. El login Windows T05 conserva su evidencia histórica. No se comprobó persistencia del login tras recrear el proceso. El servidor estándar no desbloquea el llavero. Nunca copiar tokens de Codex/ChatGPT al proyecto; MiniMax sigue sin consumo autorizado.

## Build dentro de Docker

~~~bash
./scripts/dev npm run build:server
# Con server detenido y el puerto 3000 libre:
docker compose run --rm --no-deps --service-ports server npm run start:server
~~~

scripts/build.mjs copia agent, lib, package.json y tsconfig.json a .eve/packaged dentro del volumen Docker. Eve compila allí; staging y .output comparten sistema de archivos. EXDEV queda resuelto sin modificar Eve y sin guardar el compilado en el host. start:server usa ese resultado y conserva autenticación.

No recompilar mientras se usa ese servidor compilado: el build reemplaza sus fuentes de preparación. Sus sesiones y las del modo dev tienen raíces distintas, ambas persistentes en el volumen; no se comprobó intercambio entre modalidades. Esto no es todavía la imagen de producción: B08 empaquetará fuente/artefactos/dependencias en un runtime reproducible. No se incluyen secretos en la copia de fuentes.

La advertencia de sandbox es independiente: no hay bash ni herramientas de archivos y no se monta el socket Docker.

## Persistencia y documentación

eve_state contiene .eve de desarrollo, sesiones y empaquetado; keyring_state conserva el llavero Linux cifrado. No borrar esos volúmenes al reinstalar dependencias. No versionar .env, .eve, llavero o trazas.

Antes de ampliar Eve, consultar en el contenedor node_modules/eve/docs/README.md y la guía relevante. B01 usó guides/auth-and-route-protection.md (incluido allowAgentInfo), reference/cli/index.md y guides/deployment/self-hosting/index.md. Las APIs instaladas prevalecen sobre ejemplos de otra versión.

Resultados ejecutados y pendientes concretos: [ESTADO.md](../../docs/ESTADO.md).
