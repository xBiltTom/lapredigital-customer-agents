# Roadmap de LaPreDigital · CUSTOMERS

Reorganizado el 12 de noviembre de 2026 por pedido del usuario: entregar resultados completos con menos tareas y validaciones repetidas. Este plan sustituye la ejecución individual de T09–T32; sus IDs se conservan en la correspondencia. Agrupar pendientes no los convierte en trabajo terminado.

## Para continuar

1. Leer [AGENTS.md](../AGENTS.md), [ESTADO.md](ESTADO.md), [CONTEXTO.md](CONTEXTO.md) y [ARQUITECTURA.md](ARQUITECTURA.md).
2. Revisar git status y los últimos commits; preservar cambios del usuario.
3. **B01 finalizada; esperar la reestructuración que el usuario pidió definir antes de continuar.** Los bloques B02 en adelante quedan como referencia. B01 resolvió acceso, SQL local y build; se verificaron login y herramienta reales. La revisión [R01](REVISION_T08_Y_PLAN.md) conserva los hallazgos originales.
4. Antes de escribir SQL o reglas, contrastar el [informe 7.1](reference/documento_InteligenciaNegocios.pdf) y los cuatro scripts de [database/](../database/README.md). El esquema sigue congelado.

## Primer resultado útil

El dueño selecciona a Carla en un panel local, ve progreso y señales reales, conversa con el agente y entiende su diagnóstico con evidencias. Después se añade propuesta → aprobación → simulación. React/Vite y Eve/Nitro comparten servicios; no se agrega otro backend ni otro framework de agentes.

Node 24 sigue en Docker; npm workspaces, SQL Server 2022, mssql y Zod se conservan. Las siete pruebas actuales usan node:test: conservarlas; no migrarlas a Vitest como preparación. Otra herramienta de pruebas se introduce cuando aporte una capacidad necesaria. El login ChatGPT de T05 fue real, pero solo en la TUI de Windows; no demuestra chat web ni despliegue.

## Tareas activas: un bloque, un commit

| ID | Estado | Resultado | Integra tareas anteriores | Depende de |
| --- | --- | --- | --- | --- |
| R01 | Hecha | Revisar T08, encender servicios y compactar el plan | Revisión solicitada | T08 |
| B01 | Hecha | Acceso local, conexión y build utilizables | Ajustes T05/T07/T08; identidad de T16 | R01 |
| B02 | Pendiente | Diagnóstico académico y políticas con datos SQL | T09, T10, T13 | B01 |
| B03 | Pendiente | Agente que explica el diagnóstico en terminal | T11, T12, trazas mínimas T28 | B02 |
| B04 | Pendiente | Panel con listado, ficha y diagnóstico | T16, T17, T18, T19 | B02 |
| B05 | Pendiente | Conversación real del agente en el panel | T20 | B03, B04 |
| B06 | Pendiente | Evaluaciones y propuestas persistidas consistentemente | T14, T15, integración pertinente T24/T28 | B03 |
| B07 | Pendiente | Aprobar, simular seguimiento y derivar al dueño | T21, T22, T23; pruebas pertinentes T24/T25 | B05, B06 |
| B08 | Pendiente | Demo reproducible y empaquetada | T29; cierre acotado T24/T25/T28 | B07 |

B03 y B04 pueden avanzar de manera independiente después de B02; no requieren delegación automática. B06 tampoco necesita esperar el diseño visual. No crear un commit por cada antiguo ID incluido en un bloque. Si surge una separación funcional necesaria, actualizar el plan antes de implementarla.

### B01 · Acceso local, conexión y build

- **Entregar:** configurar este CachyOS con usuario SQL de lectura y .env local, sin reconstruir el OLTP; resolver la dirección SQL desde Docker. Conservar el procedimiento Windows y documentar ambos entornos.
- Definir el contexto confiable del dueño. No hace falta un portal de estudiante/apoderado en el MVP: conservar repositorios útiles, pero no exponer acceso familiar por el mero vínculo; si se habilita, exigir REPORTES_APODERADO vigente por alumno. Un contactoId enviado por el cliente no autentica al usuario.
- Resolver el movimiento final del build entre .eve y .output. Comprobar acceso local al canal y que el proceso del chat pueda usar el llavero; el usuario desbloquea/inicia sesión cuando corresponda. No copiar tokens ni abrir el canal sin autenticación para sortear Docker.
- **Comprobar:** salud, db:check y db:t08 de lectura; dueño puede seleccionar alumnos, acceso ajeno denegado; build termina; prueba real mínima de canal/modelo con participación del usuario. Si falta login, registrar ese bloqueo y avanzar solo en trabajo independiente.
- **Límite:** sin sistema completo de usuarios/roles, OAuth propio, MiniMax ni servicios contratados.

### B02 · Diagnóstico académico y políticas

- **Entregar:** repositorios de progreso, uso, incidencias y evidencias; funciones con corte explícito; permisos de plan/contacto y seguimiento previo en un servicio reutilizable. No crear una clase/interfaz por tabla.
- Cumplimiento por ruta/versión y ventana documentada, con tratamiento de canceladas; mejora por grupo comparable en puntos porcentuales. Sin actividades: no aplicable; sin pruebas comparables: sin datos suficientes.
- Riesgo por umbrales exactos, predominio de la señal mayor y pendiente ante información insuficiente. Separar narrativas aún no interpretadas; no fabricar intención/suficiencia ni inventar caducidad o frecuencia de contacto.
- **Comprobar:** C001 +15 pp, C003 -25 pp, C004 pruebas no comparables, C007 sin datos; límites 72/168 y 48/96 horas y siete días; Inés sin contacto proactivo y Ruta UNT sin SEGUIMIENTO_IA. Probar resultados de negocio, no cada SELECT.
- **Límite:** términos origina las autorizaciones previstas; respetar revocaciones sin nueva pantalla de consentimiento por canal.

### B03 · Agente de lectura y explicación

- **Entregar:** herramientas concretas de Eve reutilizando B02; interpretación estructurada de mensajes/valoraciones con Zod y referencias existentes; instrucciones académicas y manejo de falta de modelo.
- Conservar trazas nativas de Eve; añadir solo corte, versión de reglas y referencias que falten. Sin plataforma propia de observabilidad. Registrar tokens si se midieron, sin atribuir costo API inventado a una suscripción.
- **Comprobar:** llamada real explica Carla y presenta Gabriela pendiente; rechaza evidencia inventada e instrucciones incrustadas para cambiar identidad/reglas; sin SQL libre, shell, archivos generales ni DML.
- **Límite:** una prueba real dirigida al cerrar el bloque; casos con datos fijos no se presentan como prueba del modelo.

### B04 · Panel con datos y diagnóstico

- **Entregar:** endpoints Nitro y panel React/Vite juntos, con listado, ficha, servicio/historial, progreso, incidencias, riesgo y evidencias. Mostrar corte, carga, error y falta de datos.
- Contexto del dueño validado en backend. Extraer contratos compartidos cuando ambos consumidores los necesiten. Serializar DATETIME2 peruano con convención explícita y una prueba que evite desfase de cinco horas.
- **Comprobar:** C006 beca sin pago, C011 reactivación, C007 pendiente y C008 evaluación vencida; petición inválida y acceso fuera del contexto rechazados; panel inicia y compila. Reutilizar cálculos de B02.
- **Límite:** sin dashboard complejo, editor de rutas, portal familiar ni diseño perfecto antes de conectar datos.

### B05 · Chat dentro del panel

- **Entregar:** cliente de Eve, streaming, herramientas/evidencias y errores visibles; estudiante controlado por backend. Reutilizar el acceso probado en B01.
- **Comprobar:** conversación real de Carla en navegador; cambiar de alumno no arrastra contexto ajeno; reinicio conserva sesión según configuración verificada.
- **Límite:** no sustituir silenciosamente al modelo con una frase fija ni repetir el login si sigue funcionando.

### B06 · Evaluaciones y propuestas consistentes

- **Entregar:** servicios transaccionales para evaluación/señales y propuesta/evento de intervención. Validar mayor nivel, pertenencia y actualidad de evidencias, prestaciones y duplicados de la misma operación.
- Preparar base aislada de integración y permitir seleccionarla: hoy SQLSERVER_DATABASE está fijada con z.literal a la base activa. Rechazar operaciones destructivas contra la base académica. Mantener identidad SQL de aplicación y permisos acotados.
- **Comprobar:** señal inválida revierte evaluación completa; evidencia ajena/alterada se rechaza; repetir operación no duplica propuesta. Cubrir los cinco huecos conocidos en las operaciones de la app, sin cambiar los esperados del 03.
- **Límite:** un proceso local y deduplicación persistente verificable; sin Redis/colas distribuidas ni garantías multirréplica. No sobrescribir evaluaciones previas.

### B07 · Aprobación, simulación y atención humana

- **Entregar:** bandeja del dueño para aprobar/rechazar; simulación visible de seguimiento; recomendaciones de revisión de ruta y derivaciones humanas registradas. Revalidar permisos al ejecutar y proteger doble clic/reintento.
- El agente no publica rutas ni gestiona pagos. Rechazo de intervención: CANCELADA y evento/resultado, sin inventar RECHAZADA. Simulación: nunca ENVIADO/ENTREGADO ni estado BORRADOR inexistente en Mensaje.
- **Comprobar:** diagnóstico → propuesta → aprobación → simulación; revocación posterior bloquea acción; C-4 no cuenta simulación; rollback y duplicados de escrituras probados en base aislada.
- **Límite:** sin comunicación real ni editor completo de rutas; el dueño sigue siendo quien las actualiza.

### B08 · Cierre y empaquetado

- **Entregar:** scripts inicio/build/test, imágenes con artefactos compilados y Compose/runbook reproducibles; documentar SQL existente, volúmenes, respaldo/restauración y America/Lima sin reemplazar la instancia activa.
- Añadir solo regresión de navegador que falte para flujos esenciales; Playwright si aporta esa cobertura. Reutilizar pruebas B02/B06/B07 y trazas nativas.
- **Comprobar:** otra sesión sigue README y completa diagnóstico → aprobación → simulación; build y arranque compilado pasan; datos/sesiones sobreviven al reinicio previsto; imagen sin secretos, .git ni archivos del OLTP.
- **Límite:** empaquetable para VPS no significa desplegado. Revisar una modalidad admitida del modelo antes de llevarlo a nube.

## Extensiones después de la demo

| ID anterior | Cuándo abordar | Alcance conservado |
| --- | --- | --- |
| T26 | Después de B08, si hace falta automatización | Primero lote manual, agenda local después; sin LLM para aritmética ni duplicados al reiniciar |
| T27 | Después de B08 y aclarar denominadores | C-1–C-7 provisionales con corte/numerador/denominador; aclarar varias revisiones C-1.1 y pendientes C-3.1; sin cierres congelados |
| T30 | Después de B07, según prioridad | Cambio aceptado no es aplicado; sin modificar precio ni compensar periodo pagado |
| T31 | Después de B07, según prioridad | Referidos por satisfacción contextual y atribución única fijada al primer pago; comunicación simulada |
| T32 | Después de B04/B07, según prioridad | Portal de apoderado por alumno solo con Meta UNT Plus; vínculo familiar no basta |

No son requisitos para B01–B08. Antes de implementarlas, convertir la extensión elegida en tarea concreta, con criterio de cierre y commit propio.

## Trabajo completado

| ID | Resultado | Commit |
| --- | --- | --- |
| T00 | Preservar SQL y documentos originales | 513d0c9 |
| T01 | Organizar workspace y remoto | 9059457 |
| T02 | Roadmap, contexto y continuidad | d308ea6 |
| T03 | Node 24 aislado en Docker | 381cd70 |
| T04 | Backend mínimo Eve | 37a1910 |
| T05 | Login y herramienta fija reales en TUI | 37b7f46 |
| T06 | Configuración Zod | d80d789 |
| T07 | Pool SQL y cuenta de lectura en Windows | cc7d01b |
| T08 | Repositorios perfil/servicio | a9eb90e |

T09 no está implementada en HEAD ni origin/main revisados; se integra en B02. Las verificaciones históricas de T05/T07/T08 no equivalen a ejecución nueva en otro equipo. [ESTADO.md](ESTADO.md) conserva resultados y límites.

## Cómo trabajar más rápido sin perder defensa técnica

- Una tarea entrega una capacidad verificable. Implementación, pruebas pertinentes y actualización breve de ESTADO.md van en el mismo commit; sin commits vacíos de seguimiento.
- Leer contexto al retomar; luego releer secciones afectadas. Consultar docs de Eve/AI SDK al cambiar su integración, sin investigarlos de nuevo en cada SELECT.
- npm ci solo cuando cambie el lockfile o falten dependencias, con servidor detenido. Reutilizar caché/volúmenes; no reinstalar y reconstruir sin motivo entre verificaciones.
- Funciones puras para cálculos, SQL parametrizado para datos, servicios para permisos/transacciones y adaptadores pequeños para tools/API. Sin repositorio genérico, bus de eventos o framework propio.
- Pruebas dirigidas de negocio/fallos. Tipos y check una vez al cerrar el bloque; repetir por cambios relevantes o fallos. Build cuando afecte empaquetado/configuración o al cerrar un hito de app.
- Transacciones, pertenencia de evidencia, permisos, límites horarios y simulación/envío sí requieren comprobación. Estilos, textos y movimientos de archivos no necesitan tests que copien su implementación.
- Integración destructiva siempre aislada; nunca 01/02 al arrancar. No ejecutar las 29 pruebas históricas por cada cambio documental; conservar los cinco HALLAZGO.
- Llamadas reales de modelo explícitas y dirigidas, sin repetirlas por documentación/cálculos puros. Registrar bloqueos de login y avanzar solo tareas independientes.
- Push normal cuando esté autorizado; preservar consultas personales y cambios del usuario. Sin Git forzado, nube contratada ni mensajes reales.

Reglas completas y cinco huecos: CONTEXTO.md. MiniMax sigue sin confirmar como saldo API y no se consume. Sesiones, credenciales y trazas fuera de Git.
