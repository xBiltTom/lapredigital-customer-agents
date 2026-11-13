# Backend Eve/Nitro del MVP

Node 24, Eve 1.0.0-rc.10, AI SDK 7.0.137, Zod 4.6.7 y mssql 12.7.14. Todo se ejecuta en Docker; ver [README raíz](../../README.md).

## API del dueño

| Método/ruta | Función |
| --- | --- |
| GET /eve/v1/health | Salud pública |
| GET /api/status | Estado del modelo |
| GET /api/estudiantes | Listado de estudiantes autorizados |
| GET /api/estudiantes/:id | Diagnóstico y evidencias actuales |
| POST /api/chat | Mensaje del alumno seleccionado y UUID de conversación |
| POST /api/estudiantes/:id/propuestas | Proponer seguimiento, revisión de ruta o derivación |
| POST /api/estudiantes/:id/intervenciones/:intervencionId | Aprobar, rechazar o simular |

Datos y acciones exigen Bearer local del dueño activo, con origen local. Las tools toman alumno/dueño de la identidad validada del canal; no aceptan estudianteId del modelo. Cambiar alumno cambia la dirección de conversación. El modelo no tiene herramienta de aprobación.

lib/academico/reglas.ts contiene cálculos puros; lib/academico/diagnostico.ts las fuentes y huella narrativa; lib/academico/intervenciones.ts transacciones y revalidación. Sin SQL libre ni herramientas generales de archivos/bash. El archivo de contexto es privado y lo administra la app, no el modelo.

El pool abre solo cuando hace falta. SELECT de fuentes, INSERT de evaluación/señales/eventos e INSERT/UPDATE de intervención; sin sa ni DDL. Los permisos están en infra/sql y scripts/grant-mvp. Las operaciones respetan plan, autorizaciones y revisión previa; la app conserva los hechos existentes.

## Build y estado

build:server prepara fuentes mínimas en .eve/packaged y ejecuta Eve allí para evitar EXDEV. La imagen mvp-runtime copia ese compilado y el frontend; home.ts sirve solo index y assets permitidos, sin exponer archivos del proyecto.

Eve conserva sesiones/trazas; la interpretación está en .eve/contextos/<base>, con huella de las narrativas. Keyring cifrado fuera de Git. scripts/chat-local ejecuta D-Bus/llavero y Eve juntos; el servicio estándar no lo desbloquea. Datos de dev y modo compilado tienen raíces de estado diferentes.

Las fechas SQL son peruanas, serializadas con -05:00. No hay un cierre mensual congelado. Simular no crea mensajes y deja MensajeSeguimientoId NULL para no acreditar C-4.

## Verificación

Desde la raíz: scripts/test-mvp usa SQL aislado; scripts/test-browser usa navegador real con esa API aislada. Unitarias: scripts/dev npm test. Build/tipos: comandos del README.

Modelos reales verificados aparte: Carla con consulta/interpretación, Gabriela pendiente en navegador e Inés sin contacto. No repetir llamadas de modelo en cada prueba.

Antes de cambiar Eve, leer node_modules/eve/docs/README.md y la guía de la versión instalada. Se usaron canales custom, tools, cliente, autenticación y self-hosting. No asumir APIs de otra versión.

Para recorrer el flujo paso a paso y ubicar cada responsabilidad, leer [la guía de lib](lib/README.md).
