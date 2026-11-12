# Instrucciones para continuar LaPreDigital

## Lectura inicial

Leer [README.md](README.md), [docs/ESTADO.md](docs/ESTADO.md), [docs/CONTEXTO.md](docs/CONTEXTO.md), [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) y [docs/ROADMAP.md](docs/ROADMAP.md). Antes de escribir SQL o reglas del negocio, contrastar con [el informe](docs/reference/documento_InteligenciaNegocios.pdf) y los cuatro scripts en database/.

## Extensión más reciente

M07–M09 añadieron temario SQL, dashboard global y portal Docker 5180 con mensajería local bidireccional/escalamiento. Leer ESTADO.md y README para la demo. Mantener separación global/individual/participante; no devolver herramientas privadas al participante ni enviar a proveedores reales. El esquema se amplió con autorización explícita, conservando datos existentes. No ampliar automáticamente tras esta entrega.

## Alcance autorizado

- Instrucción más reciente: terminar el MVP en una pasada de una hora. Seguir M01–M03 del roadmap; ya no esperar una reestructuración ni ejecutar B02–B08 individualmente. Priorizar diagnóstico, chat real, propuesta/aprobación/simulación y arranque local. Extensiones fuera de alcance.

- Construir primero un prototipo local del Agente Académico de CUSTOMERS. Los demás agentes del embudo y la nube son posteriores.
- Conservar el esquema actual por la decisión más reciente del usuario. Si hace falta cambiarlo para un caso real, mostrar la evidencia y discutirlo; no reconstruir la base ni lanzar scripts de creación/población al iniciar la app.
- Si se acuerdan cambios de modelo, editar directamente 01, sincronizar 02, historiales, triggers, pruebas y consultas. No inventar una migración como fuente principal del esquema.
- La aceptación de términos al registro origina automáticamente las autorizaciones previstas. Respetar la revocación posterior. No inventar un formulario adicional de autorización por cada canal/mensaje.
- Un mensaje simulado no es ENVIADO ni ENTREGADO. No llamar proveedores de comunicación reales sin una instrucción específica.
- No instalar servicios de pago ni consumir MiniMax sin confirmar que el saldo es API y que su uso está autorizado.

## Stack y código

TypeScript + Node 24; npm workspaces; Eve/Nitro, React/Vite, mssql, Zod y node:test. MVP implementado: panel, diagnóstico, herramientas académicas, chat real y propuestas/aprobación/simulación. Mantener este stack; no añadir frameworks, colas o infraestructura sin necesidad. Playwright verifica el navegador.

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

Una tarea activa del roadmap = un commit. El deadline sustituyó B02–B08 por M01–M03: backend, panel y empaquetado. No retomar extensiones automáticamente. Incluir pruebas pertinentes y ESTADO.md en cada tarea. Sin commits vacíos ni push forzado. Reutilizar node:test y trazas nativas; no reinstalar ni repetir pruebas sin cambios/fallos que lo justifiquen.

Revisar git status antes de editar; las consultas personales del 04 y cualquier cambio del usuario se conservan. Las instrucciones actuales del usuario prevalecen sobre estos acuerdos si cambia el alcance.

## Entorno aislado

Node/npm del proyecto se ejecutan en Docker: `./scripts/dev node --version` y `./scripts/dev npm run check`. No instalar dependencias con el npm global del host. Imagen oficial fijada por digest, usuario sin privilegios y volúmenes del workspace. El Compose de desarrollo no administra ni reconstruye SQL Server; no confundirlo con la imagen de producción que se completará en B08 (antes T29).

## Verificación y continuidad

Hoy: 14 pruebas unitarias, tipos y builds pasan; scripts/test-mvp prueba escrituras solo en LaPreDigital_Customers_MvpTest. scripts/test-browser usa UI real y API aislada, sin invocar al modelo. Chats reales comprobados para Carla, Gabriela e Inés. Panel en 5173; imagen compilada en 3010 verificada para UI/API/SQL. La demo con modelo usa scripts/chat-local y requiere llavero abierto; no reiniciar esa terminal ni reinstalar npm sin necesidad. Mantener sesiones/contextos/keyring fuera de Git. No se verificó desbloqueo del modelo en el runtime compilado ni persistencia real tras recreación. Consultar ESTADO.md.

Separar resultados históricos, revisión estática y ejecución real. Los datos ficticios envejecen; no ocultar los cinco HALLAZGO conocidos cambiando las expectativas de prueba. Usar una base aislada para integración destructiva, no la base académica activa. No subir .env, .eve, tokens, volcados ni archivos de datos a Git.

Al terminar una tarea, anotar cambios, pruebas con su resultado, incertidumbres y siguiente tarea concreta en ESTADO.md. Las comprobaciones que requieran credenciales o un login del usuario deben declararse pendientes si no se realizaron.
