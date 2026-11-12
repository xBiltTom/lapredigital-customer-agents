# LaPreDigital · Agente Académico de CUSTOMERS

Proyecto académico de Ingeniería de Sistemas de la Universidad Nacional de Trujillo. El objetivo es acompañar la preparación de estudiantes mediante un agente que consulte su progreso, explique riesgos y proponga acciones compatibles con su servicio.

## Continuar el proyecto

1. Leer [AGENTS.md](AGENTS.md) y [el punto de continuación](docs/ESTADO.md).
2. Seguir [el roadmap de tareas y commits](docs/ROADMAP.md).
3. Consultar [contexto y decisiones](docs/CONTEXTO.md) y [arquitectura](docs/ARQUITECTURA.md).

**B01 finalizada; pendiente la reestructuración solicitada antes de continuar.** Se verificaron SQL, acceso del dueño, build y una respuesta/herramienta reales del modelo en este equipo. El roadmap posterior queda como referencia hasta incorporar la nueva dirección. Cada bloque corresponde a un commit. Ver [la revisión](docs/REVISION_T08_Y_PLAN.md) y [el estado vigente](docs/ESTADO.md).

## Estado actual

La base OLTP y los escenarios ficticios ya existen. El backend mínimo de Eve arranca en Docker y tiene un endpoint de salud. El login local de ChatGPT, una herramienta fija, la conexión SQL de lectura y los repositorios de perfil/servicio se verificaron; aún faltan las herramientas de negocio y la interfaz. Por decisión del usuario se conserva el esquema actual mientras se desarrolla el prototipo local.

Stack acordado: TypeScript, Node.js 24, Eve/Nitro, React/Vite, SQL Server 2022 en Docker, `mssql`, Zod y Vitest. El acceso local al modelo se comprobó con la suscripción de ChatGPT en la TUI de Eve; no equivale a acceso API ni a despliegue. MiniMax queda como alternativa si sus créditos son utilizables por API.

## Organización

| Ruta | Contenido |
| --- | --- |
| [database/](database/README.md) | Creación, población, pruebas y consultas del OLTP |
| [docs/reference/](docs/reference/documento_InteligenciaNegocios.pdf) | Informe del negocio, identificado por el usuario como versión 7.1 |
| [docs/database/](docs/database/REVISION_CUSTOMERS.md) | Revisión y verificaciones previas de la base |
| [apps/](apps/README.md) | Backend mínimo y ubicación prevista del frontend |
| [packages/](packages/README.md) | Ubicación prevista de contratos compartidos |
| [infra/](infra/README.md) | Docker, persistencia y comandos locales |
| scripts/ | Comprobaciones del workspace |

## Arranque local

```bash
./scripts/dev node --version
./scripts/dev npm --version
# Solo al clonar o cambiar el lockfile, con el servidor detenido:
./scripts/dev npm ci
# CachyOS con SQL Docker existente: una sola vez, si no existe .env:
./scripts/provision-sql-app
./scripts/dev npm run check
./scripts/dev npm run typecheck
./scripts/dev npm run build:server
docker compose up --build -d --wait server
curl http://127.0.0.1:3000/eve/v1/health
```

Node está aislado en Docker: imagen oficial fijada por digest, Node 24.22.3 y npm 11.19.1. `scripts/dev` ejecuta cada comando en un contenedor temporal con tu UID/GID; dependencias, caché y estado de Eve quedan en volúmenes del proyecto. No es necesario instalar Node en el host. Ver [la guía de infraestructura](infra/README.md). Si tu UID/GID difiere de 1000, exporta `LOCAL_UID=$(id -u)` y `LOCAL_GID=$(id -g)` antes de usar Compose directamente.

La salud es pública y devuelve ok: true. El resto requiere el token local del dueño; el backend comprueba su rol DUEÑO y estado activo en SQL. La terminal interna de Eve también puede acceder durante desarrollo mediante localDev y el mismo dueño validado. No hay panel todavía.

El build copia las fuentes mínimas a .eve/packaged dentro del volumen Docker y compila allí. El resultado .eve/packaged/.output permanece en Docker y ya no cruza sistemas de archivos: EXDEV corregido. Con server detenido, se puede probar el compilado con docker compose run --rm --no-deps --service-ports server npm run start:server. Es una verificación local, todavía no la imagen final de VPS.

Para usar el modelo: ejecutar ./scripts/chat-local en una terminal interactiva. Detiene server, abre el llavero y lanza Eve en el mismo proceso de entorno. Completar /login → ChatGPT Subscription y mantener la terminal abierta mientras se usa el chat. El servicio estándar no desbloquea el llavero. [Guía del servidor](apps/server/README.md).

El aprovisionamiento Linux genera .env privado con la cuenta lapredigital_app de solo lectura, el ID del dueño existente y su token aleatorio. No sobrescribe .env/logins ni recrea la base. Windows conserva provision-sql-app.ps1 y grant-sql-read.ps1; ambos usan el mismo archivo de permisos de infra/sql. Compose resuelve host.docker.internal en Linux con host-gateway. SQL se conecta al solicitar datos o autenticar al dueño, no al arrancar salud.

Pruebas de lectura: docker compose run --rm --no-deps --workdir /workspace/apps/server server npm run db:check, db:t08 y db:b01. npm test --workspace=@lapredigital/server (mediante scripts/dev) comprueba configuración, paginación y autenticación; check solo revisa estructura/enlaces. El estado separa pruebas actuales, login pendiente y resultados históricos.

## Base de datos

Los scripts se ejecutan en orden 01 → 02; 03 sirve para verificar y 04 para explorar. No ejecutar 01/02 sobre la base actual para arrancar la aplicación. Consultar [las instrucciones de database](database/README.md).

Última verificación SQL documentada: 12 de noviembre de 2026, 29 casos con 24 OK y 5 hallazgos pendientes. Ese resultado es previo a esta organización del repositorio; en esta tarea no se ha reconstruido ni modificado la base.
