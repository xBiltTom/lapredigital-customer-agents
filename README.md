# LaPreDigital · Agente Académico de CUSTOMERS

Proyecto académico de Ingeniería de Sistemas de la Universidad Nacional de Trujillo. El objetivo es acompañar la preparación de estudiantes mediante un agente que consulte su progreso, explique riesgos y proponga acciones compatibles con su servicio.

## Continuar el proyecto

1. Leer [AGENTS.md](AGENTS.md) y [el punto de continuación](docs/ESTADO.md).
2. Seguir [el roadmap de tareas y commits](docs/ROADMAP.md).
3. Consultar [contexto y decisiones](docs/CONTEXTO.md) y [arquitectura](docs/ARQUITECTURA.md).

**Siguiente tarea: T08, consultar perfil, servicio y prestaciones.** Una tarea corresponde a un commit; el roadmap incluye dependencias y criterios para cerrarla.

## Estado actual

La base OLTP y los escenarios ficticios ya existen. El backend mínimo de Eve arranca en Docker y tiene un endpoint de salud. El login local de ChatGPT, una herramienta fija y la conexión SQL de lectura se verificaron; aún faltan las herramientas de negocio y la interfaz. Por decisión del usuario se conserva el esquema actual mientras se desarrolla el prototipo local.

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
./scripts/dev npm ci
./scripts/dev npm run check
./scripts/dev npm run typecheck
docker compose up --build -d server
curl http://127.0.0.1:3000/eve/v1/health
```

Node está aislado en Docker: imagen oficial fijada por digest, Node 24.22.3 y npm 11.19.1. `scripts/dev` ejecuta cada comando en un contenedor temporal con tu UID/GID; dependencias, caché y estado de Eve quedan en volúmenes del proyecto. No es necesario instalar Node en el host. Ver [la guía de infraestructura](infra/README.md). Si tu UID/GID difiere de 1000, exporta `LOCAL_UID=$(id -u)` y `LOCAL_GID=$(id -g)` antes de usar Compose directamente.

La salud devuelve `ok: true`. No hay panel; el login funcionó en la TUI con `scripts/eve-local`. `localDev()` solo admitió peticiones desde dentro del contenedor, mientras que las peticiones desde Windows al puerto publicado recibieron 401. Antes de repetir `npm ci`, detener los procesos del servidor para evitar reemplazar sus dependencias. [Detalles y comando de login](apps/server/README.md).

`npm run check` revisa únicamente estructura y enlaces; `typecheck` verifica el backend. `build:server` falla con EXDEV en Docker Desktop/Windows al mover la salida entre volúmenes; se documenta en [ESTADO.md](docs/ESTADO.md). Ninguno de esos comandos ejecuta SQL ni prueba una respuesta del modelo.

El archivo `.env.example` documenta la conexión SQL sin secretos. En Windows, `scripts/provision-sql-app.ps1` creó `lapredigital_app` con lectura de `dbo.Estudiante` y guardó la contraseña generada en `.env`, excluido de Git. La conexión se prueba mediante `docker compose run --rm --no-deps --workdir /workspace/apps/server server npm run db:check`; no se abre al iniciar Eve.

## Base de datos

Los scripts se ejecutan en orden 01 → 02; 03 sirve para verificar y 04 para explorar. No ejecutar 01/02 sobre la base actual para arrancar la aplicación. Consultar [las instrucciones de database](database/README.md).

Última verificación SQL documentada: 12 de noviembre de 2026, 29 casos con 24 OK y 5 hallazgos pendientes. Ese resultado es previo a esta organización del repositorio; en esta tarea no se ha reconstruido ni modificado la base.
