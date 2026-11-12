# Contexto y decisiones de LaPreDigital

Actualizado: 12 de noviembre de 2026. Este documento conserva acuerdos de negocio y de implementación que no deben depender de recordar el chat.

## Proyecto y fuentes de verdad

Proyecto académico de Ingeniería de Sistemas: plataforma virtual de preparación para ingreso a la Universidad Nacional de Trujillo, inicialmente para Trujillo y La Libertad. El embudo sigue BUYERS → LEADS → PAYERS → CUSTOMERS → TURNED. El foco actual es CUSTOMERS y su Agente Académico.

El [informe entregado](reference/documento_InteligenciaNegocios.pdf), identificado por el usuario como versión 7.1, es la fuente de verdad de las reglas. Las decisiones posteriores explícitas del usuario se registran aquí y prevalecen para trabajar. La [revisión SQL](database/REVISION_CUSTOMERS.md) conserva lo comprobado anteriormente.

## Acuerdos recientes que cambian cómo continuar

1. La base se conserva como está por tiempo. Solo se vuelve a evaluar el esquema si una prueba del agente demuestra una necesidad concreta.
2. Desarrollo local; no hay presupuesto para contratar APIs nuevas ni servidores cloud. El usuario tiene una suscripción de ChatGPT y 2.000 créditos MiniMax, pero se desconoce el plan exacto y si el saldo es utilizable por API.
3. Stack acordado: TypeScript, Node 24, Eve/Nitro, React/Vite, SQL Server 2022 Docker, mssql, Zod y Vitest. Una única aplicación de agentes académicos con herramientas; multiagentes de otras fases después.
4. Primero probar el login local de ChatGPT de Eve; no hay una integración verificada ni un modelo fijado todavía. No existe permiso implícito para convertir créditos dudosos en consumo pagado.
5. La aceptación de términos y condiciones al registro incluye las comunicaciones previstas del servicio. Es el evento de autorización inicial; no añadir otra aceptación manual por mensaje/canal. Conservar evidencia/versionado y respetar una solicitud posterior de no seguimiento proactivo. Aún no existe texto de términos ni flujo de alta implementado.
6. Cada tarea del roadmap corresponde a un commit, incluyendo la actualización de continuidad. El usuario pidió organizar el workspace e inicializar el remoto `git@github.com:xBiltTom/lapredigital-customer-agents.git`.

## Entorno y estado de datos

- CachyOS, shell bash, zona America/Lima.
- Contenedor conocido: sql-server-local; SQL Server 2022 Developer; base LaPreDigital_Customers.
- Hora de negocio en Perú y GETDATE; no usar sufijos Utc en las columnas actuales.
- Intercalación Latin1_General_100_CI_AS_SC; código de rol N'DUEÑO'.
- 40 tablas operativas y 14 de historial; carga de referencia: 501 registros operativos y 39 históricos, con 14 estudiantes (12 CUSTOMER, 1 LEAD, 1 TURNED).
- Verificación SQL previa del 12/11/2026: 29 pruebas, 24 OK y 5 HALLAZGO conocidos; DBCC sin infracciones. Es evidencia histórica, no ejecución de esta sesión.
- El usuario siguió editando 04_consultas_customers.sql. La inicialización preserva su versión exacta; no certificar sus nuevas consultas por los resultados previos.
- Los scripts son creación/población, no migraciones. La base no es un DataMart. Los historiales son tablas normales con triggers multirregistro.
- Se retiró FechaAlta de Contacto y su historial por redundancia. El ingreso a LEAD sale del primer FormularioContacto válido; FechaRegistro indica cuándo se guardó el dato.

## Semántica de personas y contratación

Contacto guarda la persona y sus datos. Estudiante.ContactoId es el propio estudiante; Apoderado.ContactoId es otra persona. Un estudiante tiene como máximo un apoderado y un apoderado puede tener varios estudiantes. Unir Contacto dos veces con alias es correcto. La vinculación familiar no concede acceso automáticamente.

Suscripcion agrupa una contratación y su continuidad. PeriodoServicio registra el tramo concreto de servicio, su modalidad, inicio/fin, precio, beca e importe exigible. Una renovación continua crea otro periodo de la misma suscripción. Si hubo baja y el estudiante vuelve después, la demo crea nueva suscripción con periodo REACTIVACION y conserva el historial. ModalidadPlan determina plan y duración (mensual/semestral); no repetir PlanServicioId en el periodo.

ImporteExigiblePEN no equivale a dinero pagado. Los cobros se consultan en Pago con Tipo=COBRO y Estado=CONFIRMADO. Reembolsos, reversiones y disputas son operaciones separadas; no confundir cobro bruto, ingreso neto y gasto después de devoluciones. Los pagos pueden efectuarlos otras personas para el estudiante.

## Reglas que debe respetar el agente

- CUSTOMER desde el primer acceso habilitado por pago confirmado o beca completa autorizada. No exige renovación previa.
- Renovación continua mantiene CUSTOMER. Desactivar renovación automática mantiene acceso hasta Fin. Baja al vencer sin continuidad, sin siete días de tolerancia.
- Beca del 100 % sin pagos ficticios.
- Reportes/cuenta de apoderado por alumno solo con Meta UNT Plus. Verificar prestaciones del plan vigente, no solo el vínculo.
- El dueño actualiza las rutas; el agente propone. Pagos, descuentos y reclamos económicos se derivan a PAYERS/personal autorizado; esos agentes todavía no existen.
- Aceptar propuesta de cambio no significa aplicarla. No alterar el periodo pagado ni generar compensaciones.
- Cumplimiento y mejora se interpretan por separado. Sin tareas planificadas: no aplicable. Sin dos pruebas comparables por alcance, escala y dificultad: sin datos suficientes. 40 % → 55 % = +15 puntos porcentuales.
- Satisfacción: cada calificación válida tiene igual peso; no promediar promedios por aspecto para el general.
- Última actividad no equivale necesariamente al último login.

| Señal | Regla de riesgo |
| --- | --- |
| Inactividad | Desde 72 y menos de 168 horas: MEDIO; desde 168: ALTO |
| Incidencia servicio/acceso sin resolver | Más de 48 y hasta 96 horas: MEDIO; más de 96: ALTO |
| Dificultad que requiere seguimiento | MEDIO si no hay un criterio más alto |
| Intención explícita de cancelar/no renovar | ALTO |
| Valoración de 1–2 estrellas con insatisfacción contextual | ALTO |
| Información insuficiente | PENDIENTE; no asumir BAJO |

Prevalece el mayor riesgo disponible. Una evaluación vigente tiene como máximo siete días. En incidencias reabiertas se conserva el reloj de apertura original, incluidas horas intermedias. No inventar caducidad para una intención antigua ni certeza de suficiencia sin definir la política.

C-4 requiere mensaje enviado y una intervención completada; una propuesta, borrador o simulación no acredita envío real. Los reportes mensuales conservan lo conocido al cierre; eso todavía no está implementado. Los indicadores actuales son provisionales.

## Cinco huecos conocidos del esquema

1. EvaluacionRiesgo puede pasar a BAJO aunque sus señales sigan siendo ALTO.
2. SenalRiesgo puede guardar un nivel contrario al criterio documentado.
3. Se puede registrar Mensaje ENVIADO aunque el canal/finalidad esté denegado. La aceptación inicial de términos aclara cómo nace el permiso, pero no impide esta escritura ni elimina revocaciones.
4. Una evidencia ya vinculada puede cambiar de estudiante en su tabla de origen y romper la trazabilidad.
5. Se puede marcar EtapaActual=CUSTOMER sin servicio habilitado vigente.

Las pruebas de estos huecos revirtieron las modificaciones. Los datos de la demo no se dejaron alterados. La aplicación debe restringir sus escrituras a operaciones validadas y transaccionales; eso no protege frente a cualquier edición SQL directa. No afirmar que el problema de base está corregido por haberlo cubierto solo en código.

## Escenarios de referencia

| Código | Caso útil |
| --- | --- |
| C001 Ana | Mejora +15 pp y nueva versión de ruta |
| C002 Bruno | 96 horas sin uso; seguimiento C-4 completado |
| C003 Carla | 192 horas sin uso y 2 estrellas con insatisfacción |
| C004 Diego | Incidencia de acceso >96 horas, aunque use recientemente |
| C005 Elena | Renovación continua; Plus; comparte apoderada con Carla |
| C006 Fabio | Beca completa, cero pagos |
| C007 Gabriela | CUSTOMER reciente, sin actividad/pruebas; pendiente |
| C008 Hugo | Evaluación con más de siete días; necesita reevaluación |
| C009 Inés | No renovar y no recibir más seguimiento proactivo; conserva acceso pagado |
| C010 Jorge | TURNED por vencimiento sin renovación |
| C011 Lucía | Baja y reactivación con nueva suscripción |
| C012 Mateo | Cambio aceptado sin aplicar; incidencia reabierta |
| C013 Paula | LEAD referido sin pago/acceso |
| C014 Rubén | Meta UNT semestral; referente fijado por primer pago |

Las fechas son relativas a @Ahora en la población y envejecen. Antes de atribuir una diferencia a un bug, comprobar el corte y la fecha de carga.
