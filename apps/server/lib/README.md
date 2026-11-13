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
