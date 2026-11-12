# Estado y continuidad

Actualizado: 12/11/2026. Instrucción vigente: terminar un MVP local en una sola pasada de máximo una hora; reemplaza el plan individual B02–B08.

## Último cambio: M10 — diseño y navegación unificados

Dashboard y Acompañamiento comparten WorkspaceNav en una barra lateral con selección activa y descripción de cada modo. Se bloquea el cambio mientras hay una operación de chat activa. Dashboard conserva el marco visual del workspace: cabecera, tarjetas con iconos, avance por tema con barras, avatares y panel de dirección. Ajustes responsive sin cambios de datos ni negocio.

Verificación acotada: build web con TypeScript correcto; sin suites adicionales. El frontend de desarrollo aplica los cambios al recargar; se reconstruye también la imagen compilada. Siguiente paso: revisión visual del dueño, sin ampliar alcance.

## M09 — entrega del circuito local

Servicios: dashboard/acompañamiento 5173; portal Docker separado 5180, con su propio proceso Vite y proxy al mismo Eve desbloqueado; paquete compilado 3010. scripts/start arranca web y portal y conserva el proceso del modelo. README contiene el guion de demostración y la carga idempotente. La imagen se reconstruyó con backend y frontend actualizados; el modelo compilado sigue requiriendo el desbloqueo documentado, sin promesa de VPS con suscripción.

Cierre: tipos backend y build frontend correctos; navegador real en escritorio/móvil y circuito de consulta/decisión con modelo real comprobados en M08. Se revisaron las capturas y se ajustó el scroll de mensajes. Las consultas pendientes aparecen fuera del área desplazable del historial. Una última validación impide comunicar una decisión si cambió el contacto o el acceso Plus de su destinatario. La lectura del agente no acredita entrega de bandeja. Sin proveedores externos ni cambio de los pagos o etapas originales.

Límites: portal de demostración local con selector controlado por el dueño; no es alta/login multiusuario de producción. Estados por tema, sin evaluación de dominio ni notas generadas. Mensajes entrantes tienen respuesta por turno; el dashboard conserva streaming. Actualización de bandeja cada 2.5 s y resumen cada 12 s. No hay programación autónoma, colas distribuidas, garantía de envío único ante reintentos concurrentes ni atribución automática al KPI C-4. El catálogo incluye el alcance metodológico del JSON, no una malla certificada CEPUNT.

No continuar con extensiones automáticamente: el usuario revisa el circuito y pide ajustes concretos. Conservar la terminal de Eve abierta y los datos actuales. M07–M09 son los tres commits de esta entrega.

## M08 — dashboard, portal y agente que actúa

Dashboard global del dueño con 14 estudiantes, 12 CUSTOMERS, riesgo, avance del temario, casos abiertos y chat global persistente. Acompañamiento conserva sesiones individuales y añade el temario. Las definiciones diferencian temas completados de cumplimiento de actividades de ruta: no son cifras contradictorias.

El portal tiene vistas academia y mensajería, selección controlada de estudiante/apoderado, estados del temario y conversación. El dueño emite un token de participante firmado, con estudiante, contacto, rol y vencimiento; el backend revalida vínculo y Plus vigente para apoderados. No se da el token del dueño al agente/participante ni acceso a herramientas privadas. Cambiar participante/canal descarta respuestas de lecturas anteriores. El selector de control usa el acceso del dueño en su propia sesión de navegador.

operar_plataforma permite resumen global, detalle, temario, envío local preautorizado, consulta al dueño, bloqueo de no contacto y comunicación de una decisión explícita. El envío verifica servicio, prestación, finalidad/canal PLATAFORMA, revocaciones y narrativas pendientes. Mensajes quedan en MensajeCanalLocal; FechaEntrega se confirma solo al consultar la bandeja del participante, no cuando el agente lee su contexto. No hay WhatsApp/Instagram real ni cómputo automático de C-4.

Las respuestas entrantes se entregan al agente del participante y su respuesta vuelve al mismo hilo. Lo desconocido/económico se registra en ConsultaDueno y aparece en el chat del dashboard. El dueño responde por tarjeta o mediante RESPONDER_CONSULTA en el chat; el agente comunica su decisión. Los modos global, individual y participante tienen instrucciones específicas y contexto institucional común.

Verificación real: conversación académica con Ana usando su temario; envío desde chat global a su bandeja; solicitud de descuento → consulta al dueño → respuesta por tarjeta → comunicación al interesado. Segunda consulta de beca resuelta escribiendo la decisión en el chat global (RESPONDIDA). Avance del portal actualizado y reflejado en SQL/ficha; rechazo de apoderado sin Plus y acceso válido de apoderado de Elena. Playwright: dashboard, navegación a desempeño, portal, filtro Álgebra, mensajería, escritorio/móvil sin errores JS; capturas inspeccionadas en tmp/*-extension*.png. Tipos y builds correctos. No se ejecutaron suites históricas ni pruebas destructivas sobre el OLTP.

Siguiente tarea: M09, terminar empaquetado/documentación y entregar. No añadir capacidades nuevas.

## M07 — temario, avance y canal local

Autorización: extensión de 30 minutos iniciada el 12/11/2026 a las 21:54 UTC. Temario JSON aportado por el dueño incorporado sin cambiar su contenido: 18 cursos, 162 temas; subtemas y documento completo conservados. ContenidoUNT es catálogo versionado separado de los recursos/rutas existentes para no alterar sus FK ni comparabilidad. ProgresoTemaUNT identifica estado de estudio y origen; no es una nota ni acredita dominio. Carga de demostración: 2.268 registros (14 alumnos × 162 temas), origen CARGA_DEMO; LEAD/TURNED empiezan pendientes. El portal registra PORTAL_LOCAL y eventos de estudio. Historial multirregistro conserva las filas anteriores U/D.

Se añadieron MensajeCanalLocal y ConsultaDueno: el transporte local tiene identidad y entrega comprobable propias, no se confunde con Mensaje WHATSAPP externo ni acredita automáticamente C-4. Se conservan los registros originales. Dos autorizaciones ficticias iniciales de REPORTES/PLATAFORMA se incorporaron para los apoderados de la carga; no se sobrescriben decisiones existentes.

01/02 son fuente canónica; 03/04 añaden lecturas sin cambiar casos personales ni expectativas históricas. scripts/import-temario deriva el bloque nuevo directamente de 01/02 y aplica solo creación faltante/carga idempotente/permisos a la base existente. Reejecutado: cero duplicados. El primer intento mezcló salida de build con SQL y falló al parsear; se corrigió para usar tools sin --build y se repitió correctamente. No hubo reconstrucción del OLTP activo.

Siguiente tarea: M08/M09, integrar y cerrar las pantallas/acciones ya desarrolladas en esta pasada.

## M06 — contexto de LaPreDigital e identidad del agente

Instrucciones principales reescritas para hablar como Agente Académico de LaPreDigital, con Markdown y respuestas centradas en el negocio. Se retiró la afirmación global «Toda comunicación del MVP es SIMULADA». Se conserva la obligación de describir el resultado real de cada acción, incluidas las simulaciones explícitas, sin afirmar envíos o C-4 inexistentes. No se ocultaron resultados ni se cambiaron proveedores, permisos, interfaz o SQL.

Nuevo agent/instructions/10-plataforma.md, cargado siempre como contexto de sistema por Eve: propuesta de valor, público, recursos, roles, planes/precios/modalidades, prueba gratuita, embudo y transiciones, becas, renovaciones, apoderados, actividades C-1–C-7, riesgo, autorizaciones e indicadores/semáforos. Fuente: informe 7.1, secciones 1–7, contrastado con las decisiones posteriores y los catálogos SQL. Distingue conocimiento del servicio de herramientas disponibles; consultas generales no requieren datos personales.

Verificación acotada: revisión del informe y Markdown; build Docker correcto. La primera lectura de /eve/v1/info todavía mostraba el prompt viejo; tocar agent/agent.ts provocó la recarga de Eve sin reiniciar su terminal/llavero. Se verificó después contexto nuevo presente y frase vieja ausente. Una llamada real en la sesión existente explicó correctamente LaPreDigital, Meta UNT Plus (S/ 99.90 mensual / S/ 499.90 semestral) y Explora UNT (14 días, sigue LEAD sin cobros), sin herramientas ni datos personales. No se ejecutaron suites SQL, unitarias ni de navegador. Imagen compilada reconstruida y reiniciada. Siguiente paso: el dueño conversa desde el panel; no ampliar alcance automáticamente.

## M05 — historial por estudiante y Markdown progresivo

La dirección de chat ahora es estable por dueño/alumno y la fija el servidor. GET /api/estudiantes/:id/chat reconstruye mensajes de usuario y respuestas públicas mediante foldEvents/conversation/reply de Eve, sin exponer razonamiento o salidas de herramientas. El panel recupera ese historial al cambiar de alumno o recargar. No se guardan chats ni credenciales en localStorage. Las antiguas sesiones con UUID aleatorio permanecen en Eve; no se fusionan automáticamente con la nueva conversación principal.

POST /api/chat admite application/x-ndjson: entrega texto mientras se genera, nombres de herramientas y resultado final. Conserva JSON por compatibilidad. Al terminar corrige la respuesta visible con el reply final; las fallas se muestran explícitamente. Desconectar el lector no cancela el turno de Eve. Streamdown 2.7.1 renderiza Markdown, listas, tablas y código con CSS del panel; HTML e imágenes incrustadas desactivados. Sin plugins adicionales ni Tailwind.

Verificación dirigida: tipos backend y build web correctos. Chat real del alumno 7: inicio, herramientas y texto antes de fin; cambio de alumno 7 → 3 → 7 recuperó 2 mensajes y misma sesión. Segundo mensaje recordó «prueba de continuidad jazmín» sin consultar herramientas. No se ejecutaron suites SQL ni de navegador. Se reconstruyó/reinició el paquete Docker; la demo con modelo continúa en el proceso de Eve desbloqueado de 5173. Siguiente paso: el usuario recarga y usa el chat.

## M04 — ficha completa del estudiante

Se muestran en Resumen los contactos del estudiante y apoderado, parentesco, universidad/carrera, fecha de examen, disponibilidad en horas y registro. Nueva pestaña Desempeño: todos los intentos finalizados, aciertos/total/porcentaje, contexto de comparabilidad, actividades de todas las versiones con fechas y estados, dificultades y revisiones. Usa campos ya disponibles en la API; no cambia SQL ni herramientas del agente.

Verificación acotada por petición del usuario: build web con TypeScript correcto y lectura de la ficha SQL/API 200 con contactos e intentos. Imagen Docker reconstruida y servicio compilado reiniciado; no se ejecutaron suites SQL, navegador ni llamadas al modelo para este cambio. Siguiente paso: el usuario revisa la ficha desde el panel.

## Resultado

M01 (5ae8bde): diagnóstico SQL, reglas, interpretación de narrativas por el modelo y propuestas transaccionales.
M02 (f46fd2f): panel React/Vite, chat real, evidencias y aprobación/simulación.
M03: imagen compilada, comprobaciones y runbook; consultar su hash en git log después del commit.

No continuar automáticamente con extensiones: usar la demo y atender los cambios que pida el usuario. Leer README para arrancar; .env de este equipo ya existe y no debe sobrescribirse.

## Servicios y acceso

- SQL Server 2022 en sql-server-local, base LaPreDigital_Customers, America/Lima.
- Eve abierto por el usuario mediante scripts/chat-local, con llavero desbloqueado y modelo ready.
- Panel de desarrollo en http://localhost:5173, proxy al proceso de Eve; scripts/start detecta ese proceso y excluye el backend de pruebas.
- scripts/open-panel abre el acceso del dueño sin imprimir el token. Token en .env privado (600), solo sessionStorage en navegador.
- Imagen compilada probada en http://localhost:3010. SQL/API/UI funcionan; el modelo requiere desbloquear el llavero dentro de ese proceso. No se verificó ese desbloqueo en modo compilado.
- .eve y keyring_state son privados/persistentes, fuera de Git. No reiniciar la terminal con modelo ni reinstalar npm sin necesidad.

## Funcionalidad y controles

El backend verifica el dueño activo en SQL y fija al alumno en la dirección de conversación; las tools no aceptan otro estudiante. Sin SQL libre, bash o archivos generales para el modelo. Los comentarios/mensajes se consideran datos no confiables.

Cumplimiento: ruta vigente, 30 días, sin canceladas, mismo conjunto para numerador/denominador. Mejora: primero y último cronológicos de cada grupo comparable, expresada en pp. Sin tareas/pruebas: no aplicable/sin datos.

Riesgo: umbrales exactos 72/168 y >48/>96 horas, apertura original para reabiertas, dificultad, intención explícita y valoración 1–2 con contexto. Prevalece ALTO conocido; datos incompletos no se fuerzan a BAJO. La clasificación estructurada preexistente no se usa como cálculo actual; se muestra su vigencia temporal.

El modelo registra interpretación con IDs y huella de mensajes/valoraciones. Cambiar esas fuentes invalida el contexto. Cache separada por nombre de base; narrativas ambiguas quedan pendientes. No se inventan caducidad de intención ni frecuencia de contacto.

Evaluación/señales/propuesta/evento se escriben en transacción con bloqueo por alumno. Se revalidan fuentes, nivel, dueño, plan y autorizaciones; deduplicación persistente por operación de negocio. Antes de aprobar/simular se vuelve a comprobar la evaluación y sus fuentes; cambio de propietario/fecha/contenido/estado o contradicción bloquea.

Solo API del dueño aprueba/rechaza/simula. El modelo solo propone. Simular requiere aprobación, deja resultado SIMULACION LOCAL y MensajeSeguimientoId NULL; no crea Mensaje ni acredita C-4. No se tocan pagos, etapas, precios ni rutas.

Permisos operativos en infra/sql/mvp-permissions.sql: SELECT de fuentes, INSERT de evaluación/señales/eventos y INSERT/UPDATE de intervención. Sin sa, DDL o UPDATE de datos académicos para la app. scripts/grant-mvp aplicó esos permisos; no cambió el esquema.

## Verificación realmente ejecutada

- Tipos y 14 pruebas node:test correctos: configuración, auth, paginación, umbrales exactos, vigencia, rutas y comparabilidad.
- Builds web y Eve completos dentro de Docker, sin EXDEV; artefactos en .eve/packaged y apps/web/.dist.
- SQL activo leído: Ana +15 pp, Carla -25 pp/ALTO, Diego no comparable/ALTO, Gabriela pendiente/no aplicable, Hugo evaluación vencida.
- Base aislada LaPreDigital_Customers_MvpTest recreada por scripts/test-mvp: evidencia ajena, bloqueo de Inés, rollback tras fallo intermedio, deduplicación, aprobación previa, simulación sin nuevos mensajes y reintento idempotente. Correcto.
- Playwright Chromium real: login, selección, escritorio 1440 y móvil 390 sin overflow ni errores JS; propuesta → aprobación → simulación por UI apuntando a SQL aislado. Capturas inspeccionadas en tmp/mvp-*.png.
- Chat real de Carla vía /api/chat: consultar_diagnostico + interpretar_contexto, explicación de -25 pp y ALTO. Sesión wrun_01M78QHM0MNTD5V2154X6Q51QP.
- Chat real de Gabriela desde navegador: pendiente con consultar_diagnostico; captura tmp/mvp-chat-real.png.
- Chat real de Inés: ambas herramientas, petición no contacto reconocida (Mensaje 10), servicio conservado y POST de seguimiento rechazado con 409.
- Imagen compilada: build y salud; / público 200; API anónima 401; listado/ficha del dueño 200. Se revisaron 193 artefactos sin contraseña SQL ni token de acceso.
- Hora: GETDATE textual y Date del driver coinciden con Perú; API devuelve offset -05:00.
- Sin envío real, sin MiniMax ni llamadas de modelo en pruebas automáticas.

## Base y antecedentes

Cuatro SQL canónicos conservados. No se recreó ni pobló el OLTP activo; solo la base de prueba. La carga original contiene 14 estudiantes, 501 registros operativos y 39 históricos. Los datos envejecen desde GETDATE de la carga.

Los 29 casos anteriores (24 OK/5 HALLAZGO) no se reejecutaron sobre la base activa en esta entrega. Los cinco huecos del esquema siguen descritos en CONTEXTO.md; las operaciones de la app añaden validaciones, sin proteger cualquier SQL directo.

B01 (795aad2) verificó login y herramienta fija, cuenta SQL, dueño y build. T05 Windows y su conexión nativa son antecedentes; no confundir con el entorno CachyOS actual.

## Límites del MVP

Un proceso local, chat progresivo con historial por estudiante, datos operativos actuales y aprobación humana. Sin cierres congelados/DataMarts/KPI oficiales completos, agenda automática, proveedores de comunicación, portal familiar, referidos, cambios de plan o agentes de otras fases.

No se prometen cuotas del modelo, despliegue con suscripción o persistencia del login real tras recreación. La fuente de verdad de negocio es informe 7.1 con decisiones posteriores del usuario. El código Windows se revisó estáticamente; la demo completa y el navegador se ejecutaron en CachyOS.
