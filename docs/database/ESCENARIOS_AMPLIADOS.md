# Escenarios adicionales C015–C030

La base conserva C001–C014 y añade estos 16 estudiantes. Buscar por código, no por ID. Las fechas son relativas al momento de la carga; el riesgo actual se recalcula con las reglas guardadas y puede exigir interpretación narrativa.

| Código | Estudiante | Situación para explorar |
|---|---|---|
| C015 | Valeria Salazar | Diez mensualidades Plus, progreso sostenido, ruta revisada y referente de Renata. |
| C016 | Sebastián Salazar | Hermano de Valeria con el mismo apoderado; menor frecuencia y acompañamiento completado. |
| C017 | Camila Torres | Ocho periodos, diez días sin estudiar, insatisfacción e incidencia de acceso abierta. |
| C018 | Nicolás Mendoza | Actividad frecuente con descenso académico; dificultad, revisión de ruta pendiente e incidencia en atención. |
| C019 | Adriana Aguilar | Apoderado vinculado sin acceso Plus, incidencia resuelta y cambio a Plus aceptado sin aplicar. |
| C020 | Diego Fernández | Semestral contratado dos meses atrás; mejora comparable en álgebra y física. |
| C021 | Luciana Huamán | Beca completa autorizada, tres periodos, sin pagos. |
| C022 | Mateo Castillo | Cinco periodos anteriores; baja al vencer, sin acceso actual. |
| C023 | Renata Vargas | Nueva contratación, primeras actividades y referido fijado al primer pago. |
| C024 | Gabriel Silva | Inactividad, no renovación y revocación de contacto; acceso pagado conservado hasta vencer. |
| C025 | Andrea Cárdenas | Nueve meses, avance alto y apoderado; incidencia reabierta que conserva apertura original. |
| C026 | Bruno Rojas | Plan básico, propuesta de mejora, renovación futura pendiente y pago fallido que no afecta el periodo vigente. |
| C027 | Daniela Sánchez | Baja después de seis periodos; desempeño descendente e historia anterior al vencimiento. |
| C028 | Joaquín Paredes | Dos suscripciones separadas por tres meses; apoderado con consulta pendiente en Dashboard. |
| C029 | Isabella León | Dos periodos semestrales y beca parcial del 50 %, con pagos del saldo. |
| C030 | Emiliano Cruz | Servicio habilitado ayer; sin uso ni pruebas y evaluación pendiente. |

Se amplían catálogos académicos, contrataciones, pagos, actividad/progreso, mensajes, valoraciones, casos, señales, intervenciones, cambios de plan y referidos. Las tablas de historial registran cambios de estado pertinentes. Los planes, prestaciones y reglas configuradas conservan su significado; no se duplican para aumentar artificialmente el conteo.

La carga inicial y la ampliación están en `database/02_poblar_customers.sql`. `scripts/poblar-ampliacion` extrae y aplica únicamente el bloque adicional. Si ya existen los 16 códigos, no vuelve a insertarlos; si encuentra una carga parcial, se detiene para evitar mezclar personas.
