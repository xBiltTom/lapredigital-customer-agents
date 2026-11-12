# Instrucciones para continuar LaPreDigital

## Lectura inicial

Leer [README.md](README.md), [docs/ESTADO.md](docs/ESTADO.md), [docs/CONTEXTO.md](docs/CONTEXTO.md), [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) y [docs/ROADMAP.md](docs/ROADMAP.md). Antes de escribir SQL o reglas del negocio, contrastar con [el informe](docs/reference/documento_InteligenciaNegocios.pdf) y los cuatro scripts en database/.

## Alcance autorizado

- Construir primero un prototipo local del Agente Académico de CUSTOMERS. Los demás agentes del embudo y la nube son posteriores.
- Conservar el esquema actual por la decisión más reciente del usuario. Si hace falta cambiarlo para un caso real, mostrar la evidencia y discutirlo; no reconstruir la base ni lanzar scripts de creación/población al iniciar la app.
- Si se acuerdan cambios de modelo, editar directamente 01, sincronizar 02, historiales, triggers, pruebas y consultas. No inventar una migración como fuente principal del esquema.
- La aceptación de términos al registro origina automáticamente las autorizaciones previstas. Respetar la revocación posterior. No inventar un formulario adicional de autorización por cada canal/mensaje.
- Un mensaje simulado no es ENVIADO ni ENTREGADO. No llamar proveedores de comunicación reales sin una instrucción específica.
- No instalar servicios de pago ni consumir MiniMax sin confirmar que el saldo es API y que su uso está autorizado.

## Stack y código

TypeScript + Node 24; npm workspaces; Eve/Nitro en apps/server; React/Vite en apps/web; mssql; Zod; Vitest. Existe el backend mínimo, la conexión SQL de lectura y repositorios de perfil/servicio con identidad validada; frontend y herramientas de negocio siguen pendientes. No introducir Next.js/NestJS, Python u otro framework de agentes sin una decisión nueva del usuario.

Verificar login local ChatGPT temprano. No asumir que una suscripción es una API key ni que sirve para un despliegue. Leer docs de la versión instalada de Eve/AI SDK antes de programar su integración.

El modelo llama herramientas concretas, no SQL libre. SQL parametrizado en repositorios; reglas y permisos en servicios; transacciones para escrituras relacionadas; el backend verifica el destinatario y la identidad activa. No dar herramientas generales de bash, archivos, credenciales ni DDL al agente de negocio.

## Convenciones de datos

- GETDATE y fechas peruanas; mantener America/Lima en cualquier recreación autorizada del contenedor.
- DATETIME2(0) donde basta el segundo; no alterar la precisión histórica sin justificación.
- VARCHAR para catálogos/datos previstos en español; NVARCHAR para narrativas Unicode. Mantener el literal N'DUEÑO' y la intercalación Latin1_General_100_CI_AS_SC.
- Historial normal con triggers multirregistro y copia de la fila anterior, operación U/D; columnas históricas con iguales tipos y tamaños que las actuales.
- Fecha de ingreso a LEAD: primer formulario válido; no reintroducir la columna redundante de alta.
- Mantener QUOTED_IDENTIFIER, XACT_ABORT, restricciones e índices con propósito; no agregar complejidad sin evidencia.

## Trabajo y commits

Una tarea del roadmap = un commit. Incluir en ese commit su implementación, pruebas pertinentes, estado de la tarea y ESTADO.md actualizado. No crear commits vacíos, de seguimiento redundante ni agrupar varias tareas inconexas. No hacer push forzado.

Revisar git status antes de editar; las consultas personales del 04 y cualquier cambio del usuario se conservan. Las instrucciones actuales del usuario prevalecen sobre estos acuerdos si cambia el alcance.

## Entorno aislado

Node/npm del proyecto se ejecutan en Docker: `./scripts/dev node --version` y `./scripts/dev npm run check`. No instalar dependencias con el npm global del host. Imagen oficial fijada por digest, usuario sin privilegios y volúmenes del workspace. El Compose de desarrollo no administra ni reconstruye SQL Server; no confundirlo con la imagen de producción que se completará en T29.

## Verificación y continuidad

Hoy: `./scripts/dev npm run check` valida únicamente el workspace y `./scripts/dev npm run typecheck` verifica tipos. `build:server` falla con EXDEV en Docker Desktop/Windows al mover el resultado entre volúmenes. `docker compose up --build -d server` inicia salud en 127.0.0.1:3000; `localDev()` admite sesiones desde dentro del contenedor, pero desde Windows devuelve 401. T05 verificó el login de ChatGPT y una herramienta fija en la TUI lanzada con `scripts/eve-local`; el servidor estándar no desbloquea ese llavero. T08 añadió repositorios SQL de perfil y servicio, aún no expuestos como herramientas de negocio. Detener los procesos del servidor antes de reinstalar dependencias con npm ci. CLI y servidor comparten el volumen eve_state, excluido de Git; el llavero persistente está en keyring_state.

Separar resultados históricos, revisión estática y ejecución real. Los datos ficticios envejecen; no ocultar los cinco HALLAZGO conocidos cambiando las expectativas de prueba. Usar una base aislada para integración destructiva, no la base académica activa. No subir .env, .eve, tokens, volcados ni archivos de datos a Git.

Al terminar una tarea, anotar cambios, pruebas con su resultado, incertidumbres y siguiente tarea concreta en ESTADO.md. Las comprobaciones que requieran credenciales o un login del usuario deben declararse pendientes si no se realizaron.
