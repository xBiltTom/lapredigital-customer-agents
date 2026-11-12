# Arquitectura acordada para el prototipo local

## Recorrido

```text
React/Vite (apps/web)
        |
        | API del panel y cliente de Eve
        v
Eve/Nitro sobre Node 24 (apps/server)
        |-- configuración y contexto de identidad validados
        |-- repositorios mssql con SQL parametrizado
        |-- servicios con reglas, permisos y transacciones
        |-- herramientas concretas del Agente Académico
        |-- simulador de comunicación
        |
        +--> SQL Server existente: LaPreDigital_Customers
        +--> ChatGPT mediante login local de Eve (pendiente de prueba)
        +--> persistencia local de sesiones/trazas fuera de Git
```

Eve es la arquitectura elegida, no una implementación ya instalada. Su servidor se basa en Nitro; Node ejecuta el programa y TypeScript es el lenguaje. No se acordó Next.js ni NestJS. Una sola instancia local es suficiente para el MVP; no se añaden Redis, colas distribuidas, vector DB ni un segundo motor de negocio sin una necesidad demostrada.

## Organización prevista del código

- apps/server: aplicación npm del backend. Dentro, agent/ contiene instrucciones/tools, y lib/ (o la estructura documentada por la versión instalada) contiene database/, domain/ y services/.
- apps/web: aplicación npm React/Vite.
- packages/contracts: esquemas/tipos compartidos cuando tengan consumidores en ambas apps.
- database: fuentes canónicas de la base actual y el laboratorio SQL.
- infra: configuración local documentada; scripts de arranque nunca reconstruyen datos.

No fijar todavía rutas internas de Nitro ni APIs de Eve desde memoria. Leer docs instaladas y adaptar el montaje web, proxy y flujo de autenticación a la versión fijada en el lockfile.

## Aislamiento y portabilidad

Por instrucción posterior del usuario, Node/npm se ejecutan en Docker mediante scripts/dev. El host no necesita el runtime del proyecto. Compose conserva dependencias Linux y caché en volúmenes y monta código para desarrollo; el usuario del contenedor coincide con UID/GID del host. La imagen base se fija por digest y conserva America/Lima.

Este empaquetado de desarrollo precede a las imágenes de runtime para VPS: los builds y artefactos se definirán con la aplicación real. SQL Server continúa en su contenedor existente y no se recrea desde Compose. Su conectividad se configura en T07. No montar el socket Docker ni credenciales del host en el agente de negocio.

## Qué calcula el código y qué interpreta la IA

El backend calcula cumplimiento, porcentajes, comparabilidad, horas exactas, antigüedad, vigencia y precedencia de riesgo. El modelo interpreta intención y satisfacción a partir de narrativas; recomienda refuerzo y redacta explicaciones o mensajes con evidencia. Una respuesta del modelo se valida como datos estructurados y se combina con las reglas; no es autoridad para saltarse un permiso.

La misma capa de servicios se usa desde endpoints, herramientas y trabajos programados. No duplicar la política en un prompt y en otra ruta HTTP con criterios distintos. Los mensajes/comentarios del estudiante son datos no confiables como instrucciones de sistema.

## Herramientas iniciales

consultar_perfil_estudiante, consultar_progreso, consultar_uso, consultar_incidencias, consultar_evidencias y consultar_contacto_y_seguimiento. Después: registrar_evaluacion_con_senales, proponer_intervencion, solicitar_revision_ruta y derivar_atencion_humana.

Cada herramienta valida un esquema de entrada pequeño y el contexto de identidad; consulta solo las columnas necesarias y devuelve IDs de evidencia. No exponer execute_sql, shell o edición de archivos al agente de negocio. El navegador no recibe credenciales de SQL ni del modelo.

## Escrituras y aprobación

- Evaluación y señales: operación atómica validada; conservar evaluaciones anteriores, revalidar referencias antes de escribir.
- Intervención y eventos: transacción y deduplicación por operación de negocio, no por una frase del modelo. El modelo no se autoaprueba.
- La autorización se revalida al ejecutar, aunque la propuesta ya esté aprobada.
- La aceptación de términos origina permisos previstos; la revocación posterior debe respetarse. No inferir aceptación donde no hay evidencia.
- Las rutas solo las publica el dueño. Los casos económicos se derivan; no se crean herramientas de cobro o compensación.
- En simulación no se escribe ENVIADO/ENTREGADO. Una intervención puede tener un resultado de simulación explícito sin acreditar C-4 de comunicación real.

La deduplicación debe sobrevivir al reinicio con estado persistente y validación en SQL. Este diseño se limita inicialmente a un proceso; la protección para varias réplicas exige volver a evaluar garantías. No prometer exactly-once para sistemas externos.

## Persistencia y fechas

SQL Server conserva hechos del negocio; Eve conserva sus sesiones y ejecución en almacenamiento local persistente, excluido de Git. No se asume un adaptador SQL Server para la persistencia interna de Eve: se accede al OLTP mediante mssql desde herramientas propias.

Las fechas de negocio siguen siendo peruanas, con GETDATE en SQL Server. mssql devuelve Date de JavaScript; probar explícitamente su configuración y serialización para evitar introducir un desfase de cinco horas. El contrato HTTP debe documentar cómo representa una fecha peruana sin offset; no convertir silenciosamente las columnas a UTC.

La trazabilidad técnica incluirá operación, corte, versiones, fuentes, acción y resultado. Una referencia a una fila mutable no basta para afirmar que se conserva su contenido original. Las limitaciones del esquema se declaran y se registra el contexto local necesario; los cierres mensuales siguen fuera de alcance hasta un diseño específico.

## Acceso al modelo y alcance económico

La [documentación de Eve](https://eve.dev/docs/agent-config) contempla chatgpt() con login local y limita esa modalidad a desarrollo local. Hay que comprobar la cuenta real antes de prometer su funcionamiento, modelos o cupos. No copiar tokens de Codex/ChatGPT manualmente al repositorio ni implementar un proxy para eludir la modalidad admitida.

MiniMax puede ser alternativo mediante su API compatible si el saldo del usuario es utilizable por API y autoriza su consumo. La clave se guarda fuera de Git. No hay fallback automático a un proveedor de pago ni servicio de nube contratado.

Para los detalles de herramientas, consultar [Eve tools](https://eve.dev/docs/tools); para persistencia, [self-hosting](https://eve.dev/docs/guides/deployment/self-hosting); para SQL, [mssql](https://github.com/tediousjs/node-mssql). El código debe seguir la documentación de las versiones efectivamente instaladas.
