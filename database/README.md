# Base OLTP de CUSTOMERS

Estos cuatro archivos se trasladaron desde la raíz conservando exactamente sus bytes, incluidas las consultas añadidas por el usuario al archivo 04.

| Archivo | Función |
| --- | --- |
| [01_crear_customers.sql](01_crear_customers.sql) | Definiciones finales de tablas, índices, restricciones e historiales |
| [02_poblar_customers.sql](02_poblar_customers.sql) | Carga ficticia transaccional y consultas de exploración |
| [03_pruebas_customers.sql](03_pruebas_customers.sql) | Pruebas con ROLLBACK; conserva los cinco hallazgos conocidos |
| [04_consultas_customers.sql](04_consultas_customers.sql) | Campo de experimentación y consultas personales del usuario |

## Conexión existente

- Contenedor conocido: `sql-server-local`.
- Base: `LaPreDigital_Customers`.
- Motor: SQL Server 2022 Developer en Docker, sobre CachyOS.
- Hora del servidor: `America/Lima`; las columnas del negocio usan hora peruana y `GETDATE()`.
- Intercalación: `Latin1_General_100_CI_AS_SC`.
- No guardar contraseñas ni asumir que el puerto publicado sigue siendo 1433.

La aplicación debe conectarse a esa base. Arrancar el agente no debe ejecutar DROP DATABASE, los scripts 01/02 ni ninguna reconstrucción automática.

## Ejecución manual

Abrir los archivos en un cliente SQL conectado a la instancia correcta, respetando `GO`. Para una base nueva se ejecuta primero 01 y luego 02. No son migraciones; 02 rechaza una base con datos y 01 no es idempotente para las tablas. Cualquier reconstrucción se limita a la base académica y requiere una instrucción actual que la autorice.

03 puede adelantar IDENTITY aunque revierta sus operaciones. 04 debe ejecutarse por bloques: el usuario añadió consultas propias y sus resultados o sintaxis completos no se han revalidado en esta tarea. Sus fechas relativas envejecen; no interpretar un resultado distinto meses después como una regresión automática.

## Congelación del modelo

El usuario decidió conservar la base por tiempo. Trabajar primero en el backend y sus validaciones. Si una limitación impide un caso concreto, documentar la evidencia y discutir el ajuste. Si se acuerda modificar tablas, actualizar directamente 01 y sincronizar 02, historiales, triggers, 03 y consultas afectadas.

La fecha de ingreso a LEAD se obtiene del primer formulario válido; se retiró la columna redundante de alta de Contacto. Se mantiene FechaRegistro para la inserción técnica. Las versiones anteriores se guardan en tablas normales Historial con triggers explícitos, no con temporal tables.

Ver [la revisión previa](../docs/database/REVISION_CUSTOMERS.md) y [el informe](../docs/reference/documento_InteligenciaNegocios.pdf).
