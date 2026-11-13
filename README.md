# LaPreDigital · Agente Académico de CUSTOMERS

MVP académico local para preparación de ingreso a la UNT. **Panel, SQL Server y agente reales**, con aprobación humana y seguimiento simulado.

## Abrir la demo en este equipo

Si la terminal de Eve sigue abierta:

~~~bash
./scripts/start
./scripts/open-panel
~~~

Panel y dashboard: **http://localhost:5173**. Portal academia/mensajería, servicio Docker separado: **http://localhost:5180**. open-panel toma el acceso local de .env sin imprimirlo, lo pasa por fragmento y el panel lo elimina del URL. El token solo permanece en sessionStorage.

En Windows con SQL Server nativo, si `.env` ya contiene la cuenta SQL y el acceso del dueño, abre PowerShell en la raíz del proyecto y ejecuta:

~~~powershell
docker compose up -d --wait server web
$token = (Get-Content .env | Where-Object { $_ -match '^OWNER_ACCESS_TOKEN=' }) -replace '^OWNER_ACCESS_TOKEN=', ''
Start-Process "http://localhost:5173/#token=$token"
~~~

La primera vez en ese equipo, instalar dependencias con `docker compose run --rm --no-deps tools npm ci` y conceder los permisos necesarios con `scripts/grant-sql-read.ps1` e `infra/sql/mvp-permissions.sql` mediante una cuenta administradora. No ejecutar los SQL de creación o población sobre la base activa.

En esta instalación Windows el bloque M07 ya se aplicó a la instancia SQL nativa, sin reconstruir la base existente. `scripts/import-temario` usa el contenedor SQL de CachyOS y no es el comando de arranque en Windows. Tras iniciar Eve interactivamente con el llavero, el portal se abre con `docker compose up -d portal` en http://localhost:5180.

Si en Windows `eve dev` termina con «Timed out waiting for the Nitro dev build to emit a worker», el build compilado evita ese límite del modo desarrollo. El build ya se realizó en este equipo; repetirlo solo después de cambiar el backend. Desde CMD, después de confirmar que ningún otro Eve ocupa el puerto 3000:

~~~cmd
docker compose run --rm --no-deps --workdir /workspace/apps/server tools npm run build
docker compose run --rm --no-deps --use-aliases --service-ports -e SSH_TTY=1 --workdir /workspace/apps/server/.eve/packaged server sh /workspace/scripts/eve-local /workspace/node_modules/.bin/eve start --host 0.0.0.0 --port 3000
~~~

La primera línea solo es necesaria una vez por versión del código. Mantener abierta la terminal de la segunda línea. Se comprobaron salud, API y SQL en modo compilado **sin** llavero; la conexión real del modelo tras desbloquearlo en ese modo aún requiere verificación del usuario.

En CachyOS, si apagaste todo, primero en una terminal:

~~~bash
docker start sql-server-local
./scripts/chat-local
~~~

Desbloquea el llavero y completa /login → ChatGPT Subscription si Eve lo solicita. **Deja esa terminal abierta**. En otra terminal ejecuta start y open-panel. Si cambiaste el proceso de Eve, repite start para actualizar el proxy.

El arranque de desarrollo usa `--resume` para recuperar conversaciones conservadas en el volumen `eve_state`. Compose desactiva la recuperación paralela del SDK (`WORKFLOW_LOCAL_RECOVER_ACTIVE_RUNS=false`): Eve se encarga de reencolar. `scripts/eve-dev` aplica un ajuste acotado a Eve rc.10 para que las reentregas internas incluyan la credencial de confianza del proceso actual; no desactiva autenticación y exige revisar compatibilidad si cambia la versión. No borrar ese volumen para resolver un error de recuperación. Reanudar puede repetir un paso interrumpido; no garantiza recuperar snapshots dañados o ausentes.

El chat necesita el llavero abierto; sin él las consultas SQL y la bandeja siguen disponibles y el chat muestra un error explícito. No hay respuestas prefabricadas que sustituyan al modelo.

## Qué puedes demostrar

- Seleccionar estudiantes y consultar plan, vigencia, beca, reactivación, historial y prestaciones.
- Revisar cumplimiento de ruta, resultados comparables, uso, valoración e incidencias.
- Consultar KPI CUSTOMERS C-2.1, C-2.2, C-2.3 y C-6.1 en el dashboard y mediante el agente: mes en curso, semáforos, fórmulas y cifras de respaldo; no son cierres mensuales congelados.
- Explicar el riesgo con datos y referencias; sin datos suficientes queda pendiente.
- Conversar con el agente con Markdown y respuesta progresiva; recuperar su conversación al volver al estudiante o recargar, con herramientas y referencia de sesión.
- Registrar una propuesta, aprobar/rechazar y **simular** el seguimiento.
- Respetar el plan, los permisos de contacto y la petición de no contacto de Inés.

Guion sugerido: **Carla C003** (riesgo alto y -25 pp), **Gabriela C007** (pendiente, no aplicable), **Inés C009** (no contacto), **Fabio C006** (beca sin pago) y **Lucía C011** (reactivación). Las fechas de la demo envejecen.

Toda comunicación es simulada: no se llama a WhatsApp/correo ni se crean mensajes ENVIADO/ENTREGADO. Una simulación no acredita C-4. El modelo propone; solo el dueño aprueba y simula. Las rutas y los pagos no se modifican.

## Demostración con estudiantes y apoderados

1. Ejecutar `./scripts/start` y `./scripts/open-panel`; mantener Eve desbloqueado.
2. En el dashboard preguntar por el panorama general o pedir: «Envía un mensaje a Ana para preguntarle cómo va con Álgebra por MENSAJERIA». El agente consulta evidencias y autorizaciones antes de actuar.
3. Abrir **http://localhost:5180**. En «Control de participantes» introducir el acceso del dueño (OWNER_ACCESS_TOKEN de .env), elegir estudiante y rol y pulsar «Abrir su sesión». El participante recibe un token propio firmado. Ana sirve para estudiante; Elena C005 sirve para apoderado con Plus.
4. Alternar Academia/Mensajería. En Academia filtrar curso y cambiar un tema a En curso/Completado; el avance se refleja en la ficha y el dashboard. Los subtemas del JSON se muestran bajo cada tema. No se generan notas ni dominio académico por marcar completado.
5. En Mensajería responder al agente. Para demostrar escalamiento solicitar una condición económica especial. Aparecerá una consulta en el dashboard; responder desde su tarjeta o indicar al chat «Para la consulta #N, mi decisión es ...; comunícala al interesado». El agente lleva la decisión al mismo hilo.

El canal es local y bidireccional; su apariencia de mensajería no realiza envíos por proveedores externos. El envío y la recepción de bandeja tienen registros propios, sin reinterpretar simulaciones antiguas como mensajes entregados. La regla anterior de propuestas/aprobación se mantiene para esas intervenciones; los mensajes locales solicitados por el dueño usan las validaciones de su herramienta específica.

## Temario y base existente

El JSON original está en [docs/courses/temario_preuniversitario_UNT_2027.json](docs/courses/temario_preuniversitario_UNT_2027.json): 18 cursos, 162 temas y subtemas, con fuentes y alcance metodológico. No se presenta como malla certificada de CEPUNT. El documento completo se conserva en SQL y el catálogo se organiza por edición.

01/02 incluyen el nuevo esquema y población. Sobre una base ya existente, `./scripts/import-temario` aplica solo el bloque nuevo derivado de esos archivos, sin borrar estudiantes, rutas, pagos o historiales; no se ejecuta al arrancar. La carga inicial de avance de los 14 alumnos se identifica CARGA_DEMO; las acciones del portal usan PORTAL_LOCAL y conservan historial. No ejecutar 01/02 completos sobre la base activa.

## Primera instalación

Requisitos: Docker Engine/Compose, Git y shell POSIX. Node 24 está aislado en Docker.

~~~bash
./scripts/dev npm ci
# Solo si no existe .env y el SQL Docker existente aún no tiene usuario de app:
./scripts/provision-sql-app
# Permisos mínimos para los módulos MVP sobre la base existente:
./scripts/grant-mvp
./scripts/dev npm run build:web
./scripts/chat-local
# Otra terminal:
./scripts/start
./scripts/open-panel
~~~

Nunca ejecutar 01/02 para arrancar la aplicación. El aprovisionamiento no sobrescribe .env/logins. Windows conserva los scripts PowerShell; aplicar también infra/sql/mvp-permissions.sql con una cuenta administradora. El arranque y la UI de solo lectura se verificaron en Windows; el chat real y el flujo completo de escrituras se verificaron en CachyOS.

## Comprobaciones

~~~bash
./scripts/dev npm run check
./scripts/dev npm run typecheck
./scripts/dev npm test
./scripts/dev npm run build:web
./scripts/dev npm run build:server
./scripts/test-mvp
./scripts/test-browser
~~~

test-mvp crea/recrea **solo LaPreDigital_Customers_MvpTest** con copias en memoria de los SQL canónicos, y verifica transacciones, evidencias, permisos, duplicados y simulación. test-browser usa la UI real y dirige sus escrituras a esa base aislada. Sus capturas quedan en tmp/, fuera de Git. No ejecutan llamadas al modelo: esas se verificaron aparte con Carla, Gabriela e Inés.

Los 29 casos del SQL 03 y sus cinco HALLAZGO son históricos; el MVP no modifica ese esquema ni oculta sus limitaciones frente a SQL directo.

## Imagen compilada

~~~bash
docker compose -f compose.packaged.yaml up --build -d --wait
PANEL_URL=http://localhost:3010 ./scripts/open-panel
~~~

La imagen sirve frontend y API en **3010**, sin montar las fuentes del host. Se verificaron build, salud, autenticación y consulta SQL. El token y la contraseña se inyectan en ejecución, no dentro del bundle.

Para habilitar el modelo del proceso compilado con el llavero local, detener ese servicio y abrirlo interactivamente:

~~~bash
docker compose -f compose.packaged.yaml stop app
docker compose -f compose.packaged.yaml run --rm --service-ports app sh /workspace/scripts/eve-local npm run start:server
~~~

Introduce la contraseña del llavero y mantén esa terminal abierta. **Ese desbloqueo del modo compilado aún no se verificó**; la demo con modelo real sí se verificó mediante chat-local. La suscripción ChatGPT es una modalidad local, no una API key ni garantía de despliegue en VPS. Nube/proveedor de modelo se revisan después.

## Estructura y continuidad

| Ruta | Contenido |
| --- | --- |
| [apps/server](apps/server/README.md) | Eve/Nitro, reglas, SQL, herramientas y API |
| [apps/web](apps/web/README.md) | Panel React/Vite |
| [database](database/README.md) | Cuatro scripts canónicos conservados |
| [infra](infra/README.md) | Docker, permisos y persistencia |
| [docs/ESTADO.md](docs/ESTADO.md) | Qué se ejecutó y límites |
| [docs/ROADMAP.md](docs/ROADMAP.md) | M01–M03 y alcance del MVP |
| [docs/CONTEXTO.md](docs/CONTEXTO.md) | Reglas y acuerdos del negocio |
| [AGENTS.md](AGENTS.md) | Instrucciones para continuar |

SQL guarda fechas peruanas con GETDATE; la API las serializa con offset -05:00. No hay cierres mensuales congelados, DataMart, agenda, referidos, cambios de plan, portal familiar ni otros agentes del embudo en este MVP. MiniMax no se consumió.

## Administración de CUSTOMERS

El sidebar incorpora **Estudiantes**, **Apoderados**, **Cursos y temario**, **Recursos**, **Rutas de estudio**, **Consultas e incidencias** y **Planes y servicios**. Dashboard conserva su asistente global; Agente IA abre el acompañamiento individual existente.

Se pueden registrar/editar perfiles, vincular apoderados, gestionar materiales, publicar versiones de rutas, añadir actividades y atender/resolver/reabrir casos de servicio o acceso. Cursos/temario, planes, suscripciones, periodos y movimientos de pago son de consulta. No hay borrado de estudiantes ni edición de resultados académicos históricos. Las altas administrativas crean perfiles LEAD; habilitar CUSTOMER sigue dependiendo de una contratación/beca, fuera de estos formularios.

Administración usa **Prisma 7.10.1** con SQL Server. Las consultas complejas de KPI y herramientas actuales conservan SQL parametrizado. El esquema Prisma es un mapa parcial para consultar/operar; no ejecutar `prisma migrate` ni `db push`. La fuente de verdad sigue siendo `database/01_crear_customers.sql`, junto con su población 02. No se necesita reconstruir la base para estas vistas.

Después de instalar estas dependencias en otro equipo, conceder una vez los permisos administrativos con una cuenta SQL administradora:

~~~bash
./scripts/grant-admin
~~~

En Windows ejecutar `infra/sql/admin-permissions.sql` con la cuenta administradora de SQL Server. Arranque y build generan el cliente Prisma dentro de Docker. La comprobación focalizada `apps/server/scripts/check-admin.mjs` solo admite `LaPreDigital_Customers_MvpTest`; no ejecutarla contra la base académica. `scripts/admin-browser-smoke.mjs` verifica la navegación sin escribir datos ni llamar al modelo.


## Bandeja de mensajería

**Mensajería** en el sidebar permite leer los hilos del portal y responder directamente como equipo LaPreDigital. Los hilos se distinguen por estudiante, contacto y rol; un mismo apoderado conserva un hilo por estudiante. Incluye búsqueda, filtro de rol, mensajes anteriores y sincronización periódica. El historial académico ACADEMIA permanece separado.

Las respuestas manuales aparecen en la zona MENSAJERIA del portal, sin llamar al agente ni a proveedores externos. La recepción se confirma cuando el participante lee su bandeja. El asistente automático sigue activo; esta vista no representa una toma de control exclusiva ni cierra automáticamente consultas pendientes del Dashboard. Para delegar respuestas se conservan el chat global del Dashboard y el acompañamiento individual de Agente IA.


## Herramientas y consultas desde el chat

El catálogo se adapta al interlocutor desde el primer mensaje. Estudiante y apoderado pueden pedir «pásame mi rendimiento»: el agente consulta resultados, mejora comparable, cumplimiento de la ruta y actividad sin exponer riesgo o notas internas. Academia y Mensajería conservan identidades e historiales separados. Los resultados faltantes se distinguen de un problema de acceso; actividades y periodos futuros pueden consultarse.

El dueño dispone en Dashboard de consultas SQL de negocio en vivo: tablas, relaciones verificadas, filtros, agrupaciones, conteos, sumas e historiales. Por ejemplo: «Agrupa mis estudiantes por etapa», «Muéstrame los periodos que vencen esta semana» o «Consulta los mensajes recientes de Carla». El agente descubre campos con `consultar_datos_negocio` y no recibe SQL libre. Los KPI publicados y el diagnóstico de riesgo conservan sus herramientas especializadas.

Esta lectura usa la cuenta independiente `lapredigital_reader`, con SELECT y escrituras denegadas. En SQL Server Docker local se habilita una sola vez con:

~~~bash
./scripts/provision-sql-reader
~~~

La instalación de este equipo ya está preparada. El script no crea/reconstruye tablas ni carga datos; conserva la contraseña y solo guarda las credenciales nuevas en .env. El proceso de desarrollo puede leer esas dos variables adicionales sin reiniciar el llavero. El runtime compilado las recibe por Compose. En Windows, crear ese login con contraseña propia y usuario en la base, conceder SELECT sobre `SCHEMA::dbo` y denegar INSERT/UPDATE/DELETE/EXECUTE/ALTER sobre el esquema; configurar `SQLSERVER_READONLY_USER` y `SQLSERVER_READONLY_PASSWORD` en .env. No usar la cuenta de escritura como reemplazo si falta la lectora.

El agente responde de forma directa y cercana, sin aclaraciones automáticas de recepción o simulación en cada mensaje. Conserva el estado real de cada acción cuando se pregunta por él. El historial del chat del dueño vive en Eve; las tablas SQL de conversaciones corresponden a los registros del negocio y al canal local.

Guía técnica y matriz por contexto: [herramientas del agente](docs/HERRAMIENTAS.md). La comprobación dirigida `apps/server/scripts/check-herramientas.mjs` solo acepta la base MvpTest existente; no la reconstruye ni llama al modelo.


## Reglas del negocio

La nueva opción del sidebar permite ajustar seis parámetros de riesgo de abandono. Basta editar valores y pulsar **Guardar cambios**. Incluye historial automático por fecha/responsable; no solicita motivo ni selección de política.

Los nuevos diagnósticos usan los valores guardados. Las evaluaciones anteriores conservan los suyos, y las propuestas basadas en reglas anteriores requieren reevaluación. Las reglas de pagos, acceso, autorizaciones y KPI no se modifican desde este formulario. El agente puede consultar la configuración vigente o histórica, pero solo el dueño la cambia desde la aplicación.


En una base nueva, ejecutar 01 y 02 actualizados como siempre. Para incorporar esta extensión a una instalación existente sin borrar datos, ejecutar una vez `./scripts/instalar-reglas` (SQL Server Docker local). El instalador lee el DDL y la semilla de esos mismos scripts; no es una segunda fuente del esquema. La instalación actual ya lo tiene aplicado. Las pruebas de publicación solo escriben en LaPreDigital_Customers_MvpTest.


## Consultas e incidencias

Pulsa **Ver caso** para consultar historial, reporte de origen y ayuda del agente. El análisis explica el problema y propone pasos; no ejecuta reparaciones ni resuelve el caso. El dueño registra atención, solución o reapertura. En casos reportados desde mensajería puede comunicar después la solución al estudiante/apoderado.

Los problemas claros reportados en MENSAJERIA pueden registrarse automáticamente como incidencias. El agente deriva al chat global del Dashboard cuando necesita una decisión; responder allí permite que comunique la decisión y registre el caso si corresponde. Los asuntos económicos se derivan al dueño/PAYERS. El canal académico se mantiene separado.

La instalación actual ya incorpora AtencionMensaje. En otro equipo con base existente ejecutar `./scripts/instalar-atencion`; toma el DDL de 01 y conserva datos. Los casos antiguos sin origen mantienen sus eventos; no se inventan vínculos de mensajería. `apps/server/scripts/check-atencion.mjs` solo escribe en MvpTest.

## Población ampliada

La base incluye **30 estudiantes** y escenarios desde meses anteriores. La guía [Escenarios ampliados](docs/database/ESCENARIOS_AMPLIADOS.md) permite elegir casos para la demostración. C015–C030 ya están cargados en este equipo; recarga el panel para verlos. En otra instalación con C001–C014, `./scripts/poblar-ampliacion` añade únicamente el bloque final de 02 sin reconstruir la base.
