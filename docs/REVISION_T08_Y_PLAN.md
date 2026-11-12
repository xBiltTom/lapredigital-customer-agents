# R01 · Revisión de implementación y tareas

12 de noviembre de 2026. HEAD revisado: a9eb90e, también confirmado en origin/main. Alcance: revisión de T05–T08, arranque local y reorganización del plan. No se implementaron funciones nuevas ni se cambiaron tablas, permisos SQL o datos.

## Resultado de la revisión

La base del backend es pequeña y aprovechable: configuración Zod, pool perezoso, SQL parametrizado y dos operaciones de perfil/servicio. No hay un framework propio ni capas genéricas que justifiquen rehacerlo. Los repositorios todavía no son herramientas del modelo ni endpoints públicos.

T00–T08 son **nueve tareas completadas**, contando T00; no existe una implementación de **T09** en el repositorio revisado. README, ESTADO y el antiguo roadmap la indicaban como siguiente pendiente.

## Puntos a corregir antes de ampliar

1. **Acceso de apoderado sin prestación (prioridad alta antes de exponerlo).** En apps/server/lib/database/estudiantes.ts:102, accesoIdentidad acepta cualquier vínculo de Apoderado, sin comprobar servicio vigente ni REPORTES_APODERADO. La misma condición protege listado y ficha. Pedro puede satisfacer esa condición para C001, aunque su plan actual es META_UNT, sin cuenta familiar según el informe (apartados 3.1, 3.2.2 y 6.1). El caso de prueba del apoderado compartido cubre dos alumnas Plus y no detecta este límite. Es revisión estática de la condición, corroborada con la relación/plan en SQL; no se ejecutó el repositorio con la cuenta de aplicación en este host. Resolver en B01: no exponer esa rama hasta exigir prestación vigente por alumno.
2. **El dueño aún no tiene contexto de acceso.** IdentidadActiva solo contiene contactoId y el filtro solo admite estudiante/apoderado. validarIdentidad valida un número, no una sesión ni un rol; no hay forma explícita de listar todos los alumnos como dueño. No es una fuga HTTP demostrada —no existen endpoints—, pero hay que resolverlo antes del panel. B01 debe definir una identidad local confiable; no requiere construir un sistema completo de usuarios. Portal familiar se pospone a T32.
3. **Portabilidad de SQL incompleta.** El aprovisionamiento/grant usa PowerShell y autenticación integrada Windows. En este CachyOS no hay .env, USER_ID('lapredigital_app') devuelve NULL y host.docker.internal no resuelve desde el backend. db:check falla por SQLSERVER_USER/SQLSERVER_PASSWORD ausentes. La base está ONLINE con 14 estudiantes y hora -05:00; esto no demuestra conexión de la app. B01 debe configurar el entorno local sin recrear la base ni copiar credenciales entre equipos.
4. **El build falla también en Linux.** Se reprodujo EXDEV al renombrar .eve/builds/.../output hacia .output entre el volumen de Eve y el bind mount. Nitro compila, pero el comando termina con código 1; no es un build correcto ni un problema exclusivo de Windows. Corregir la disposición de artefactos en B01; imagen final en B08. No montar Docker del host para silenciar el aviso independiente de sandbox.
5. **La configuración bloquea seleccionar una base de integración.** apps/server/lib/config.ts:20 exige el nombre exacto LaPreDigital_Customers mediante z.literal. La base aislada prevista para pruebas de escritura no puede elegirse solo por entorno. Resolver en B06 con configuración validada y protección expresa contra operaciones destructivas en la base académica; no eliminar la validación ni usar sa en la app.

El login y herramienta de T05 son evidencia histórica válida de la TUI de Windows. El servidor estándar no desbloquea el llavero y el acceso web todavía no está probado; el plan anterior lo dejaba demasiado tarde en T20. B01 adelanta la prueba de ese camino para evitar construir un panel alrededor de una suposición.

## Qué se ejecutó en este equipo

| Verificación | Resultado |
| --- | --- |
| Encender sql-server-local | Correcto; base ONLINE, 14 estudiantes, hora -05:00 |
| npm ci dentro de Docker, con servidor detenido | 103 paquetes instalados; 105 auditados, sin vulnerabilidades reportadas |
| docker compose up --build -d --wait server | Correcto; servicio healthy en 127.0.0.1:3000 |
| GET /eve/v1/health desde el host | 200, ok: true |
| npm run check / npm run typecheck | Correctos |
| npm test --workspace=@lapredigital/server | 7/7 correctas; configuración y paginación, no riesgo ni progreso |
| npm run build:server | Fallo EXDEV después de compilar Nitro |
| db:check | Fallo esperado por credenciales locales no configuradas |
| Resolución de host.docker.internal | ENOTFOUND dentro del contenedor |
| db:t08 / modelo real / persistencia login | No ejecutados de nuevo; faltan preparación SQL/login locales |

La inspección SQL usó la administración ya existente dentro del contenedor para SELECT de estado, recuento y planes; no se concedió sa a la aplicación ni al agente. No se ejecutaron 01/02/03/04 ni las 29 pruebas históricas. No se consumió MiniMax ni se enviaron comunicaciones.

## Por qué compactar el plan

Los 24 IDs pendientes T09–T32 separaban piezas que se necesitan juntas: servidor/API/panel vacío/listado/ficha/diagnóstico, y persistencia por un lado con pruebas de transacción mucho después. Esa fragmentación multiplica lectura de contexto, documentación y verificaciones sin mostrar una capacidad completa.

El [roadmap activo](ROADMAP.md) define ocho bloques, uno por commit, y deja cinco extensiones después de la demo. No elimina las comprobaciones críticas: mueve las pruebas relevantes a la función que entregan. Las trazas nativas de Eve, node:test existente, SQL directo parametrizado y servicios pequeños bastan para esta etapa. No hay evidencia para añadir colas, repositorios genéricos, RBAC completo o un sistema propio de observabilidad.

No se estiman horas a partir del número de tareas: agrupar reduce coordinación, no elimina la dificultad del login, las reglas o las transacciones. Próximo trabajo concreto: **B01**, no implementar T09 ignorando los bloqueos encontrados.
