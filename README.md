# LaPreDigital · Agente Académico de CUSTOMERS

MVP académico local para preparación de ingreso a la UNT. **Panel, SQL Server y agente reales**, con aprobación humana y seguimiento simulado.

## Abrir la demo en este equipo

Si la terminal de Eve sigue abierta:

~~~bash
./scripts/start
./scripts/open-panel
~~~

Panel: **http://localhost:5173**. open-panel toma el acceso local de .env sin imprimirlo, lo pasa por fragmento y el panel lo elimina del URL. El token solo permanece en sessionStorage.

Si apagaste todo, primero en una terminal:

~~~bash
docker start sql-server-local
./scripts/chat-local
~~~

Desbloquea el llavero y completa /login → ChatGPT Subscription si Eve lo solicita. **Deja esa terminal abierta**. En otra terminal ejecuta start y open-panel. Si cambiaste el proceso de Eve, repite start para actualizar el proxy.

El chat necesita el llavero abierto; sin él las consultas SQL y la bandeja siguen disponibles y el chat muestra un error explícito. No hay respuestas prefabricadas que sustituyan al modelo.

## Qué puedes demostrar

- Seleccionar estudiantes y consultar plan, vigencia, beca, reactivación, historial y prestaciones.
- Revisar cumplimiento de ruta, resultados comparables, uso, valoración e incidencias.
- Explicar el riesgo con datos y referencias; sin datos suficientes queda pendiente.
- Conversar con el agente, ver qué herramientas usó y su referencia de sesión.
- Registrar una propuesta, aprobar/rechazar y **simular** el seguimiento.
- Respetar el plan, los permisos de contacto y la petición de no contacto de Inés.

Guion sugerido: **Carla C003** (riesgo alto y -25 pp), **Gabriela C007** (pendiente, no aplicable), **Inés C009** (no contacto), **Fabio C006** (beca sin pago) y **Lucía C011** (reactivación). Las fechas de la demo envejecen.

Toda comunicación es simulada: no se llama a WhatsApp/correo ni se crean mensajes ENVIADO/ENTREGADO. Una simulación no acredita C-4. El modelo propone; solo el dueño aprueba y simula. Las rutas y los pagos no se modifican.

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

Nunca ejecutar 01/02 para arrancar la aplicación. El aprovisionamiento no sobrescribe .env/logins. Windows conserva los scripts PowerShell; aplicar también infra/sql/mvp-permissions.sql con una cuenta administradora. El arranque completo se verificó en CachyOS; los scripts Windows se revisaron estáticamente.

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
