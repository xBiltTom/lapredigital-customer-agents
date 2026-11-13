# Herramientas del agente académico

El backend tiene catorce herramientas dinámicas, con un solo agente Eve. `alcance-herramientas.ts` determina cuáles se anuncian y vuelve a validar identidad/alcance en ejecución. Un modo desconocido no habilita herramientas. El análisis de un caso usa los hechos ya preparados y no recibe ninguna.

| Contexto | Herramientas disponibles |
| --- | --- |
| Dueño, Dashboard | dashboard, datos de negocio, indicadores, reglas, rendimiento, riesgo, temario, envío local, consulta de casos, respuesta a consultas e interpretación/propuesta |
| Dueño, individual | registros del alumno fijado, reglas, rendimiento, riesgo, temario, envío local, consulta de casos e interpretación/propuesta |
| Participante, Mensajería | rendimiento, registros propios, temario, reportar/consultar casos, solicitar decisión y no contacto |
| Participante, Academia | rendimiento, registros propios, temario, solicitar decisión y no contacto |

## Elegir una entrada

- `consultar_rendimiento`: preparación del alumno. Separa resultados individuales, mejora por grupo comparable, cumplimiento de la ruta en 30 días, dificultades, actividad y contadores del temario. Devuelve estado por sección, fuentes y corte; los intentos adicionales se consultan en registros. La frecuencia compara siete días con los siete anteriores. No devuelve mensajes, riesgo ni notas de atención internas.
- `consultar_registros`: antes `consultar_base`. Detalle paginado de pagos, servicio, actividades, evaluaciones y valoraciones del alumno fijado. Estado/fecha/tipo/orden se validan; cuenta total independiente de la página y permite planificación/contratación futura. Retira el ID del pagador para participantes. No está en Dashboard: ahí las consultas de registros globales se resuelven con datos de negocio.
- `consultar_temario`: catálogo/progreso con curso, texto, estado y páginas. No convierte completados en notas o dominio.
- `consultar_dashboard`: panorama y prioridades, más consultas pendientes. Las fórmulas de KPI pertenecen a `consultar_indicadores`.
- `consultar_riesgo`: antes `consultar_diagnostico`. Solo dueño, con estudianteId explícito en global; devuelve política, señales, evidencias y acciones previas sin el temario completo. `interpretar_contexto` conserva validación de huella/IDs y devuelve esa proyección reducida.
- `gestionar_caso`: listado/detalle del dueño, reporte de un fallo de servicio/acceso desde Mensajería y consulta del estado público propio. El dueño solo recibe la acción CONSULTAR; registra/atiende/resuelve por la aplicación. El participante ve su reporte original, no descripción/resolución internas. Cobertura: hasta 50 reportes propios recientes, paginados. Las decisiones especiales pertenecen a consultas al dueño.
- `gestionar_consulta_dueno`: una sola entrada para solicitar una decisión (participante) o comunicarla (dueño global); el esquema cambia con el rol. Conserva el origen del reporte en Mensajería. Preguntas idénticas pendientes desde Academia se reutilizan; una solicitud de no contacto idéntica también se reutiliza aunque haya sido atendida.
- `enviar_mensaje_local`: extraída de `operar_plataforma`, requiere petición del dueño y rol de destinatario explícito. Conserva validaciones de servicio, seguimiento, plan, no contacto y autorización. La respuesta ordinaria del participante se publica por su canal sin usar esta herramienta.
- `registrar_no_contacto`: petición expresa del participante. Conserva la semántica existente del bloqueo proactivo por alumno, sin desactivar acceso ni renovar/cancelar una contratación.
- `consultar_indicadores`, `consultar_reglas`, `proponer_intervencion`: mantienen su propósito; propuestas e interpretación permiten ID explícito en global y alumno fijado en individual. El modelo no aprueba/aplica propuestas ni edita políticas.

Se retiraron del catálogo `operar_plataforma`, `consultar_base`, `consultar_diagnostico` y la comprobación técnica `comprobar_conexion`. El cálculo, los repositorios y las validaciones existentes se reutilizan. Compartir una fuente entre una lectura general y un diagnóstico especializado no cambia la definición de ese diagnóstico: no reconstruir KPI/riesgo desde una fórmula improvisada.

## Consultas generales de solo lectura

`consultar_datos_negocio` está reservada al Dashboard del dueño y tiene dos operaciones:

1. CATALOGO, sin tabla: enumera las tablas de negocio permitidas. Con tabla, devuelve columnas/tipos y claves foráneas.
2. CONSULTAR: elige tabla y alias, columnas, relaciones, filtros, agrupaciones y medidas. Los nombres se resuelven contra el catálogo validado del servidor; los valores se parametrizan. Las relaciones son LEFT JOIN por una clave foránea existente, incluidas sus columnas cuando es compuesta. No admite expresiones o SQL libre.

Ejemplo de conteo:

~~~json
{
  "accion": "CONSULTAR",
  "tabla": "Estudiante",
  "alias": "e",
  "agruparPor": ["e.EtapaActual"],
  "medidas": [{ "operacion": "CONTAR", "alias": "cantidad" }]
}
~~~

El constructor admite hasta cuatro relaciones, dieciséis filtros, cuatro medidas y cien filas por página. Devuelve total, página siguiente, tablas fuente y corte SQL peruano. Los conteos de personas después de unir varios registros deben usar CONTAR_DISTINTOS. Sumas/promedios solo aceptan campos numéricos. Los historiales contienen filas anteriores, no cierres mensuales reconstruidos. No hay caché de resultados de negocio.

La lista cerrada de tablas de `catalogo-negocio.ts` procede del esquema canónico. No se amplía automáticamente si aparece una tabla nueva. La conexión lectora usa `lapredigital_reader` y un pool separado, sin fallback a la cuenta de escrituras. El aprovisionamiento solo modifica login/usuario/permisos, no el esquema ni los datos del modelo. Timeout SQL: cinco segundos; no busca otras bases ni expone credenciales.

En desarrollo, `lectura.ts` puede obtener únicamente las dos credenciales lectoras adicionales de `/workspace/.env` si no estaban presentes al arrancar el proceso. Permite habilitarlas conservando el llavero abierto. En el runtime compilado, inyectarlas por Compose; no se empaqueta .env.

## Contexto y tono

Las instrucciones están separadas en base, conocimiento institucional y modo. El participante recibe por turno nombre del interlocutor/estudiante, plan/prestaciones y los doce mensajes públicos más recientes de su canal, sin confirmar entrega. La lectura del hilo está acotada en SQL y no mezcla estudiante/apoderado ni Academia/Mensajería. Ese contenido se incorpora como datos, no como instrucciones privilegiadas. Cada herramienta revalida el acceso, incluidas prestación de apoderado e identidad vinculada cuando el canal suministra contactoId.

Los informes académicos ya no arrastran todo el temario y las conversaciones. El riesgo mantiene sus evidencias para interpretar sin exponerlas al participante. Las sesiones e historiales existentes se conservan.

Se eliminaron los cierres defensivos obligatorios. El agente comunica el resultado en lenguaje natural y explica límites que afecten a la pregunta: una prueba sin envío no equivale a un mensaje entregado. No hay cambios en proveedores externos, permisos de contacto, aprobaciones ni semántica de simulaciones.

Registro de dificultades desde el chat, biblioteca de materiales, cambios de objetivos, integración de narrativas locales en señales persistidas y toma exclusiva de la conversación por personal siguen fuera de este cambio.
