# Cómo seguir el código del backend

El flujo habitual tiene cuatro pasos:

1. `agent/channels/` recibe la petición HTTP y valida la identidad.
2. `agent/tools/` define lo que el agente puede pedir, con entradas Zod.
3. `lib/servicios/` o `lib/academico/` comprueba permisos y reglas, consulta SQL y prepara la respuesta.
4. `lib/database/` conecta con SQL Server; `database/consultas/` contiene las consultas largas con nombres descriptivos.

## Dónde buscar

| Carpeta/archivo | Responsabilidad |
| --- | --- |
| `config.ts` | Variables de entorno y validación de configuración. |
| `seguridad/auth.ts` | Autenticación del dueño y de la terminal local. |
| `seguridad/identidad.ts` | Identidad de peticiones y herramientas; separación del participante. |
| `academico/reglas.ts` | Cálculos puros: riesgo, vigencia, cumplimiento y comparabilidad. |
| `academico/diagnostico.ts` | Combina fuentes y reglas para explicar el estado del alumno. |
| `academico/intervenciones.ts` | Propuestas, aprobación y simulación dentro de transacciones. |
| `servicios/consultas.ts` | Lectura flexible del agente: identidad → recurso → filtros → parámetros SQL. |
| `servicios/plataforma.ts` | Resumen global, temario, destinatarios, mensajes y consultas al dueño. |
| `servicios/indicadores.ts` | Convierte numeradores/denominadores en KPI y semáforos. |
| `conversaciones/historial.ts` | Recupera mensajes públicos guardados en las sesiones de Eve. |
| `database/estudiantes.ts` | Repositorio de ficha, suscripciones, periodos y prestaciones. |
| `database/identidad.ts` | Comprueba en SQL que el dueño sigue activo. |
| `database/pool.ts` | Reutiliza la conexión SQL del proceso. |
| `database/consultas/` | SELECT y escrituras del canal local, separados de su validación. |

## Ejemplos de lectura

Para entender **«¿cuánto fue mi último pago?»**, empieza en `agent/tools/consultar_base.ts`, sigue a `servicios/consultas.ts` y mira la proyección `PAGOS` en `database/consultas/recursos.ts`. El servicio fija al alumno autorizado, añade filtros y pasa los valores con `.input(...)`. La consulta no recibe SQL escrito por el modelo.

Para entender **los KPI**, abre `servicios/indicadores.ts` y `database/consultas/indicadores.ts`: una consulta devuelve el corte y cuatro resultados, en el mismo orden que las definiciones de C-2.1, C-2.2, C-2.3 y C-6.1.

Para entender **el riesgo**, lee primero las funciones pequeñas de `academico/reglas.ts`, después el armado de señales en `academico/diagnostico.ts`. El orden de los SELECT del diagnóstico corresponde al orden de sus `recordsets`.

Las escrituras de intervenciones conservan su transacción y revalidaciones en `academico/intervenciones.ts`. Sus consultas permanecen cerca de esas validaciones para leer cada operación completa. No se añadieron ORM, migraciones ni reglas nuevas en esta reorganización.

## Administración con Prisma

`agent/channels/admin.ts` valida el acceso del dueño y llama a `administracion/`:

- `personas.ts`: perfiles y vínculo estudiante/apoderado; al cambiar objetivo o fecha solicita revisión de la ruta vigente.
- `catalogo.ts`: cursos/temario, recursos y lectura de planes, suscripciones, periodos y pagos.
- `academico.ts`: publicación de versiones, actividades y ciclo de atención de casos.

`database/prisma.ts` reutiliza un cliente por proceso. `prisma/schema.prisma` mapea únicamente los campos que usa administración; **no sustituye** `database/01_crear_customers.sql`. No ejecutar `db push` ni `migrate` con este mapa parcial. Generar el cliente con `npm run prisma:generate --workspace=@lapredigital/server` dentro de Docker; arranque y build lo hacen automáticamente.

Usamos `findMany`, `count`, `create` y `updateMany` para las operaciones sencillas. `updateMany` conserva los triggers de SQL Server evitando `OUTPUT` directo; los INSERT con triggers usan `createMany` o SQL parametrizado. Los pocos bloques `$executeRaw` conservan `GETDATE()` y las operaciones relacionadas dentro de una transacción. La creación de casos captura el ID con `OUTPUT INTO` en la misma sentencia, sin consultar el último ID global.

Prisma representa la hora SQL sin zona en los campos Date del cliente con `useUTC: true`, para que leer y volver a escribir no desplace la hora. **La base sigue guardando hora peruana**, obtenida con GETDATE. Las pantallas administrativas muestran fechas de calendario directamente. El driver mssql existente conserva `useUTC: false` y su conversión anterior.

Los KPI y herramientas actuales mantienen sus consultas SQL parametrizadas; no se reescribieron consultas complejas solo por cambiar de tecnología. Los nuevos endpoints administrativos no se exponen como herramientas al agente ni al participante.

`conversaciones/archivo.ts` mantiene un índice privado de sesiones por dirección del chat en el volumen de Eve. El historial incluye sesiones archivadas; no depende exclusivamente de `resolveSession`. Antes de abrir una sesión nueva, el backend recupera y pasa el diálogo público como `history`. Las referencias del runtime anterior se recuperaron una vez con `scripts/recover-chat-history.mjs`, ejecutado desde apps/server dentro de Docker; ese lector de metadatos es específico de Eve rc.10. No borrar `.eve` ni el volumen para reiniciar la interfaz.
