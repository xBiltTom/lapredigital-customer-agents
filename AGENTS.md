# Instrucciones para continuar LaPreDigital

## Lectura inicial

Leer [README.md](README.md), [docs/ESTADO.md](docs/ESTADO.md), [docs/CONTEXTO.md](docs/CONTEXTO.md), [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) y [docs/ROADMAP.md](docs/ROADMAP.md). Antes de escribir SQL o reglas del negocio, contrastar con [el informe](docs/reference/documento_InteligenciaNegocios.pdf) y los cuatro scripts en database/.

## Alcance autorizado

- Instrucción más reciente: terminar el MVP en una pasada de una hora. Seguir M01–M03 del roadmap; ya no esperar una reestructuración ni ejecutar B02–B08 individualmente. Priorizar diagnóstico, chat real, propuesta/aprobación/simulación y arranque local. Extensiones fuera de alcance.

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

Una tarea activa del roadmap = un commit. El usuario pidió compactar el trabajo: B01–B08 sustituyen la ejecución individual de T09–T32; conservar su correspondencia y las extensiones pospuestas. Incluir implementación, pruebas pertinentes y actualización breve de ESTADO.md en ese commit. No crear commits vacíos ni agrupar tareas inconexas. No hacer push forzado. Reutilizar node:test y las trazas nativas de Eve; no añadir infraestructura o migrar pruebas sin necesidad concreta. Reinstalar dependencias solo si cambió el lockfile o faltan; repetir comprobaciones si hubo cambios relevantes o fallos.

Revisar git status antes de editar; las consultas personales del 04 y cualquier cambio del usuario se conservan. Las instrucciones actuales del usuario prevalecen sobre estos acuerdos si cambia el alcance.

## Entorno aislado

Node/npm del proyecto se ejecutan en Docker: `./scripts/dev node --version` y `./scripts/dev npm run check`. No instalar dependencias con el npm global del host. Imagen oficial fijada por digest, usuario sin privilegios y volúmenes del workspace. El Compose de desarrollo no administra ni reconstruye SQL Server; no confundirlo con la imagen de producción que se completará en B08 (antes T29).

## Verificación y continuidad

Hoy: check valida estructura, typecheck y 10 pruebas unitarias pasan; db:check/db:t08/db:b01 verifican SQL de lectura en CachyOS. B01 corrigió EXDEV en .eve/packaged y start:server pasó salud/autenticación. Usuario SQL, .env privado y host-gateway configurados sin recrear la base. Dueño autenticado con token y rol activo; apoderados requieren REPORTES_APODERADO vigente. El usuario completó login y se verificó respuesta y comprobar_conexion reales por API. B01 finalizada; el usuario pidió reestructurar antes de seguir: no iniciar B02 todavía. La terminal interactiva se cerró después; comprobar servicios al retomar. El servidor estándar no desbloquea el llavero; usar scripts/chat-local cuando corresponda. Sin herramientas académicas ni T09 completada. Estado/llavero fuera de Git; persistencia del login tras recreación no verificada. Consultar ESTADO.md.

Separar resultados históricos, revisión estática y ejecución real. Los datos ficticios envejecen; no ocultar los cinco HALLAZGO conocidos cambiando las expectativas de prueba. Usar una base aislada para integración destructiva, no la base académica activa. No subir .env, .eve, tokens, volcados ni archivos de datos a Git.

Al terminar una tarea, anotar cambios, pruebas con su resultado, incertidumbres y siguiente tarea concreta en ESTADO.md. Las comprobaciones que requieran credenciales o un login del usuario deben declararse pendientes si no se realizaron.
