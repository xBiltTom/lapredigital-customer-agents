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
