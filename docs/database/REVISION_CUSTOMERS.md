# Primera ejecución y revisión de CUSTOMERS

Fecha de actualización: 12 de noviembre de 2026, hora de Perú.

La primera versión funciona como entorno de experimentación OLTP. Aún no se considera cerrado el modelo para implementar agentes. Se revisaron los dos scripts y el informe entregado, tomando como referencia las reglas que el usuario identifica como versión 7.1, en especial las transiciones, los planes y las secciones 6.1–6.3 de CUSTOMERS. El PDF se consultó mediante extracción de texto; no se modificó.

## Cambios aplicados

- `01_crear_customers.sql`: unificado el nombre `LaPreDigital_Customers` en DB_ID y CREATE DATABASE; declarada `Latin1_General_100_CI_AS_SC`; activados QUOTED_IDENTIFIER y ANSI_NULLS; unificado el valor `DUEÑO`, escrito como literal Unicode `N'DUEÑO'`, en las restricciones, la población y las comparaciones de los triggers. Las columnas conservan VARCHAR, que admite la ñ con la intercalación acordada.
- `02_poblar_customers.sql`: mismas opciones de sesión; la consulta de mejora incluye customers sin pruebas comparables, con cero intentos y «Sin datos suficientes»; corregidas cuatro autorizaciones de referidos anteriores a su primer formulario válido; los dos mensajes de acompañamiento de Ruta UNT quedan atribuidos a SOPORTE, respetando que ese plan no incluye seguimiento IA. Se agregaron comprobaciones de estas dos últimas condiciones antes del COMMIT.
- `03_pruebas_customers.sql`: 29 casos reproducibles, cada uno dentro de una transacción que se revierte. No realiza envíos externos. Los IDENTITY pueden avanzar pese al ROLLBACK.

La ejecución original de creación falló con el error 1934 por QUOTED_IDENTIFIER al crear el primer índice filtrado. Los otros defectos iniciales se identificaron estáticamente antes de ejecutar la versión corregida. La base parcial creada por esa primera prueba fue eliminada y recreada.

## Verificación por ejecución real

Contenedor `sql-server-local`, imagen SQL Server 2022. Solo se recreó `LaPreDigital_Customers`; las otras bases de la instancia no se modificaron.

La versión final completa de 01, 02, 03 y 04 terminó sin errores. Última reconstrucción verificada: 2026-11-12 07:31:01, hora de Perú. Se recreó únicamente la base académica desde los scripts 01 y 02 sin la columna redundante de alta, conservando el rol `DUEÑO`. Las 29 pruebas dieron 24 OK y los mismos 5 HALLAZGO pendientes. Los 20 bloques de consultas de 04 se ejecutaron correctamente; T14 devolvió los 16 contactos y A06 no informó incoherencias. DBCC CHECKCONSTRAINTS no informó infracciones.

| Comprobación | Resultado |
| --- | --- |
| Tablas operativas / registros | 40 / 501 |
| Tablas de historial / registros | 14 / 39 |
| Estudiantes | 14: 12 CUSTOMER, 1 LEAD y 1 TURNED |
| Triggers activos | 24 |
| Intercalación | Latin1_General_100_CI_AS_SC |
| Hora SQL Server | GETDATE en Perú, offset -05:00 |
| DBCC CHECKCONSTRAINTS | Sin infracciones informadas |
| Repetir población sobre base cargada | Rechazada con 51100, sin duplicar datos |
| Suite de 29 casos | 24 OK y 5 HALLAZGO; cero resultados inesperados |

Los 24 OK comprueban historial de UPDATE y DELETE con varias filas, conservación de Unicode, acceso al desactivar renovación, pago confirmado inmutable, suscripción vigente única, periodos sin superposición, habilitación respaldada por pago, importe correcto, renovación enlazada, beca autorizada por dueño, rutas publicadas por dueño, baja exactamente al vencimiento, fechas de valoración, atribución fija de referido, pertenencia de evidencias y mensajes, rechazo de un lote mixto, beca sin pago, seguimiento C-4 y aceptación sin aplicación. También incluyen comparaciones en los límites de 72/168 y 48/96 horas. Estas últimas validan expresiones horarias; no ejecutan un clasificador, que aún no existe. La prueba 29 comprueba que un reenvío posterior o un formulario inválido anterior no cambian la fecha de ingreso obtenida del primer formulario válido.

Las consultas exploratorias confirmaron Ana 40 % → 55 % = +15 puntos porcentuales; Gabriela con cumplimiento no aplicable y mejora sin datos; Hugo con evaluación vencida; Bruno con C-4 cumplido; Mateo con cambio aceptado sin aplicar; Fabio con beca sin pagos; Elena con renovación continua; Jorge de baja y Lucía reactivada. Son escenarios relativos al momento de carga y envejecen.

## Retiro de FechaAlta (12 de noviembre)

Se revisaron las 54 tablas, sus triggers e historiales, la población, las pruebas, las consultas y los objetos SQL de la base en ejecución para rastrear esta columna. En los 16 contactos de la demo su valor coincidía exactamente con la fecha del primer formulario válido. No sustentaba ningún KPI ni relación estructural; se almacenaba, se copiaba al historial y se usaba en una comprobación de coherencia de la población. No se encontró un evento de negocio distinto que justificara conservarla, de acuerdo con la regla de ingreso a LEAD exclusivamente por formulario válido.

Se eliminó directamente de las definiciones de Contacto y ContactoHistorial y de la copia del trigger. Los 16 INSERT de Contacto en 02 y la prueba de eliminación en 03 se ajustaron. La comprobación 51107 de la demo consulta ahora MIN(FechaEnvio) de formularios válidos, en vez de una copia de esa fecha. No se crearon migraciones con ALTER TABLE.

La fecha de ingreso a LEAD se consulta desde el primer FormularioContacto válido. Contacto.FechaRegistro conserva cuándo se creó el contacto en la base; FormularioContacto.FechaRegistro conserva cuándo se registró ese evento. Si no existe un formulario válido, la fecha de ingreso permanece desconocida: no se sustituye por la fecha técnica de registro. T14 permite observar esta distinción. Se verificó en SQL Server que no quedan columnas ni módulos dependientes de la columna retirada.

## Cinco huecos reproducidos, pendientes de resolver

| Caso en 03 | Operación admitida actualmente | Consecuencia |
| --- | --- | --- |
| 22 | Cambiar evaluación ALTO a BAJO manteniendo sus señales | No se impone la prevalencia del mayor riesgo fuera de la comprobación inicial de carga. |
| 23 | Cambiar a BAJO una señal de insatisfacción | La FK valida la evidencia, pero no que el nivel cumpla la regla del negocio. |
| 24 | Insertar un mensaje como ENVIADO para una conversación cuyo canal/finalidad están denegados | El modelo registra autorizaciones pero no impone su cumplimiento al registrar el envío. La prueba no envía nada. |
| 25 | Cambiar el estudiante de un evento de uso ya usado como evidencia | La validación de SenalRiesgo no se vuelve a ejecutar al modificar su tabla de origen. Se puede romper la trazabilidad después de evaluarla. |
| 26 | Marcar CUSTOMER al LEAD C013 sin servicio habilitado | La etapa y los registros de contratación pueden desincronizarse mediante SQL directo. |

HALLAZGO significa que se reprodujo un problema conocido, no que esa conducta sea correcta. Las pruebas revierten cada modificación. No se han cerrado estos cinco puntos en esta primera iteración: corresponde definir su escritura transaccional y protección antes de declarar estable el modelo. Riesgo y señales se insertan actualmente en sentencias separadas; un control global inmediato sin diseñar ese flujo impediría construir una evaluación válida.

## Hallazgos por revisión estática y límites

- Los 14 historiales conservan los tipos y tamaños de las columnas actuales: comprobado mediante comparación de las definiciones locales. No se reemplazaron por tablas temporales versionadas.
- Las evaluaciones de riesgo y sus señales no tienen historial propio ni inmutabilidad. Sus vínculos permiten consultar el sustento actual; no garantizan conservar el sustento original si se modifica. La prueba 25 demuestra parte del problema.
- Las consultas de 02 y los 20 bloques de 04 son exploratorios del estado actual, no reportes mensuales cerrados. No existe todavía un mecanismo de cierre que congele lo conocido al corte. Fecha del evento y fecha de registro deben distinguirse al tratar datos tardíos. Los historiales existentes por sí solos no congelan todos los KPI.
- El modelo puede almacenar prestaciones y autorizaciones; aún falta proteger globalmente su cumplimiento, el seguimiento previo y la relación estudiante/apoderado al registrar acciones. Los responsables indicados en filas no sustituyen permisos de ejecución del futuro servicio.
- No hay proceso programado que cambie etapa y acceso al vencer un periodo ni que reevalúe riesgo. El transcurso del tiempo no ejecuta triggers. La aplicación deberá coordinar los cambios o invocar una operación transaccional definida para ello.
- La fecha de baja se valida al escribir BajaServicio; modificar después el periodo referido requiere revisar también esa coherencia. Esta dirección inversa no se probó en la suite actual.
- La zona America/Lima está configurada en el contenedor actual mediante /etc/timezone y /etc/localtime. No existe un archivo Docker Compose ni definición de recreación en esta carpeta; la persistencia de esa configuración al reconstruir el contenedor queda sin verificar. Los scripts SQL no configuran la zona horaria del sistema operativo.
- No se midieron concurrencia, bloqueos ni rendimiento a escala. Con 501 registros, la ejecución correcta no demuestra optimización para producción.

## Cómo continuar la experimentación

Ejecutar 01 en una base nueva, después 02 y finalmente 03. Para repetir 02 con fechas nuevas hay que eliminar y recrear únicamente esta base académica; 01 no es una migración ni un script idempotente de tablas. Los tres archivos están preparados para sqlcmd o un editor que respete los separadores GO.

La siguiente iteración debería cerrar primero la clasificación y conservación de evidencias, después el registro autorizado de acciones, y finalmente las transiciones y los cierres. Tras cada cambio de estructura se deben sincronizar 01 y 02, recrear la base y convertir el HALLAZGO correspondiente en una prueba que exija el comportamiento corregido. El sistema de agentes y los DataMarts siguen pendientes, conforme al alcance solicitado.
