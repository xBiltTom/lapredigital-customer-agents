# Estado y continuidad

Actualizado: 12/11/2026. Instrucción vigente: terminar un MVP local en una sola pasada de máximo una hora; reemplaza el plan individual B02–B08.

## Corrección local — alcance de consultar_diagnostico

En el portal, el agente respondió una vez «no tengo acceso a esa consulta» y en el turno siguiente sí dio el diagnóstico. Causa: las instrucciones globales pedían usar consultar_diagnostico sin aclarar que es exclusiva del dueño; la herramienta rechaza el modo participante en identidadHerramienta. Se acotó la instrucción a dashboard/acompañamiento, se indicó operar_plataforma ESTUDIANTE para el portal y se hizo explícito el error. Sin cambios de esquema, permisos ni datos. Verificación: check de workspace, tipos y 14 pruebas unitarias correctos; build compilado regenerado. Pendiente: reiniciar la terminal de `eve start` para cargar las instrucciones nuevas y repetir una consulta en el portal.

## Último cambio: M14 — KPI calculables de CUSTOMERS

Dashboard incorpora C-2.1 satisfacción, C-2.2 respuesta a valoraciones, C-2.3 resolución de incidencias de servicio/acceso y C-6.1 aceptación de cambios de plan. Tarjetas con valor, semáforo del informe, numerador/denominador, periodo/corte peruano y detalle de fórmula/fuentes. Es avance provisional del mes actual; no hay selector de meses cerrados ni snapshots históricos. Denominador cero devuelve null y No aplicable, sin convertirlo en favorable o cero.

Una sola función indicadoresCustomers alimenta el dashboard y consultar_indicadores, herramienta reservada al dueño en modo global. C-2.1 usa cada calificación válida respondida en el mes con igual peso; C-2.2 usa la cohorte de solicitudes emitidas en el mes (incluye respuesta recibida al corte sin exigir que la valoración sea válida); C-2.3 usa incidencias abiertas originalmente en el mes, excluye consultas/economía y no cuenta reabiertas como resueltas; C-6.1 usa propuestas presentadas en el mes con aceptación confirmada al corte (ACEPTADA/APLICADA). Aceptación no implica aplicación. No se añadió C-4 ni se cuentan mensajes locales como seguimiento formal.

Permiso adicional SELECT de FechaPresentacion/Estado/FechaRespuesta de PropuestaCambioPlan; no hay cambio de esquema, población ni escrituras de negocio. Se corrigió el contador «Servicio activo» para comprobar servicio vigente además de etapa CUSTOMER.

Verificación ejecutada: tipos backend y build frontend correctos; SQL/API dieron C-2.1 44/10=4.40 estrellas, C-2.2 9/11=81.82 %, C-2.3 1/4=25 %, C-6.1 1/3=33.33 %. Chat real del dashboard llamó consultar_indicadores y devolvió los mismos valores, identificando C-2.3 como Requiere atención y el periodo como provisional. Los valores cambian con los registros y el tiempo. Imagen reconstruida; sin suites históricas ni pruebas destructivas. Siguiente paso: recargar dashboard y consultar al agente por estos indicadores.

## M13 — exploración de registros de negocio por el agente

Nueva herramienta consultar_base: recursos PAGOS, SERVICIO, ACTIVIDADES, EVALUACIONES, INCIDENCIAS y VALORACIONES; filtros por estado/tipo/texto/rango de fechas, orden reciente/antiguo/importe y paginación hasta 50 filas. Las proyecciones/relaciones son vistas de negocio definidas en el servidor; los valores se parametrizan. No hay SQL libre, DDL, escrituras económicas, credenciales o configuración técnica como herramientas.

En portal/acompañamiento el estudiante se resuelve desde la sesión, rechazando un ID ajeno. Solo el dashboard del dueño puede elegir otro estudiante o consultar el conjunto. Se comprueba dueño activo, existencia del alumno y acceso Plus de apoderado. El alcance de sus consultas es el estudiante vinculado, no pagos ni datos de otros alumnos. El catálogo de información es independiente del canal; la diferencia estudio/seguimiento no impide responder una consulta informativa de cuenta.

Pagos devuelve cobros, estados, importes brutos, fechas, plan y operaciones correctivas separadas. Último cobro: COBRO + CONFIRMADO + reciente + límite 1, ordenado por confirmación/operación; no se confunde importe exigible con cobrado ni se atribuye un pagador sin evidencia. La falta de cobros exige revisar beca/servicio antes de inferir deuda. Se ampliaron únicamente permisos SELECT de columnas de Pago en mvp-permissions.sql; el esquema y la población no cambian.

Las solicitudes de descuentos/devoluciones, contradicciones o falta de evidencia se derivan con CONSULTAR_DUENO, describiendo la consulta y hechos verificados. La respuesta del dashboard sigue pasando por el agente del destinatario en el flujo RESPONDER_CONSULTA existente; nunca aplica automáticamente cambios económicos.

Verificación: tipos backend correctos; lectura SQL de los seis recursos; un ID de otro alumno fue rechazado. El primer intento detectó permisos insuficientes de Pago y se corrigió la concesión de lectura. Después, chat real de Ana respondió último cobro S/ 79.90, Meta UNT, confirmado el 23/10/2026, sin atribuir falsamente el pagador. Build de la imagen realizado. No se reejecutaron suites SQL ni de navegador. Siguiente paso: el usuario prueba consultas naturales en su sesión; no ampliar alcance automáticamente.

## M12 — perspectiva de la bandeja del participante

La cabecera y la conversación seleccionada de Mensajería muestran Seguimiento LaPreDigital, que es la contraparte del estudiante/apoderado. La identidad propia se mantiene en «Tu cuenta», con nombre y rol/vínculo. Corrección visual sin cambios de sesiones, mensajes, permisos ni lógica del agente. Verificación: compilación web; sin pruebas adicionales.

## M11 — identidad de destinatarios y dos asistentes del portal

Academia y Mensajería tienen diseños diferenciados. Mensajería presenta cabecera con el nombre real del contacto autenticado, teléfono, rol ESTUDIANTE/APODERADO y, para apoderados, estudiante vinculado; el nombre del estudiante nunca sustituye al del apoderado. Las burbujas identifican al interlocutor y al asistente correspondiente. La ficha expone solo el contacto de esa identidad, resuelta en servidor.

Academia usa Asistente de estudio para temario, conceptos/ejercicios, progreso y uso de la plataforma. Mensajería usa Asistente de seguimiento para recordatorios, actividades pendientes, satisfacción/incidencias y acompañamiento CUSTOMERS. Son sesiones e historiales distintos por canal, con instrucciones específicas. Los envíos proactivos de la herramienta se restringen a MENSAJERIA; Academia atiende las consultas dentro del portal. Cambiar de vista limpia el borrador y se bloquea durante una respuesta.

Verificación: tipos backend y build frontend correctos; ficha API contrastada para estudiante y apoderado Plus con sus respectivos nombres. Sin suites adicionales ni cambios de SQL. Imagen reconstruida y entrega local actualizada. Siguiente paso: recargar 5180 y revisar ambas identidades/vistas.

## M10 — diseño y navegación unificados

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
M03 (331d26c): imagen compilada, comprobaciones y runbook.

No continuar automáticamente con extensiones: usar la demo y atender los cambios que pida el usuario. Leer README para arrancar; .env de este equipo ya existe y no debe sobrescribirse.

## Servicios y acceso

- En la demo de CachyOS, SQL Server 2022 en sql-server-local, base LaPreDigital_Customers, America/Lima. En Windows, SQL Server nativo (ver verificación adicional).
- En CachyOS, Eve abierto por el usuario mediante scripts/chat-local, con llavero desbloqueado y modelo ready.
- Panel de desarrollo en http://localhost:5173, proxy al proceso de Eve; en CachyOS scripts/start detecta ese proceso y excluye el backend de pruebas.
- scripts/open-panel abre el acceso del dueño sin imprimir el token. Token en .env privado fuera de Git, solo sessionStorage en navegador.
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

## Verificación adicional en Windows (12/11/2026)

- En este equipo SQL Server es el servicio nativo `MSSQLSERVER`, no `sql-server-local`. Se conservaron la base activa y `.env`; se añadieron solo la identidad del dueño existente (ID 1) y un token aleatorio local. Se aplicaron `scripts/grant-sql-read.ps1` e `infra/sql/mvp-permissions.sql` a la cuenta de app, sin recrear tablas ni poblar datos.
- Dependencias instaladas en el volumen Docker; `npm run typecheck`, 14 pruebas `node:test` y `npm run build:web` pasaron. Servidor y Vite levantados en 3000/5173; salud 200, API anónima 401, API del dueño 200, listado de 14 alumnos y ficha de Carla consultados.
- Playwright Chromium real sobre la UI y la API activas: acceso con fragmento, Carla, Gabriela e Ines, cuatro métricas y diseño de 1440/390 px sin desbordamiento ni errores JS. Capturas en `tmp/ui-desktop.png` y `tmp/ui-mobile.png`. Esta pasada fue de solo lectura: no se ensayaron propuestas/escrituras sobre la base activa.
- Se corrigió en el panel la interpretación de `+` en tokens locales: `URLSearchParams` lo convertía en espacio cuando `open-panel` pasaba el token por fragmento. En el bind mount de Windows Vite siguió sirviendo la copia antigua hasta reiniciar `web`. El panel se abrió en el navegador predeterminado.
- Al levantar Eve interactivamente en Windows con el llavero desbloqueado, tardó varios minutos en pasar de `Starting agent` a `ready`; durante el arranque Vite mostró un fallo temporal de conexión. Una vez saludable, `/api/status` devolvió `modelo: ready` tanto directo en 3000 como a través del panel en 5173, y el listado respondió con 14 alumnos. No se ejecutó todavía un turno de chat real en Windows; los chats verificados en CachyOS constan arriba. Siguiente paso concreto: recargar el panel y comprobar un turno de chat con el usuario, conservando abierta la terminal interactiva.
- Sincronización posterior de M04–M06 en Windows: `main` avanzó por fast-forward hasta `af5892c`, las tres ediciones locales se reaplicaron sin conflictos y quedó una copia en Git stash. La dependencia nueva se instaló incrementalmente en el volumen Docker; build web, tipos backend y 14 pruebas unitarias pasaron. Vite ya sirve la UI nueva, pero Eve interactivo siguió usando las rutas antiguas (`GET /api/estudiantes/3/chat` respondió 404); tocar `agent.ts` no provocó recarga en este bind mount. No se cerró la terminal con llavero. Siguiente paso: cuando termine el turno activo, reiniciar Eve interactivamente, esperar `ready` y comprobar esa ruta y el chat desde el panel.
- Sincronización M07–M10 en Windows: `main` avanzó por fast-forward hasta `b9fb759`, se reaplicaron sin conflicto las tres ediciones locales y se conservó una copia en Git stash. Pasaron build web, tipos backend, 14 pruebas unitarias, check del workspace y validación Compose. Eve ya estaba detenido; se reinició solo Vite para leer el código nuevo. Consulta SQL de solo lectura confirmó que `ContenidoUNT`, `ProgresoTemaUNT`, `MensajeCanalLocal` y `ConsultaDueno` aún no existen en la base Windows. No se importó temario ni se ejecutaron 01/02 sobre la base activa. Siguiente paso concreto: acordar la aplicación del bloque M07 a la instancia nativa existente, sin reconstruir datos; luego arrancar Eve interactivamente y verificar dashboard/portal en Windows.
- Aplicación M07 autorizada después en la instancia nativa Windows (`LaPreDigital_Customers`, SQL Server 2019 Standard): copia `COPY_ONLY, CHECKSUM` creada y validada con `RESTORE VERIFYONLY` en el directorio de backups de SQL Server (`LaPreDigital_Customers_pre_M07_20261112_172907.bak`). Se ejecutó en una sola transacción el bloque nuevo generado desde 01/02 más los GRANT de `infra/sql/mvp-permissions.sql`, con `sqlcmd -b` y entrada UTF-8. Resultado: una edición, 18 cursos, 162 temas, 2268 avances CARGA_DEMO y dos autorizaciones PLATAFORMA/REPORTES para apoderados previamente autorizados. Estudiantes 14, suscripciones 14, periodos 15 y pagos 14 conservaron sus conteos. Documento y subtemas JSON válidos, sin progresos huérfanos; trigger habilitado, siete FK nuevas confiables; `lapredigital_app` lee/escribe solo lo concedido, sin UPDATE de Estudiante, y `db:check` pasó. No se invocó el modelo ni se probó navegador/portal tras la carga. Siguiente paso concreto: iniciar Eve interactivamente con llavero, levantar portal 5180 y comprobar dashboard/portal contra esta base Windows.
- Sincronización M11–M12 en Windows: `main` avanzó por fast-forward a `e0d275b`; las tres ediciones locales se reaplicaron sin conflictos y conservan respaldo en stash. Estos commits modifican la identidad y el diseño del portal y separan las instrucciones de Academia/Mensajería; no cambian SQL ni dependencias. Pasaron tipos backend, build web y check del workspace. No se ejecutaron pruebas de navegador ni de chat en Windows; Eve permanece detenido. Siguiente paso concreto: iniciar Eve con el llavero, levantar portal en 5180 y comprobar las dos vistas con identidades de estudiante y apoderado.
- Verificación de los cuatro scripts `database/` frente a la base nativa: Git no mostró cambios locales ni remotos pendientes en esos archivos. `01` coincide con los nombres de las 60 tablas, 25 triggers y 27 índices explícitos de la base activa; tipos/longitudes de historiales iguales. El documento del temario y los 162 temas/subtemas de `02` coinciden exactamente con SQL. Se ejecutaron copias de `01`, `02` y `03` con el nombre de base sustituido **solo** en `LaPreDigital_Customers_ScriptValidation`, creada para esta comprobación y eliminada al terminar: 24 OK y los cinco HALLAZGO conocidos, 18 cursos/162 temas y cero progresos huérfanos. Entre base activa y aislada: cero diferencias en columnas, CHECK, DEFAULT, FK, índices explícitos y conteos por tabla; el trigger M07 tiene el mismo cuerpo tras normalizar el espaciado de `CREATE OR ALTER`. `04` se ejecutó sin error en modo de solo lectura sobre la base activa. No se ejecutaron 01/02/03 completos sobre el OLTP activo; la identidad de sus datos y las fechas relativas envejecidas no se confunden con el esquema. Siguiente paso concreto: arrancar Eve y el portal en Windows para verificar la UI con la base ya contrastada.
- Sincronización M13–M14 en Windows: `main` avanzó por fast-forward hasta `d76b14b`; cuatro ediciones locales preservadas y respaldadas en stash. Los commits añaden consultas de negocio y KPI CUSTOMERS provisionales; no cambian esquema ni población ni dependencias npm. Pasaron tipos backend, build web y check del workspace; Vite se reinició para servir el dashboard nuevo, Eve sigue detenido. Consulta de solo lectura confirmó que `lapredigital_app` aún conserva solo las cuatro columnas iniciales de `Pago` y no tiene los nuevos SELECT de `PropuestaCambioPlan`: los GRANT ampliados de `infra/sql/mvp-permissions.sql` siguen pendientes en esta instancia. No se modificó SQL durante esta sincronización ni se verificaron los KPI/chat por API en Windows. Siguiente paso concreto: aplicar los GRANT acotados tras autorización, iniciar Eve con llavero y probar los KPI y consultas filtradas en el dashboard.
- Permisos M13–M14 aplicados después en Windows: únicamente `GRANT SELECT` a las once columnas autorizadas de `Pago` y tres de `PropuestaCambioPlan` según `infra/sql/mvp-permissions.sql`, dentro de una transacción; sin escritura de datos ni privilegios de UPDATE en Pago/Estudiante. La cuenta de aplicación ejecutó `indicadoresCustomers` (C-2.1 4.40, C-2.2 81.82 %, C-2.3 25 %, C-6.1 33.33 %) y `consultarBase` de PAGOS con un cobro confirmado. Se comprobó SELECT disponible en `PagoId` y `FechaRespuesta`, pero denegado en `CodigoOperacion` y `Necesidad`. No se probó el chat/modelo ni el navegador tras los GRANT; Eve permanece detenido. Siguiente paso concreto: iniciar Eve con llavero y probar KPI y consultas en el dashboard.
- Incidencia de arranque Windows posterior: `eve dev` interactivo aceptó la contraseña del llavero, pero agotó la espera fija de 120 segundos de Eve 1.0.0-rc.10 por el worker del build Nitro. No se borraron .eve, sesiones ni keyring. Como alternativa, `npm run build` del servidor terminó correctamente en Docker en 188 s y generó `.eve/packaged/.output`. `eve start` desde ese directorio, probado sin desbloquear llavero, respondió 200 en salud, `/api/status`, `/api/dashboard` por el proxy web (14 alumnos) y `/api/estudiantes/3/chat`. En esa prueba el estado del modelo fue `unavailable` porque el llavero no estaba abierto; **no está verificado el modelo en runtime compilado**. Se detuvo el contenedor de comprobación para liberar 3000. Siguiente paso concreto: usuario inicia el compilado con `scripts/eve-local` interactivamente, desbloquea llavero y confirma que el modelo figura `ready` antes de probar un turno del chat.

## Base y antecedentes

Cuatro SQL canónicos conservados. No se recreó ni pobló el OLTP activo; solo la base de prueba. La carga original contiene 14 estudiantes, 501 registros operativos y 39 históricos. Los datos envejecen desde GETDATE de la carga.

Los 29 casos anteriores (24 OK/5 HALLAZGO) no se reejecutaron sobre la base activa en esta entrega. Los cinco huecos del esquema siguen descritos en CONTEXTO.md; las operaciones de la app añaden validaciones, sin proteger cualquier SQL directo.

B01 (795aad2) verificó login y herramienta fija, cuenta SQL, dueño y build. T05 y T07/T08 se realizaron en Windows; M01–M03 en CachyOS, con la verificación de lectura en Windows añadida arriba.

## Límites del MVP

Un proceso local, chat progresivo con historial por estudiante, datos operativos actuales y aprobación humana. Sin cierres congelados/DataMarts/KPI oficiales completos, agenda automática, proveedores de comunicación, portal familiar, referidos, cambios de plan o agentes de otras fases.

No se prometen cuotas del modelo, despliegue con suscripción o persistencia del login real tras recreación. La fuente de verdad de negocio es informe 7.1 con decisiones posteriores del usuario. La demo completa con modelo y escrituras de navegador se ejecutó en CachyOS; en Windows se verificó la UI real en modo de solo lectura, sin login del modelo.
