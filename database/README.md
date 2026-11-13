# Base OLTP de CUSTOMERS

Estos cuatro archivos se trasladaron desde la raíz conservando exactamente sus bytes, incluidas las consultas añadidas por el usuario al archivo 04.

| Archivo | Función |
| --- | --- |
| [01_crear_customers.sql](01_crear_customers.sql) | Definiciones finales de tablas, índices, restricciones e historiales |
| [02_poblar_customers.sql](02_poblar_customers.sql) | Carga ficticia transaccional y consultas de exploración |
| [03_pruebas_customers.sql](03_pruebas_customers.sql) | Pruebas con ROLLBACK; conserva los cinco hallazgos conocidos |
| [04_consultas_customers.sql](04_consultas_customers.sql) | Campo de experimentación y consultas personales del usuario |

## Conexión existente

- Contenedor histórico en CachyOS: `sql-server-local`. En Windows T07 encontró el servicio local `MSSQLSERVER`, no un contenedor SQL.
- Base: `LaPreDigital_Customers`.
- Motor histórico: SQL Server 2022 Developer en Docker, sobre CachyOS. La instancia actual es SQL Server nativo de Windows, accesible desde Docker Desktop por `host.docker.internal:1433`.
- Hora del servidor: `America/Lima`; las columnas del negocio usan hora peruana y `GETDATE()`.
- Intercalación: `Latin1_General_100_CI_AS_SC`.
- En T07 la cuenta `lapredigital_app` solo leía `dbo.Estudiante`; T08, M07 y M13–M14 ampliaron permisos acotados de lectura y operaciones del MVP, sin conceder escritura sobre pagos o estudiantes. Su contraseña generada está en `.env` local, excluido de Git.

La aplicación debe conectarse a esa base. Arrancar el agente no debe ejecutar DROP DATABASE, los scripts 01/02 ni ninguna reconstrucción automática.

En Windows se confirmó por consulta que la base tiene 14 estudiantes y GETDATE() usa -05:00. El usuario informó que la creó y pobló allí. En T07 no se ejecutaron 01, 02, 03 ni 04 sobre esta instancia: los resultados anteriores de 29 pruebas siguen siendo históricos.

Verificación posterior en Windows: la instancia nativa SQL Server 2019 Standard ya recibió solo el bloque M07 sobre la base existente, con copia de seguridad verificada. Los cuatro scripts coinciden con Git; se ejecutaron 01/02/03 en una base aislada de vida corta (24 OK, cinco HALLAZGO) y 04 en solo lectura sobre la base activa. El esquema de la base aislada y el activo coincidieron en columnas, restricciones, claves foráneas e índices; el catálogo JSON y los 162 temas coinciden exactamente con 02. Consulte [ESTADO.md](../docs/ESTADO.md) para resultados y límites. No ejecutar 01/02 completos sobre el OLTP activo.

## Ejecución manual

Abrir los archivos en un cliente SQL conectado a la instancia correcta, respetando `GO`. Para una base nueva se ejecuta primero 01 y luego 02. No son migraciones; 02 rechaza una base con datos y 01 no es idempotente para las tablas. Cualquier reconstrucción se limita a la base académica y requiere una instrucción actual que la autorice.

03 puede adelantar IDENTITY aunque revierta sus operaciones. 04 debe ejecutarse por bloques: el usuario añadió consultas propias y sus resultados o sintaxis completos no se han revalidado en esta tarea. Sus fechas relativas envejecen; no interpretar un resultado distinto meses después como una regresión automática.

## Congelación del modelo

El usuario decidió conservar la base por tiempo. Trabajar primero en el backend y sus validaciones. Si una limitación impide un caso concreto, documentar la evidencia y discutir el ajuste. Si se acuerda modificar tablas, actualizar directamente 01 y sincronizar 02, historiales, triggers, 03 y consultas afectadas.

La fecha de ingreso a LEAD se obtiene del primer formulario válido; se retiró la columna redundante de alta de Contacto. Se mantiene FechaRegistro para la inserción técnica. Las versiones anteriores se guardan en tablas normales Historial con triggers explícitos, no con temporal tables.

Ver [la revisión previa](../docs/database/REVISION_CUSTOMERS.md) y [el informe](../docs/reference/documento_InteligenciaNegocios.pdf).
