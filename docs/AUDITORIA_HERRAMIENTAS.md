# Auditoría y propuesta de herramientas del agente

Fecha: 13/11/2026. Este documento conserva el diagnóstico previo. La implementación autorizada posterior y sus comprobaciones se documentan en ESTADO.md, sección M30.

## Resultado

La prioridad es corregir la selección de herramientas y completar la lectura académica del participante. Los datos para responder rendimiento ya existen en buena parte; hoy están repartidos entre un diagnóstico privado, una proyección parcial del portal y una consulta de registros.

Existe un solo agente Eve con contextos distintos: dueño global, dueño individual, participante en Academia, participante en Mensajería y análisis de caso de solo lectura. No son cinco agentes independientes. El modelo base tiene las herramientas generales desactivadas (`defaultTools: false`), pero las nueve herramientas propias están registradas estáticamente, incluso donde su ejecución se rechaza.

No se propone cambiar el esquema, incorporar proveedores, modificar rutas automáticamente ni crear agentes de otras fases. Primero se presenta el contrato deseado y después corresponde implementarlo y evaluarlo.

## Evidencia y límites de esta revisión

- Lectura de README, ESTADO, CONTEXTO, ARQUITECTURA, ROADMAP, instrucciones del agente, las nueve herramientas, canales, servicios, consultas y pruebas relacionadas. Contraste con la sección 6 de CUSTOMERS y los criterios C-1.2/C-1.3 del informe, y con los cuatro SQL canónicos.
- Documentación instalada de Eve **1.0.0-rc.10**: herramientas, instrucciones, contexto y configuración dinámica. Permite devolver una herramienta o `null` según la sesión; la autorización debe verificarse también al ejecutar. No hace falta cambiar de framework.
- Ejecución en Docker, Node **v24.22.3**. `GET /api/status`: HTTP 200 y modelo `ready`. Esto acredita disponibilidad informada por Eve, no una respuesta nueva del modelo.
- `GET /eve/v1/info`: nueve herramientas estáticas, ninguna dinámica y ninguna proyección `toModelOutput` ni esquema de salida. Las dos instrucciones estáticas activas coinciden exactamente con las fuentes actuales del repositorio; existe además la instrucción dinámica de modos. Esto no demuestra qué prompt recibió la conversación histórica del amigo.
- Lectura autenticada de 30 estudiantes y diagnósticos C001, C004 y C007. Corte: **13/11/2026 04:34:46, America/Lima**.
- Invocación directa, sin modelo ni SQL, de `consultar_diagnostico` con contexto global sin alumno y con contexto participante: ambos rechazos reproducidos. El esquema de `operar_plataforma` acepta `ENVIAR` sin texto/destinatario; esos requisitos se comprueban después, al ejecutar.
- No se enviaron mensajes, crearon sesiones, interpretaciones, casos o propuestas, ni se modificó la base. No se reinició el servidor, desbloqueó el llavero o reconstruyó la aplicación.
- No se reprodujo la conversación exacta reportada: falta identificar ese turno y su traza. Los hallazgos verifican una causa compatible, no atribuyen con certeza esa ejecución histórica.

Comprobación temporal: `tmp/auditar-herramientas.mjs`, ignorada por Git. Solo usa GET autenticados y validaciones locales; su salida omite credenciales y narrativas personales. No forma parte de la suite permanente.

## El problema de «pásame mi rendimiento»

Hay tres problemas distintos:

1. **Selección:** el participante ve `consultar_diagnostico`, pero `identidadHerramienta` lo rechaza. ESTADO ya documenta ese mismo síntoma y un ajuste previo de instrucciones. El catálogo sigue ofreciendo la opción equivocada.
2. **Descripción contradictoria:** `consultar_diagnostico` dice servir para dashboard o acompañamiento, pero no acepta `estudianteId` y la conversación global no fija alumno. La instrucción raíz también recomienda esa herramienta para dashboard; la instrucción dinámica global dice que no se use.
3. **Cobertura:** `operar_plataforma ESTUDIANTE` devuelve al participante nombres, plan, cumplimiento, mejoras, temario y mensajes. Omite corte/ventana, intentos individuales, actividades, ruta, dificultades, uso y prestaciones. `consultar_base EVALUACIONES` permite recuperar intentos, pero el modelo tiene que descubrir ese segundo camino.

Fuentes actuales tras la reorganización: [instrucciones](../apps/server/agent/instructions.md), [modos](../apps/server/agent/instructions/20-modos.ts), [riesgo](../apps/server/agent/tools/consultar_riesgo.ts), [alcance](../apps/server/lib/seguridad/alcance-herramientas.ts), [rendimiento](../apps/server/agent/tools/consultar_rendimiento.ts). Los nombres retirados se conservan en el análisis histórico siguiente.

Resultados actuales de lectura:

| Estudiante | Intentos | Mejora calculable | Cumplimiento de ruta |
| --- | --- | --- | --- |
| C001 Ana | 2 | +15 pp en Álgebra | 1/2, 50 % |
| C004 Diego | 2 | No: un intento por cada grupo distinto | 3/6, 50 % |
| C007 Gabriela | 0 | Sin datos suficientes | Sin actividades planificadas; no aplicable |

Diego tiene resultados aunque no tenga una mejora comparable. Gabriela carece de evaluaciones; eso no implica falta de permiso. Marcar temas completados tampoco demuestra dominio. Las respuestas deben expresar estas diferencias por sección.

## Inventario actual y decisión propuesta

Esta tabla distingue ejecución permitida de visibilidad: hoy las nueve definiciones son estáticas.

| Herramienta actual | Alcance efectivo principal | Decisión propuesta |
| --- | --- | --- |
| `comprobar_conexion` | Prueba local, sin consulta de negocio | Retirar del catálogo conversacional; conservar como comprobación técnica. |
| `consultar_diagnostico` | Dueño con alumno fijado; también análisis de caso | Convertir en `consultar_riesgo`, reservada al dueño, con ID explícito solo en global. Separar el informe académico del diagnóstico interno de retención. |
| `interpretar_contexto` | Dueño individual o global con ID; bloqueada en análisis | Mantener como paso interno del diagnóstico, con huella y fuentes verificadas. No ofrecer al participante. |
| `proponer_intervencion` | Dueño individual; bloqueada en análisis y sin alumno en global | Mantener propuesta/aprobación/simulación. Unificar selección del alumno; permitir global con ID validado si se adopta el contrato común. |
| `consultar_base` | Global o alumno fijado, incluido participante | Conservar lectura detallada y paginada; hacer explícita la semántica de cada recurso. Sacar casos hacia `gestionar_caso`. Proyectar columnas por rol. |
| `consultar_indicadores` | Dueño global | Mantener; cuatro KPI disponibles y mes provisional. |
| `consultar_reglas` | Dueño | Mantener como consulta de configuración actual/histórica. |
| `gestionar_caso` | Dueño consulta; participante de Mensajería consulta/registra/deriva | Conservar listado/detalle/reporte. Mover la derivación a una sola herramienta de consultas al dueño. |
| `operar_plataforma` | Siete acciones con permisos diferentes | Retirar del catálogo una vez sustituidas sus acciones por contratos específicos. Reutilizar servicios existentes. |

## Catálogo propuesto por responsabilidad

Los nombres son una propuesta, no nuevas implementaciones. La separación es del contrato que ve el modelo; no exige duplicar repositorios ni consultas.

### Ampliación solicitada: consultas generales del dueño

El dueño quiere consultar la base actual desde el chat global del Dashboard. Incorporar una herramienta exclusiva de ese ámbito, tentativamente `consultar_datos_negocio`, con lecturas entre entidades, agrupaciones, conteos, fechas y relaciones del esquema de negocio autorizado. Ejemplos: renovaciones próximas, alumnos con incidencias y poca actividad, mensajes sin respuesta y cambios registrados en historiales. Cada ejecución consulta SQL y devuelve su corte; no depender de la memoria del chat para afirmar el estado actual.

`consultar_base` pasaría a llamarse `consultar_registros`. Conservaría el acceso a registros concretos del alumno; las preguntas transversales del dueño irían a `consultar_datos_negocio`. Ambas deben reutilizar definiciones y fuentes. Si las dos resuelven exactamente el mismo contrato global, unificarlas en lugar de ofrecer dos rutas equivalentes. Los cálculos oficiales de riesgo/KPI siguen usando sus servicios existentes.

El agente describe la consulta con operaciones y entidades permitidas; el backend resuelve relaciones y valores parametrizados. No ofrecer SQL libre, procedimientos arbitrarios ni acceso general a archivos. Para garantizar lectura en SQL, usar una conexión con identidad dedicada y permisos SELECT sobre las tablas/vistas de negocio autorizadas, independiente de las credenciales usadas por operaciones de escritura. Acotar resultados, tiempo y paginación; conservar metadatos de fuente y corte. Esto es una propuesta de permisos, no una concesión ya aplicada ni un cambio de esquema.

Las tablas Conversacion, Mensaje y MensajeCanalLocal no tienen una columna EsSimulacion. Eso no convierte todos sus registros en comunicaciones externas reales: existen datos ficticios de población, intercambios efectivos del portal local y, en Intervencion.Resultado, simulaciones explícitas que no crean mensajes enviados. Los chats internos del dueño se conservan en Eve y no forman parte de esas tablas SQL. La consulta debe identificar el origen disponible y reconocer cuando no existe evidencia suficiente para distinguir una fila sembrada de otra originada por uso; no inferirlo solo por el nombre de la tabla.

| Entrada propuesta | Responsabilidad exclusiva | Acceso |
| --- | --- | --- |
| `consultar_rendimiento` | Resumen académico: resultados recientes, evolución comparable, cumplimiento/ventana, ruta vigente, dificultades y actividad. Explicar disponibilidad de cada sección. | Dueño y participante, con proyección distinta. |
| `consultar_base` | Registros concretos de evaluaciones, actividades, pagos, servicio y valoraciones; filtros, fechas y páginas. No recalcular diagnósticos ni KPI. | Dueño y participante en su alcance. |
| `consultar_temario` | Catálogo y avance por tema, filtrable por curso/tema/estado; separado de las actividades de ruta y las notas. | Dueño y participante. |
| `consultar_dashboard` | Panorama global de estudiantes y prioridades, con búsqueda/filtros. No traer el diagnóstico completo de cada alumno como resultado. | Dueño global. |
| `consultar_riesgo` + `interpretar_contexto` | Diagnóstico interno, señales, política, evidencias e interpretación controlada. El informe académico corresponde a rendimiento. | Dueño. |
| `gestionar_caso` | Listar/ver casos permitidos y registrar o ampliar un reporte claro de Mensajería. Sin descuentos, resolución o reapertura autónoma. | Dueño lee; participante de Mensajería reporta. |
| `gestionar_consulta_dueno` | Única vía para abrir una consulta y comunicar una decisión autorizada. Entradas distintas según rol; conservar origen e idempotencia. | Participante solicita; dueño responde. |
| `enviar_mensaje_local` | Envío solicitado por el dueño, destinatario validado, canal Mensajería, comprobación de plan y contacto. | Dueño. |
| `registrar_no_contacto` | Registrar la petición de no seguimiento y comunicar su efecto real. No reutilizar una consulta genérica que el modelo deba prefijar manualmente. | Participante, ambos canales. |
| `consultar_indicadores`, `consultar_reglas`, `proponer_intervencion` | Conservar sus responsabilidades actuales y permisos explícitos. | Dueño, con ámbito correspondiente. |

La lectura del hilo reciente de Mensajería se prepara automáticamente en backend antes de responder. Si después hace falta consultar mensajes anteriores, puede agregarse paginación específica; no hace falta una herramienta adicional para el arranque del turno.

Cada sesión recibe únicamente su subconjunto. Academia tiene lectura académica y de cuenta, consulta al responsable y no contacto; Mensajería añade reportes. El análisis de caso, que ya recibe los hechos preparados, puede trabajar sin herramientas. El dueño global puede seleccionar un ID validado; individual/participante lo reciben del servidor. Un modo desconocido no debe asumir acompañamiento individual.

## Solapamientos encontrados y fronteras propuestas

| Solapamiento actual | Frontera propuesta |
| --- | --- |
| `consultar_diagnostico` y `operar_plataforma ESTUDIANTE` del dueño devuelven prácticamente el mismo diagnóstico; el segundo agrega conversaciones locales. | Rendimiento para preparación; riesgo para retención interna; contexto del hilo separado. Compartir cálculos, no duplicar resultados completos. |
| `ESTUDIANTE`, diagnóstico y `TEMARIO` incluyen el mismo catálogo. | Temario filtrado bajo demanda; rendimiento devuelve contadores y temas relevantes. |
| `gestionar_caso DERIVAR` y `operar_plataforma CONSULTAR_DUENO` derivan al dueño. | Una única entrada `gestionar_consulta_dueno`, reutilizando `tramitarReporte` donde existe mensaje de origen. |
| `consultar_base INCIDENCIAS` y `gestionar_caso CONSULTAR` consultan casos con coberturas diferentes. | Casos se listan y detallan desde `gestionar_caso`, con proyección de participante. |
| `RESUMEN` contiene KPI que también devuelve `consultar_indicadores`. | Dashboard orienta prioridades; indicadores da fórmulas/cifras. Si el resumen conserva KPI breves, usar la misma función y señalar el mismo corte. |

Compartir tablas o funciones no es un problema por sí mismo. Sí lo es ofrecer dos caminos indistinguibles que devuelven coberturas diferentes sin explicarlo. Resumen calculado y listado de evidencias pueden coexistir si sus descripciones dejan clara esa relación.

## Situaciones que todavía requieren cobertura

### Prioridad alta: preparar un primer turno correcto

- **Permiso frente a ausencia:** devolver errores de alcance diferenciados de `SIN_REGISTROS`, `NO_APLICABLE` y `SIN_COMPARABILIDAD`. Un fallo de SQL tampoco acredita que no haya datos. No exigir interpretar riesgo o contactar al dueño para contestar una consulta académica ordinaria.
- **Fechas futuras:** [consultarBase](../apps/server/lib/servicios/consultas.ts) impone `fecha <= GETDATE()` a todos los recursos. En ACTIVIDADES, fecha es FechaPlanificada; en SERVICIO, Inicio. Eso impide consultar correctamente «qué tengo mañana» o un periodo futuro ya registrado, incluso dando un rango futuro. Usar semántica temporal por recurso; conservar el corte para resultados observados.
- **Paginar sin inventar totales:** límite predeterminado 10, máximo 50; `totalCoincidencias` está en cada fila y desaparece si una página está vacía. Proponer metadatos explícitos de cobertura/total/página siguiente. Una página vacía no prueba ausencia en todo el historial.
- **Identidad y columnas:** `consultar_base` limita alumno, pero usa las mismas proyecciones para dueño y participante. INCIDENCIAS incluye descripción y resolución completas; PAGOS incluye ID del pagador. Definir qué datos de atención son públicos antes de exponerlos. No se demostró acceso cruzado a otro alumno en esta revisión.

### Prioridad media: situaciones comunicadas por el estudiante

- **«Me cuesta ecuaciones»:** existe DificultadAcademica, pero no una herramienta para registrar esa dificultad desde el chat. No crear CasoAtencion por una dificultad de estudio. Propuesta posterior: `registrar_dificultad`, con alumno/origen del servidor y sin modificar la ruta. Requiere diseñar deduplicación y revisión; no activarla automáticamente como parte de esta auditoría.
- **«Cambié de carrera/fecha»:** administración ya puede pedir revisión de ruta al editar el perfil. El participante carece de operación equivalente. En primera fase derivar con hechos precisos al dueño; después evaluar una solicitud de revisión, sin editar el objetivo o la ruta por inferencia.
- **«Recomiéndame material»:** existen recursos con título, tipo y Ubicacion, pero las herramientas no ofrecen una búsqueda de materiales con enlaces y disponibilidad. `TEMARIO` es catálogo, no biblioteca. Candidata posterior: `buscar_recursos`, validando acceso y devolviendo solo enlaces existentes; un enlace vacío sigue sin material disponible. No hay evidencia para prometer leer el PDF/video.
- **«¿En qué preguntas fallé?»:** IntentoEvaluacion guarda aciertos y total, no respuestas por pregunta. Ninguna herramienta puede reconstruir esos errores. Explicar el límite o analizar un enunciado aportado; no inventar una herramienta de análisis por pregunta sin datos.

### Consistencia del contexto y de las acciones

- **Narrativas de dos orígenes:** [diagnóstico SQL](../apps/server/lib/database/consultas/diagnostico.ts) interpreta mensajes entrantes de `dbo.Mensaje`; el portal escribe en `dbo.MensajeCanalLocal`. El dueño puede leer mensajes locales con ESTUDIANTE, pero esas narrativas no integran la huella ni las señales del diagnóstico. Una intención nueva de no renovar en el portal puede ser conocida por el chat y no por el riesgo calculado. Mantener origen/ID explícitos; SenalRiesgo referencia Mensaje, de modo que persistir evidencia local requiere un diseño aparte. No mezclar IDs ni ampliar el esquema sin discutirlo. La operación actual NO_CONTACTO sí bloquea el envío proactivo local mediante ConsultaDueno.
- **No contacto:** actualmente se registra como Pregunta con prefijo `NO_CONTACTO:` y cualquier fila así bloquea al estudiante. No actualiza AutorizacionContacto ni implementa reanudación. La herramienta nueva debe describir ese efecto real; cambiar alcance por contacto/canal o permitir reanudación sería una decisión adicional, no una regla asumida.
- **Reintentos:** derivar desde Mensajería tiene deduplicación por mensaje; `consulta()` genérica y NO_CONTACTO insertan sin ese vínculo. Envío local y respuesta del dueño tienen varios pasos. Diseñar resultado/idempotencia para un timeout después de un efecto, sin afirmar que una llamada repetida es inocua. Este riesgo se detectó por lectura, no provocando fallos reales.
- **Atención manual:** el bot y el equipo pueden responder en paralelo; hoy no hay toma exclusiva de la conversación. Preparar el hilo reciente es necesario, pero no garantiza coordinación si ambas respuestas ocurren simultáneamente. La pausa o toma de control debe discutirse como comportamiento del producto.

## Reorden del contexto

1. **Base breve:** identidad, reglas estables, tratamiento de datos no confiables y veracidad de acciones. Reducir el catálogo de otras fases a lo necesario para derivar; no sugerir agentes que no existen.
2. **Un contrato por modo:** actor, interlocutor, estudiante fijado o global, canal, operaciones permitidas y prohibidas. Catálogo dinámico coherente con ese contrato. Mantener guardas de backend: ocultar no reemplaza autorizar.
3. **Inicio del turno:** identidad autenticada, plan/prestaciones necesarias y corte peruano; en Mensajería, tramo reciente del hilo público, decisiones pendientes/autorizadas y referencias. No cargar un diagnóstico privado al participante. Los hechos recuperados siguen siendo datos, aunque los adjunte el servidor.
4. **Detalle bajo demanda:** rendimiento o recurso solicitado. El diagnóstico de Ana midió **34 592 bytes JSON** y el de Gabriela **30 785**; ambos incluyen 162 temas aunque la pregunta no sea sobre temario. Son bytes de respuesta API, no una medición de tokens ni latencia del modelo. Hoy no hay `toModelOutput` para reducirlo.
5. **Salidas con alcance:** alumno, corte, ventana efectiva, versión de ruta/grupo, fuentes e IDs, disponibilidad por sección y cobertura/paginación. Ejemplo: cumplimiento en 30 días y mejora entre intentos comparables de todo el historial no deben aparentar el mismo periodo.
6. **Historial:** conservar direcciones separadas como ahora. Al abrir una sesión nueva del dueño, panel reinyecta todo el diálogo público recuperado; no las evidencias estructuradas de herramientas. No tratar esas afirmaciones antiguas como estado actual. El portal no tiene el mismo índice/reinyección explícita; consulta su bandeja, pero Academia no está obligada a hacerlo en cada turno. Evaluar continuidad en ambos canales sin fusionarlos.
7. **Datos actuales:** la documentación de Eve confirma compactación nativa; no asumir que el proyecto carece de ella. Lo que falta aquí es reducir resultados y definir qué hechos operativos deben recuperarse de nuevo después de resumir/reabrir. Nunca cachear permisos o situación académica para toda la sesión sin invalidación.

## Verificación propuesta después de implementar

Las pruebas existentes cubren reglas, identidad HTTP, filtros e historial; las comprobaciones de integración verifican escrituras e incidencias. No constituyen una evaluación sistemática de selección de herramientas en un primer mensaje. Primero verificar contratos/alcances sin modelo; después conversación real en sesiones aisladas.

| Escenario | Resultado exigido |
| --- | --- |
| Primer mensaje «pásame mi rendimiento», C001 | Rendimiento actual, +15 pp y cumplimiento con su ventana. Cero intentos de herramienta privada por el participante. |
| Misma pregunta, C004 | Mostrar resultados individuales; explicar que no hay pareja comparable. |
| Misma pregunta, C007 | Sin intentos y cumplimiento no aplicable, sin atribuir falta de acceso. |
| Apoderado Plus | Hablar al apoderado, datos del estudiante vinculado y ningún riesgo/nota interna. |
| Apoderado sin prestación o vínculo cambiado | Rechazo del backend, aunque exista conversación previa. |
| «¿Qué tengo mañana?» | Incluir actividades futuras pertinentes; distinguir de cumplimiento histórico. |
| «¿Cuándo empieza mi renovación?» | Leer periodo futuro registrado sin presentarlo como acceso ya vigente. |
| «Mi último pago» / beca completa | Cobro confirmado real, o explicar beca/servicio sin inventar deuda. |
| «Me cuesta este tema» frente a «no abre el material» | Ayuda/dificultad académica frente a incidencia de servicio; sin mezclar registros. |
| Decisión económica | Una consulta al dueño con origen, sin prometer descuento ni aplicar cambios. |
| «No me escriban» | Bloqueo proactivo verificado; consulta entrante académica sigue atendible. |
| Dos roles y dos canales | Sin mezcla de interlocutor, estudiante, bandeja o historial. |
| Herramienta incorrecta, error SQL o página vacía | Recuperar el camino permitido o explicar el error real; no declarar ausencia/acceso indebidamente. |
| Sesión nueva, restaurada y compactada | Identidad y catálogo correctos desde el primer turno; releer hechos actuales. |
| Envío repetido / timeout / decisión reenviada | Un solo efecto o resultado explícito de incertidumbre; no declarar entrega sin lectura. |
| Análisis de caso | Solo hechos preparados, sin efectos laterales ni consultas redundantes. |

No repetir escrituras contra la base activa para esta evaluación: usar MvpTest y sesiones de prueba. Las primeras pruebas reales prioritarias son C001, C004 y C007 en ambos canales, y apoderado Plus. Medir ruta elegida, intentos fallidos, fidelidad factual y tamaño del contexto; no solo que aparezca texto.

## Orden recomendado

1. Catálogo por modo, instrucciones coherentes y `consultar_rendimiento`; estados de disponibilidad y errores claros. Resuelve directamente el fallo reportado sin tocar el esquema.
2. Sustituir `operar_plataforma`, unificar derivación/casos, separar hilo y reducir proyecciones. Corregir fechas/paginación con las pruebas anteriores.
3. Evaluar con modelo real el primer turno y la continuidad. No dar por corregida la selección a partir de tipos o tests unitarios.
4. Decidir aparte registro de dificultades, búsqueda de materiales, revisión de objetivos, integración de narrativas locales y coordinación con atención humana. Son necesidades adicionales, no extensiones ya ejecutadas.
