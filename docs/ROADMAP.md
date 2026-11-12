# Roadmap del MVP de LaPreDigital

Actualizado el 12/11/2026. El usuario adelantó el deadline y autorizó terminar el MVP en una sola pasada de como máximo una hora (inicio de esta entrega: 20:16:59 UTC). Este alcance sustituye B02–B08; B01 ya está terminada en 795aad2. Un entregable funcional equivale a un commit con su verificación y ESTADO.md.

## Entregables de esta pasada

| ID | Estado | Resultado | Sustituye |
| --- | --- | --- | --- |
| M01 | Hecha | Diagnóstico SQL, agente con herramientas y propuestas transaccionales con aprobación/simulación | B02, B03, B06 y backend B07 |
| M02 | Hecha | Panel React/Vite: selección, ficha, evidencias, chat real y bandeja de intervenciones | B04, B05 y UI B07 |
| M03 | Hecha | Arranque reproducible, empaquetado, pruebas de navegador y guía de demo | B08 |

## M01: backend defendible

- Regla de inactividad 72/168 horas e incidencias >48/>96, mayor riesgo, pendiente sin datos.
- Cumplimiento de ruta vigente en ventana de 30 días sin canceladas; mejora solo por grupo comparable, en pp.
- Narrativas interpretadas por el modelo con IDs y huella de las fuentes; sin autorizar contacto por el mero texto. Cache de interpretación privada y separada por base.
- Herramientas sin SQL libre/shell/archivos generales. El servidor fija alumno y dueño por conversación.
- Evaluación/señales/propuesta/evento en transacción, evidencia revalidada, bloqueo por alumno y deduplicación persistente.
- Solo el dueño aprueba/rechaza; simulación revalida permisos y nunca crea Mensaje ENVIADO/ENTREGADO. No acredita C-4.
- Verificado: 14 pruebas unitarias, tipos, build, lectura de casos demo y transacciones en LaPreDigital_Customers_MvpTest. Chat real de Carla usó consultar_diagnostico e interpretar_contexto.

## M02: panel que permite demostrar el flujo

- Dueño entra con token local; scripts/open-panel abre el acceso sin imprimirlo.
- Selecciona estudiante, consulta progreso, servicio, riesgo, casos, mensajes y valoraciones.
- Conversa con el modelo real; ve herramientas utilizadas, referencia de sesión y errores explícitos.
- Registra propuesta, aprueba/rechaza y simula. La UI identifica la simulación.
- Cambiar de alumno cambia la conversación. Pruebas de escrituras de navegador apuntan a SQL aislado.

## M03: entrega y continuidad

- scripts/start levanta frontend y reutiliza Eve abierto; scripts/chat-local desbloquea el llavero.
- Compose de desarrollo y artefactos/imágenes compilados, sin claves dentro de bundles.
- Comprobar desktop/móvil, autenticación, casos principales y flujo de propuesta.
- README con pasos exactos de arranque y demo; ESTADO.md distingue ejecución real de límites.

## Mejoras posteriores solicitadas

| ID | Estado | Resultado |
| --- | --- | --- |
| M06 | Hecha | Contexto institucional del informe 7.1 cargado siempre en Eve; identidad de agente académico y estados de acciones veraces sin etiqueta global de simulación. |
| M05 | Hecha | Conversación persistente por dueño/alumno, historial desde Eve, respuesta progresiva NDJSON y Markdown con Streamdown. |
| M04 | Hecha | Ficha visible de contacto del estudiante/apoderado y pestaña de desempeño con todos los intentos, versiones de ruta, actividades, dificultades y revisiones. Reutiliza la API existente; compilación y reconstrucción Docker. |

## Fuera de esta entrega

DataMarts/cierres mensuales, KPI oficiales C-1–C-7 completos, agenda automática, proveedores de comunicación, agentes de otras fases, cobros, cambios de plan, referidos, portal familiar y autenticación de producción. No bloquear la demo por esas extensiones.

M05 añadió respuesta progresiva e historial por estudiante sobre las sesiones de Eve. El login local ChatGPT requiere un proceso con llavero desbloqueado y no equivale a API/despliegue cloud. No consumir MiniMax.

## Convenciones y comprobación

Leer AGENTS.md, ESTADO.md y CONTEXTO.md. Reglas del informe 7.1; esquema SQL congelado. Se conservan los cuatro scripts y los cinco HALLAZGO históricos. Hora peruana, GETDATE y NVARCHAR para narrativas.

La aplicación puede escribir evaluaciones/propuestas/eventos con permisos acotados; no recibe sa, DDL ni permisos para cambiar alumnos, pagos o rutas. Los scripts 01/02 solo se reutilizan contra la base aislada de pruebas, nunca al arrancar ni sobre el OLTP activo.

Reutilizar node:test y trazas de Eve. Tipos y pruebas dirigidas por funcionalidad; no reinstalar dependencias sin cambios. Cada commit incluye su implementación y estado. Push normal; preservar cambios del usuario.

## Extensión autorizada en 30 minutos (12/11/2026)

| ID | Estado | Entregable |
| --- | --- | --- |
| M07 | Hecha | Temario UNT 2027 versionado, progreso por tema con historial, mensajería local y consultas al dueño; SQL canónico e importación no destructiva. |
| M08 | Hecha | Dashboard global, herramientas por rol, acompañamiento individual y portal academia/mensajería con escalamiento. |
| M09 | Hecha | Servicio Docker separado, compilación, verificación del circuito y documentación de demostración. |
| M10 | Hecha | Pulido visual del dashboard y navegación común con Acompañamiento, verificación por compilación. |
| M11 | Hecha | Portal diferenciado, nombres reales de destinatarios, asistente de estudio y asistente de seguimiento con alcances separados. |
| M12 | Hecha | Cabecera de mensajería desde la perspectiva del participante: bot como contacto e identidad propia en Tu cuenta. |
