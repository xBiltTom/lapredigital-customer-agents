# Roadmap de LaPreDigital · CUSTOMERS

Actualizado: 12 de noviembre de 2026. Este archivo es el plan canónico de tareas; cada tarea equivale a un commit coherente y comprobable.

## Para retomar en otra sesión

1. Leer [AGENTS.md](../AGENTS.md), [contexto y acuerdos](CONTEXTO.md), [estado de continuidad](ESTADO.md) y [arquitectura](ARQUITECTURA.md).
2. Revisar `git status`, `git log -5 --oneline` y `git remote -v`. No sobrescribir cambios del usuario.
3. Continuar con **T07**, primer pendiente. T05 probó el login local de ChatGPT y una llamada real a la herramienta fija; T06 valida la configuración. La conexión SQL y el usuario de aplicación siguen pendientes.
4. Leer los scripts de [database/](../database/README.md) y el [informe 7.1](reference/documento_InteligenciaNegocios.pdf) antes de convertir consultas en herramientas. La base está congelada por decisión del usuario.
5. El login de ChatGPT está verificado solo en la TUI local; no asumir que funciona en despliegue o desde Windows por el puerto publicado. No asumir créditos API de MiniMax ni permisos SQL.

## Objetivo y decisiones aceptadas

LaPreDigital prepara postulantes a la UNT, inicialmente de Trujillo/La Libertad. Se empieza con un Agente Académico de CUSTOMERS y un panel local para el dueño. El primer resultado útil es seleccionar a Carla, consultar datos reales de la demo, explicar su riesgo con evidencias y recomendar una acción. Luego se añade propuesta, aprobación y simulación de comunicación.

Stack: TypeScript, Node 24, backend Eve/Nitro, React/Vite, SQL Server 2022 en Docker, `mssql`, Zod y Vitest. Se usan npm workspaces y un lockfile raíz. La integración local `chatgpt()` de Eve mediante `/login` pasó una prueba real de modelo y herramienta fija en T05. MiniMax es alternativo solo si sus créditos son válidos para API. No se presupuestan claves nuevas, AI Gateway, nube ni mensajes reales para este MVP.

Las reglas de cálculo y permisos se aplican en código. La IA interpreta narrativas, selecciona herramientas y explica recomendaciones. El modelo no recibe SQL arbitrario, credenciales, herramientas de shell ni permiso para autoaprobar acciones. Las tablas actuales se conservan y las escrituras se encapsulan en transacciones con validación y deduplicación.

La aceptación de términos en el registro es la fuente prevista de autorizaciones del servicio: no pedir consentimiento adicional por cada mensaje. Conservar evidencia y respetar solicitudes posteriores de no contacto proactivo. Ese acuerdo es funcional; no se presenta como validación jurídica de un texto de términos todavía inexistente.

## Alcance de los hitos

- **Preparación (T00–T07):** repositorio, documentación, toolchain, servidor mínimo, login y SQL.
- **MVP 1 (T08–T12 y T16–T20):** consulta y diagnóstico explicado en navegador. También requiere las políticas de T13.
- **MVP 2 (T13–T15 y T21–T25):** propuestas, aprobación, simulación y pruebas de escritura.
- **Operación local (T26–T29):** agenda, métricas provisionales, trazas y ejecución reproducible.
- **Extensiones (T30–T32):** cambios de plan, referidos y vista del apoderado; se priorizan después del núcleo según tiempo.

Los IDs dan una secuencia sugerida, pero mandan las dependencias. T10 y otras tareas deterministas pueden avanzar mientras se resuelve el login de T05.

## Protocolo: una tarea, un commit

- Antes de empezar, verificar el estado de Git y escoger la primera tarea desbloqueada. No implementar varias tareas inconexas dentro de un commit.
- Si una tarea crece demasiado, dividirla aquí antes de implementarla, manteniendo IDs existentes y actualizando dependencias.
- Completar sus pruebas y criterios, actualizar su estado en este archivo y el punto de continuación en ESTADO.md, y hacer el commit de la tarea con esos documentos incluidos.
- No crear un commit separado solo para marcar como terminada la misma tarea. Consultar el hash del propio commit con Git; no intentar escribirlo dentro de sí mismo.
- Un fallo de auth o entorno se documenta como pendiente real, no como funcionalidad terminada. Indicar qué se verificó estáticamente y qué se ejecutó.
- No reformatear SQL ni cambiar consultas del usuario como parte incidental de una tarea del agente.
- Publicar con push normal cuando esté dentro del trabajo autorizado; no forzar ni reescribir la historia compartida.

## Tablero

| ID | Estado | Tarea | Dependencias |
| --- | --- | --- | --- |
| T00 | Hecha | Preservar la base y las consultas existentes | Ninguna |
| T01 | Hecha | Organizar y configurar el workspace | T00 |
| T02 | Hecha | Documentar roadmap y continuidad | T01 |
| T03 | Hecha | Preparar Node 24 y el gestor de paquetes | T02 |
| T04 | Hecha | Crear el backend mínimo de Eve | T03 |
| T05 | Hecha | Probar ChatGPT local con una herramienta inocua | T04 |
| T06 | Hecha | Validar la configuración de la aplicación | T04 |
| T07 | Pendiente | Conectar a SQL Server con un usuario de aplicación | T06 |
| T08 | Pendiente | Consultar perfil, servicio y prestaciones | T07 |
| T09 | Pendiente | Consultar progreso académico y revisiones | T08 |
| T10 | Pendiente | Implementar las reglas deterministas de riesgo | T06, T08 |
| T11 | Pendiente | Interpretar mensajes y valoraciones con evidencia | T05, T10 |
| T12 | Pendiente | Integrar herramientas de consulta y explicación | T09, T10, T11 |
| T13 | Pendiente | Aplicar política de contacto y prestaciones | T08, T10 |
| T14 | Pendiente | Registrar evaluaciones y señales atómicamente | T10, T11, T13 |
| T15 | Pendiente | Registrar propuestas sin duplicar acciones | T13, T14 |
| T16 | Pendiente | Exponer la API local con contexto de usuario | T08, T09, T10, T13 |
| T17 | Pendiente | Crear la interfaz React/Vite | T03, T16 |
| T18 | Pendiente | Mostrar listado y ficha del estudiante | T17, T08 |
| T19 | Pendiente | Mostrar progreso, incidencias y riesgo | T18, T09, T10 |
| T20 | Pendiente | Conectar el chat real de Eve al panel | T12, T17, T19 |
| T21 | Pendiente | Aprobar o rechazar una intervención desde el panel | T15, T20 |
| T22 | Pendiente | Simular mensajes y registrar seguimiento | T21 |
| T23 | Pendiente | Gestionar revisión de ruta y derivaciones humanas | T15, T21 |
| T24 | Pendiente | Probar herramientas de escritura contra SQL Server | T14, T15, T22, T23 |
| T25 | Pendiente | Preparar regresión de la demo en navegador | T20, T22, T23, T24 |
| T26 | Pendiente | Programar la revisión local de customers | T24 |
| T27 | Pendiente | Exponer indicadores operativos del mes | T19, T22, T24 |
| T28 | Pendiente | Registrar trazas y consumo de la ejecución | T12, T24 |
| T29 | Pendiente | Empaquetar y documentar el inicio local | T25, T28 |
| T30 | Pendiente | Preparar propuestas de cambio de plan | T23, T24 |
| T31 | Pendiente | Preparar invitaciones a referidos | T13, T22, T24 |
| T32 | Pendiente | Mostrar reportes del apoderado por estudiante | T18, T19, T24 |

## Tareas y criterios de cierre

### T00 · Preservar la base y las consultas existentes

- [x] Tarea completada.
- **Depende de:** ninguna.
- **Commit:** `chore(T00): versionar base academica y consultas existentes`.
- **Entregable:** Importar los seis archivos originales sin alterarlos; inicializar main y origin.
- **Cierre verificable:** Archivos presentes en el primer commit; repositorio remoto comprobado vacío por git ls-remote.
- **Contexto o límite:** Concluida en 513d0c9.

### T01 · Organizar y configurar el workspace

- [x] Tarea completada.
- **Depende de:** T00.
- **Commit:** `chore(T01): organizar workspace y configurar entorno local`.
- **Entregable:** Mover SQL a database/ y documentación a docs/; preparar npm workspaces, Node 24, exclusiones de secretos, editor y comprobación local.
- **Cierre verificable:** Comparar los seis archivos con sus blobs de T00; npm run check y git diff --check.
- **Contexto o límite:** Concluida en 9059457; bytes de los originales preservados.

### T02 · Documentar roadmap y continuidad

- [x] Tarea completada.
- **Depende de:** T01.
- **Commit:** `docs(T02): definir roadmap y contexto de continuidad`.
- **Entregable:** Crear este plan, contexto, arquitectura, estado y AGENTS.md; enlazarlos desde README; publicar la inicialización en origin/main.
- **Cierre verificable:** Enlaces locales válidos; tareas con dependencias y criterios; sin secretos; árbol limpio tras commit; verificar remoto al publicar.
- **Contexto o límite:** La publicación se verifica con Git; el hash de este mismo commit se consulta en git log.

### T03 · Preparar Node 24 y el gestor de paquetes

- [x] Tarea completada.
- **Depende de:** T02.
- **Commit:** `chore(T03): aislar toolchain node 24 en docker`.
- **Entregable:** Imagen oficial Node fijada por digest, Compose con usuario sin privilegios y UID/GID del host, volúmenes de dependencias/caché, wrapper scripts/dev, .dockerignore e instrucciones de uso. El usuario pidió Docker para aislar Node y preparar portabilidad a VPS.
- **Cierre verificable:** Node 24.22.3 y npm 11.19.1 en contenedor; usuario sin privilegios; TZ America/Lima; escritura con UID/GID del host; npm run check dentro del contenedor; SQL y scripts sin cambios.
- **Contexto o límite:** Node global 26 permanece intacto. Es el entorno de desarrollo, no una imagen de producción final; esta se completa en T29.

### T04 · Crear el backend mínimo de Eve

- [x] Tarea completada.
- **Depende de:** T03.
- **Commit:** `feat(T04): iniciar servidor local de eve`.
- **Entregable:** apps/server con Eve 1.0.0-rc.10, AI SDK 7.0.137 y Zod 4.6.7; docs instaladas revisadas y lockfile raíz. Compose inicia el backend en 127.0.0.1:3000, con salud y volumen de estado compartido con CLI. Sin Git anidado ni SQL.
- **Cierre verificable:** npm ci, typecheck y build pasan dentro de Docker; salud 200 antes y después de recrear el contenedor; persistencia de marcador .eve; sesión sin autorización devuelve 401; eve info sin errores y sin herramientas.
- **Contexto o límite:** Eve es una versión candidata. Sin login ni llamada real al modelo, agente de negocio o permisos de escritura. auth: [] mantiene sesiones cerradas hasta T05; el aviso de sandbox no impide compilar y no se montó Docker del host. Imagen final de VPS en T29.

### T05 · Probar ChatGPT local con una herramienta inocua

- [x] Tarea completada.
- **Depende de:** T04.
- **Commit:** `feat(T05): verificar autenticacion local del agente`.
- **Entregable:** Configurar chatgpt() y /login según la versión instalada; el usuario realiza la autenticación. Probar una herramienta que devuelve datos fijos no sensibles y registrar resultado, modelo disponible y límites observados.
- **Cierre verificable:** Una respuesta real y una llamada real a la herramienta se completan; un fallo de auth se muestra sin exponer tokens.
- **Contexto o límite:** El login local con código de dispositivo funcionó desde la TUI en Docker; traza con `gpt-6-luna-fast`, dos pasos y `execute_tool comprobar_conexion`. No se comprobó persistencia del login tras reinicio, acceso al chat desde Windows, ni despliegue. Credenciales en llavero Linux cifrado fuera de Git; MiniMax no se consumió.

### T06 · Validar la configuración de la aplicación

- [x] Tarea completada.
- **Depende de:** T04.
- **Commit:** `feat(T06): validar configuracion de entorno`.
- **Entregable:** Implementar configuración Zod y .env.example coherente, puertos locales, zona horaria y proveedor; separar opciones públicas de secretos del servidor.
- **Cierre verificable:** Una variable requerida ausente produce un error claro; ningún secreto llega al frontend o al log.
- **Contexto o límite:** Configuración mínima de TZ y proveedor local; Compose fija el puerto 127.0.0.1:3000. Sin frontend ni conexión SQL, no hay secretos que transmitir. El login se verificó después en T05; no se conecta ni reconstruye la base al importar el módulo.

### T07 · Conectar a SQL Server con un usuario de aplicación

- [ ] Tarea completada.
- **Depende de:** T06.
- **Commit:** `feat(T07): conectar sql server con pool compartido`.
- **Entregable:** Comprobar el puerto del contenedor existente; configurar identidad de aplicación y permisos mínimos para la fase de lectura; implementar mssql con un pool reutilizable y cierre ordenado. Documentar los cambios operativos de usuarios/permisos.
- **Cierre verificable:** Consulta parametrizada SELECT de prueba; fallo de conexión manejado; GETDATE() mantiene hora de Perú; no cambios de tablas o datos.
- **Contexto o límite:** No utilizar sa desde las herramientas del modelo. La creación de usuarios/permisos es configuración, no un rediseño del esquema.

### T08 · Consultar perfil, servicio y prestaciones

- [ ] Tarea completada.
- **Depende de:** T07.
- **Commit:** `feat(T08): consultar perfil y servicio del customer`.
- **Entregable:** Implementar repositorios parametrizados para estudiante, contactos, apoderado, periodos y prestaciones; paginar listados y distinguir servicio actual de historial.
- **Cierre verificable:** C006 beca sin pago; C011 dos episodios; C013 LEAD; apoderado compartido sin duplicar estudiantes.
- **Contexto o límite:** La identidad activa proviene del contexto validado del backend; una instrucción del chat no concede acceso a otro estudiante.

### T09 · Consultar progreso académico y revisiones

- [ ] Tarea completada.
- **Depende de:** T08.
- **Commit:** `feat(T09): calcular progreso academico comparable`.
- **Entregable:** Implementar cumplimiento por ruta y mejora por grupo comparable; exponer actividades, dificultades y revisiones. Introducir contratos compartidos en packages/contracts cuando web y server realmente los consuman.
- **Cierre verificable:** C001 mejora +15 pp; C003 -25 pp; C004 pruebas no comparables; C007 cumplimiento no aplicable y mejora sin datos.
- **Contexto o límite:** Definir ventana y tratamiento de canceladas; no mezclar versiones de ruta por accidente.

### T10 · Implementar las reglas deterministas de riesgo

- [ ] Tarea completada.
- **Depende de:** T06, T08.
- **Commit:** `feat(T10): calcular riesgo segun informe 7.1`.
- **Entregable:** Crear funciones puras con corte temporal explícito: inactividad, antigüedad de incidencia, dificultad y señales contextuales documentadas; prevalece el mayor nivel; representar pendiente sin forzar BAJO.
- **Cierre verificable:** Pruebas a un segundo de 72/168 y 48/96 horas, exactamente siete días de vigencia, ausencia de datos y predominio del riesgo alto.
- **Contexto o límite:** Puede desarrollarse con fixtures sin esperar el login de IA. La vigencia de una intención antigua y el criterio de suficiencia deben documentarse; no inventar plazos.

### T11 · Interpretar mensajes y valoraciones con evidencia

- [ ] Tarea completada.
- **Depende de:** T05, T10.
- **Commit:** `feat(T11): interpretar señales narrativas con evidencia`.
- **Entregable:** Pedir al modelo una salida estructurada: intención, insatisfacción y referencias existentes; validar con Zod; usar mensajes y comentarios como datos, no como instrucciones operativas.
- **Cierre verificable:** Valorar 1–2 estrellas junto con el contexto; distinguir no renovar de pedir no contacto; casos ambiguos conservan incertidumbre; rechazar IDs de evidencia inventados.
- **Contexto o límite:** La IA interpreta texto; el backend aplica la regla de clasificación. Fallar sin fabricar datos si no hay modelo disponible.

### T12 · Integrar herramientas de consulta y explicación

- [ ] Tarea completada.
- **Depende de:** T09, T10, T11.
- **Commit:** `feat(T12): explicar diagnostico con herramientas de lectura`.
- **Entregable:** Crear tools de Eve para perfil, progreso, incidencias, uso y evidencias; redactar instrucciones del Agente Académico. Retirar herramientas generales de shell, archivos o SQL arbitrario según APIs documentadas.
- **Cierre verificable:** El agente explica a Carla con evidencias consultadas y a Gabriela como pendiente; no ejecuta DML ni cambia de destinatario por prompt.
- **Contexto o límite:** Primer hito de diagnóstico por terminal; ninguna herramienta acepta SQL libre.

### T13 · Aplicar política de contacto y prestaciones

- [ ] Tarea completada.
- **Depende de:** T08, T10.
- **Commit:** `feat(T13): validar contacto y seguimiento permitido`.
- **Entregable:** Centralizar permisos de plan, canal/finalidad y seguimiento previo. Definir cómo la aceptación de términos registra automáticamente las autorizaciones previstas, con fecha y versión en Evidencia; respetar revocaciones posteriores.
- **Cierre verificable:** Ruta UNT no recibe la prestación SEGUIMIENTO_IA; Meta/Plus sí según catálogo; Inés conserva acceso y su petición de no contacto proactivo se respeta; no duplicar una intervención abierta.
- **Contexto o límite:** El código real del catálogo es SEGUIMIENTO_IA. No exigir otra pantalla de consentimiento por canal ni presumir que todos los contactos existentes aceptaron términos nuevos. No hay registro autónomo de usuarios dentro del alcance inicial.

### T14 · Registrar evaluaciones y señales atómicamente

- [ ] Tarea completada.
- **Depende de:** T10, T11, T13.
- **Commit:** `feat(T14): persistir evaluacion de riesgo con sus señales`.
- **Entregable:** Implementar una operación transaccional que valide pertenencia, fechas, nivel y evidencia actual; agregar evaluaciones completas sin sobrescribir evaluaciones clasificadas anteriores.
- **Cierre verificable:** Si falla una señal se revierte todo; nivel coincide con el mayor sustentado; una evidencia ajena o alterada impide finalizar la operación.
- **Contexto o límite:** Usar las tablas actuales. Conservar contexto de ejecución en almacenamiento local de la app si el OLTP no permite una instantánea; no prometer inmutabilidad ante SQL directo.

### T15 · Registrar propuestas sin duplicar acciones

- [ ] Tarea completada.
- **Depende de:** T13, T14.
- **Commit:** `feat(T15): proponer intervenciones con deduplicacion`.
- **Entregable:** Crear Intervencion en estado PROPUESTA y su EventoIntervencion dentro de transacción; verificar plan, evaluación, intervenciones previas y aprobación necesaria. Diseñar una clave estable de operación y recuperación para el único proceso local.
- **Cierre verificable:** Dos solicitudes/reintentos para la misma operación no crean dos propuestas; rollback consistente; no cambiar etapas, pagos ni rutas.
- **Contexto o límite:** No basar deduplicación solo en texto del prompt o en el ID efímero de una llamada. Explicitar los límites si en el futuro se ejecutan varias réplicas.

### T16 · Exponer la API local con contexto de usuario

- [ ] Tarea completada.
- **Depende de:** T08, T09, T10, T13.
- **Commit:** `feat(T16): exponer api local del panel`.
- **Entregable:** Añadir endpoints Nitro y contratos para listar, consultar y analizar; validar IDs, errores y sesión local del dueño. La vista simulada de estudiante debe estar identificada como demo.
- **Cierre verificable:** Pruebas HTTP de datos válidos, inexistentes, entradas inválidas y acceso fuera del contexto; secretos ausentes en respuestas.
- **Contexto o límite:** Reutilizar el servidor de Eve; no añadir NestJS o Next.js. No presentar la selección de un estudiante como autenticación de producción.

### T17 · Crear la interfaz React/Vite

- [ ] Tarea completada.
- **Depende de:** T03, T16.
- **Commit:** `feat(T17): iniciar panel react vite`.
- **Entregable:** Crear apps/web con TypeScript y React/Vite; configurar proxy local a /api y /eve según docs; navegación, estilos y estados de conexión.
- **Cierre verificable:** Interfaz inicia junto al backend, muestra errores de conexión y compila; lockfile único en raíz.
- **Contexto o límite:** Dependencias con función concreta; no instalar una segunda librería de agentes.

### T18 · Mostrar listado y ficha del estudiante

- [ ] Tarea completada.
- **Depende de:** T17, T08.
- **Commit:** `feat(T18): mostrar ficha del customer`.
- **Entregable:** Listado paginado y ficha con servicio, periodos, contacto, apoderado y prestaciones; identificar beca, reactivación y etapa.
- **Cierre verificable:** Mostrar C006, C011 y las dos estudiantes de María sin confundir personas; sin datos se muestra explícitamente.
- **Contexto o límite:** Conservar el ámbito de acceso en el backend.

### T19 · Mostrar progreso, incidencias y riesgo

- [ ] Tarea completada.
- **Depende de:** T18, T09, T10.
- **Commit:** `feat(T19): visualizar diagnostico y evidencias`.
- **Entregable:** Presentar cumplimiento, mejora, uso, valoración, incidencias, riesgo y vigencia con evidencias consultables. Mostrar fecha del corte y origen de datos.
- **Cierre verificable:** C007 nunca aparece bajo por ausencia de datos; C008 requiere reevaluación; notas en pp y pruebas comparables.
- **Contexto o límite:** Las métricas operativas son actuales; no llamarlas cierres mensuales congelados.

### T20 · Conectar el chat real de Eve al panel

- [ ] Tarea completada.
- **Depende de:** T12, T17, T19.
- **Commit:** `feat(T20): conectar chat del agente academico`.
- **Entregable:** Integrar el cliente React de Eve con sesiones locales y streaming; mostrar herramientas, errores y referencias; conservar el estudiante seleccionado en contexto validado.
- **Cierre verificable:** Conversación real de Carla en navegador usa perfil y evidencia; cambio de estudiante no arrastra el contexto de otro; reinicio conserva sesión según configuración.
- **Contexto o límite:** Hito MVP 1: diagnóstico explicado de principio a fin. No sustituir la llamada real por una respuesta fija sin etiquetarla.

### T21 · Aprobar o rechazar una intervención desde el panel

- [ ] Tarea completada.
- **Depende de:** T15, T20.
- **Commit:** `feat(T21): aprobar propuestas desde el panel`.
- **Entregable:** Añadir bandeja de propuestas y detalle de evidencia; aprobación/rechazo del dueño con identidad y fecha verificadas; revalidar condiciones al ejecutar tras aprobación.
- **Cierre verificable:** Doble clic no ejecuta dos veces; revocación o cambio de plan posterior bloquea la acción; el modelo no puede autoaprobar.
- **Contexto o límite:** No agregar un estado RECHAZADA inexistente a Intervencion: mapear a CANCELADA con resultado y evento explicativo.

### T22 · Simular mensajes y registrar seguimiento

- [ ] Tarea completada.
- **Depende de:** T21.
- **Commit:** `feat(T22): simular comunicacion de seguimiento`.
- **Entregable:** Crear bandeja simulada de borradores/respuestas y registrar las operaciones de negocio permitidas. Utilizar estados existentes, sin inventar BORRADOR en Mensaje. Identificar toda simulación.
- **Cierre verificable:** Ningún proveedor externo es llamado; un borrador/simulación no se marca ENVIADO/ENTREGADO ni incrementa C-4 de envíos reales; historial de intervención consistente.
- **Contexto o límite:** Hito MVP 2: diagnóstico → propuesta → aprobación → simulación visible. Los envíos reales requieren un adaptador posterior.

### T23 · Gestionar revisión de ruta y derivaciones humanas

- [ ] Tarea completada.
- **Depende de:** T15, T21.
- **Commit:** `feat(T23): registrar revisiones y derivaciones humanas`.
- **Entregable:** Registrar recomendaciones en RevisionRuta e intervenciones de derivación con la evidencia correspondiente; ofrecer al dueño su bandeja de revisión.
- **Cierre verificable:** Solo el dueño publica cambios de ruta mediante operación controlada; el agente propone; una consulta económica queda derivada sin procesar pagos.
- **Contexto o límite:** No dar por implementado un Agente de Cobranza: por ahora hay una derivación para atención humana.

### T24 · Probar herramientas de escritura contra SQL Server

- [ ] Tarea completada.
- **Depende de:** T14, T15, T22, T23.
- **Commit:** `test(T24): validar transacciones del agente en sql server`.
- **Entregable:** Agregar pruebas de integración sobre una base de prueba aislada, comprobando transacciones, permisos y reintentos; comparar los cinco huecos SQL con la protección aplicada por la app.
- **Cierre verificable:** 29 pruebas de referencia mantienen su interpretación; pruebas nuevas de app rechazan los cinco casos inconsistentes; ninguna ejecución borra la base principal.
- **Contexto o límite:** El 03 seguirá mostrando sus cinco HALLAZGO mientras no se modifique el esquema. No cambiarlo para fingir que se corrigieron a nivel de base.

### T25 · Preparar regresión de la demo en navegador

- [ ] Tarea completada.
- **Depende de:** T20, T22, T23, T24.
- **Commit:** `test(T25): verificar escenarios completos del panel`.
- **Entregable:** Automatizar los flujos esenciales con Playwright; aislar pruebas deterministas de las que consumen una sesión/modelo real.
- **Cierre verificable:** Carla, Gabriela, Hugo, Fabio, Inés y Lucía cubren los caminos esperados; aprobación, aislamiento por alumno y mensajes simulados funcionan.
- **Contexto o límite:** Las pruebas de modelo real son explícitas y presupuestadas; no ejecutarlas automáticamente en cada commit.

### T26 · Programar la revisión local de customers

- [ ] Tarea completada.
- **Depende de:** T24.
- **Commit:** `feat(T26): programar reevaluacion local controlada`.
- **Entregable:** Añadir ejecución manual por lote y agenda local con un único proceso; evaluar semanalmente y ante señales nuevas según política definida, reutilizando deduplicación y límites.
- **Cierre verificable:** Reiniciar no duplica trabajos/acciones; la selección respeta servicio vigente y necesidad de reevaluación; registrar corte y resultado por estudiante.
- **Contexto o límite:** El programa no trabaja cuando el equipo está apagado. No ejecutar un LLM para cálculos que puede resolver el motor de reglas.

### T27 · Exponer indicadores operativos del mes

- [ ] Tarea completada.
- **Depende de:** T19, T22, T24.
- **Commit:** `feat(T27): calcular indicadores provisionales de customers`.
- **Entregable:** Implementar cohortes y denominadores de C-1 a C-7 según datos disponibles; mostrar numerador, denominador, corte y no aplicable; separar pendientes y evaluaciones vencidas.
- **Cierre verificable:** No contar aceptado como aplicado; reactivación no cuenta como renovación continua; no duplicar customers por sus eventos; no incluir envíos simulados en C-4.
- **Contexto o límite:** Resolver con el usuario las ambigüedades de C-1.1 con varias revisiones y cobertura de pendientes en C-3.1 antes de rotularlos como KPI oficiales. Los cierres históricos permanecen fuera de alcance.

### T28 · Registrar trazas y consumo de la ejecución

- [ ] Tarea completada.
- **Depende de:** T12, T24.
- **Commit:** `feat(T28): registrar trazas y consumo del agente`.
- **Entregable:** Añadir identificador de ejecución, versión de reglas/instrucciones, referencias de evidencia, herramientas, tiempos, resultado y consumo disponible; redactar secretos y minimizar datos personales.
- **Cierre verificable:** Una ejecución puede explicarse a partir de su rastro; un error no deja un estado ficticio exitoso; se distinguen tokens medidos de estimaciones.
- **Contexto o límite:** Sesiones y trazas locales quedan fuera de Git y con persistencia; no duplicar automáticamente conversaciones completas en cada log.

### T29 · Empaquetar y documentar el inicio local

- [ ] Tarea completada.
- **Depende de:** T25, T28.
- **Commit:** `chore(T29): preparar inicio local reproducible`.
- **Entregable:** Consolidar scripts dev/build/test y runbook; documentar red/puertos/volúmenes de SQL existente, restauración de copias y persistencia de Eve. Añadir Compose solo si aporta al arranque sin reemplazar el contenedor actual.
- **Cierre verificable:** Una sesión nueva puede seguir el README y ejecutar la demo; los datos y sesiones sobreviven al reinicio previsto; ninguna tarea de arranque reconstruye el OLTP.
- **Contexto o límite:** Verificar America/Lima y distinguir prueba ejecutada de configuración propuesta. No desplegar servicios de pago.

### T30 · Preparar propuestas de cambio de plan

- [ ] Tarea completada.
- **Depende de:** T23, T24.
- **Commit:** `feat(T30): proponer cambios de plan compatibles`.
- **Entregable:** Extensión posterior al núcleo: sugerir modalidad según necesidad explícita y prestaciones; registrar propuesta/respuesta de manera controlada.
- **Cierre verificable:** Mateo aceptado sigue sin plan aplicado; no modificar precio ni compensar periodo pagado; aplicación solo en operación autorizada.
- **Contexto o límite:** No es requisito para cerrar el primer diagnóstico conversacional.

### T31 · Preparar invitaciones a referidos

- [ ] Tarea completada.
- **Depende de:** T13, T22, T24.
- **Commit:** `feat(T31): preparar invitaciones de referidos`.
- **Entregable:** Extensión posterior: identificar satisfacción contextual, proponer invitación y consultar referente/conversión respetando atribución única.
- **Cierre verificable:** No invitar por promedio sin contexto; no alterar referente fijado al primer pago; distinguir formulario válido de compra.
- **Contexto o límite:** Conservar simulación de mensajes mientras no exista canal real.

### T32 · Mostrar reportes del apoderado por estudiante

- [ ] Tarea completada.
- **Depende de:** T18, T19, T24.
- **Commit:** `feat(T32): mostrar reportes autorizados del apoderado`.
- **Entregable:** Extensión posterior: vista vinculada por estudiante con verificación de prestaciones de Meta UNT Plus y contexto de identidad en el backend.
- **Cierre verificable:** María puede tener dos alumnos, pero cada acceso depende del plan de ese alumno; Pedro no accede por el mero vínculo con Ana.
- **Contexto o límite:** La demo de roles no equivale a autenticación real de usuarios finales; documentar alcance y cuentas de prueba.

## Pendientes que no deben convertirse en supuestos

- No está confirmado si la suscripción es Plus/Pro ni qué modelos permite su integración local con Eve.
- Los 2.000 créditos de MiniMax no se han identificado como saldo API o créditos de su aplicación.
- No se ha fijado una política de frecuencia de contacto de CUSTOMERS; no trasladar la secuencia comercial de LEADS a esta fase.
- Hay cinco huecos conocidos de integridad descritos en [CONTEXTO.md](CONTEXTO.md). La app los cubre en sus operaciones; el esquema no queda mágicamente protegido frente a SQL directo.
- Todavía no existen cierres mensuales congelados ni DataMarts. Los reportes del MVP son provisionales.
- Las consultas personales añadidas por el usuario al 04 se conservan; el resultado histórico de sus 20 bloques no certifica automáticamente cualquier edición posterior.

## Fuentes técnicas que debe verificar quien implemente

- [Eve: inicio y Node requerido](https://eve.dev/docs/getting-started).
- [Eve: configuración del modelo y ChatGPT local](https://eve.dev/docs/agent-config).
- [Eve: herramientas y aprobaciones](https://eve.dev/docs/tools).
- [Eve: self-hosting y persistencia](https://eve.dev/docs/guides/deployment/self-hosting).
- [mssql para Node.js](https://github.com/tediousjs/node-mssql).

Las opciones de acceso al modelo son documentadas, no probadas en este proyecto. Al instalar Eve, sus docs en `node_modules/eve/docs/README.md` y las del AI SDK instalado prevalecen para escribir APIs concretas. No copiar ejemplos de versiones incompatibles ni elegir un modelo por un nombre antiguo del chat.
