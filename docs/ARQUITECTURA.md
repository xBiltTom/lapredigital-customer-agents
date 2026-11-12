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
        +--> ChatGPT mediante login local de Eve (T05: TUI verificada)
        +--> persistencia local de sesiones/trazas fuera de Git
```

T04 instaló Eve 1.0.0-rc.10, AI SDK 7.0.137 y Zod 4.6.7, fijados en el lockfile raíz. T07/T08 añadieron configuración SQL, pool y repositorios de perfil/servicio; falta el recorrido de negocio del diagrama. R01 compactó la implementación en B01–B08: priorizar servicios pequeños y trazas nativas, sin framework propio de repositorios, roles u observabilidad. Eve es una versión candidata: revisar sus docs instaladas antes de ampliar la integración. Su servidor se basa en Nitro; Node ejecuta el programa y TypeScript es el lenguaje. No se acordó Next.js ni NestJS. Una sola instancia local basta; no se añaden Redis, colas distribuidas, vector DB ni otro motor de negocio sin una necesidad demostrada.

## Organización prevista del código

- apps/server: aplicación npm del backend. Dentro, agent/ contiene instrucciones/tools, y lib/ (o la estructura documentada por la versión instalada) contiene database/, domain/ y services/.
- apps/web: aplicación npm React/Vite.
- packages/contracts: esquemas/tipos compartidos cuando tengan consumidores en ambas apps.
- database: fuentes canónicas de la base actual y el laboratorio SQL.
- infra: configuración local documentada; scripts de arranque nunca reconstruyen datos.

No fijar todavía rutas internas de Nitro ni APIs de Eve desde memoria. Leer docs instaladas y adaptar el montaje web, proxy y flujo de autenticación a la versión fijada en el lockfile.

## Aislamiento y portabilidad

Por instrucción posterior del usuario, Node/npm se ejecutan en Docker mediante scripts/dev. El host no necesita el runtime del proyecto. Compose conserva dependencias Linux y caché en volúmenes y monta código para desarrollo; el usuario del contenedor coincide con UID/GID del host. La imagen base se fija por digest y conserva America/Lima.

Este empaquetado de desarrollo precede a las imágenes de runtime para VPS: los builds y artefactos se definirán con la aplicación real. Compose no administra SQL Server; T07 verificó la instancia local de Windows. No montar el socket Docker ni credenciales del host en el agente de negocio.

T07/T08 añadieron pool diferido y repositorios de perfil/servicio. B01 los verificó en CachyOS con cuenta SQL de lectura y host-gateway; Windows conserva su procedimiento con permisos comunes de infra/sql. La identidad interna permite dueño activo, estudiante propio o apoderado con REPORTES_APODERADO vigente; no se acepta ese objeto desde el cuerpo HTTP. El token local se resuelve al dueño configurado y se revalida en PersonalInterno. No hay sistema completo de usuarios ni portal familiar. B03 integra herramientas concretas; el modelo nunca recibe SQL libre.

El servidor publica solo 127.0.0.1:3000. Canal del dueño con Bearer y permiso allowAgentInfo, sin permitir reemplazo de herramientas. TUI interna admite localDev solo en desarrollo y con el mismo dueño activo; un Bearer incorrecto no tiene esa alternativa. Salud pública. scripts/chat-local inicia D-Bus/llavero interactivo y Eve juntos; el servicio estándar no desbloquea ese llavero. Estado en eve_state, llavero en keyring_state. B01 verificó login, respuesta y herramienta reales por API aquí; persistencia del login tras recreación aún no probada. T05 conserva evidencia Windows. defaultTools: false excluye herramientas generales; no se montó el socket Docker.

B01 compila una copia mínima de fuentes en .eve/packaged, dentro del volumen Docker, para que staging y .output compartan sistema de archivos. Se probaron build y arranque compilado. Desarrollo y compilado tienen raíces de sesiones distintas dentro del volumen; no se afirma intercambio entre modalidades. B08 construirá la imagen final, sin estado privado ni secretos.

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

Las fechas de negocio siguen siendo peruanas, con GETDATE en SQL Server. T07 confirmó offset -05:00 del servidor y configuró `useUTC: false` en `mssql`; queda por probar la serialización de columnas DATETIME2 al exponerlas. El contrato HTTP debe documentar cómo representa una fecha peruana sin offset; no convertir silenciosamente las columnas a UTC.

La trazabilidad técnica incluirá operación, corte, versiones, fuentes, acción y resultado. Una referencia a una fila mutable no basta para afirmar que se conserva su contenido original. Las limitaciones del esquema se declaran y se registra el contexto local necesario; los cierres mensuales siguen fuera de alcance hasta un diseño específico.

## Acceso al modelo y alcance económico

La [documentación de Eve](https://eve.dev/docs/agent-config) contempla chatgpt() con login local y limita esa modalidad a desarrollo local. T05 verificó una llamada real con la suscripción del usuario y el modelo observado `gpt-6-luna-fast`; esto no establece cupos ni viabilidad de despliegue. No copiar tokens de Codex/ChatGPT manualmente al repositorio ni implementar un proxy para eludir la modalidad admitida.

MiniMax puede ser alternativo mediante su API compatible si el saldo del usuario es utilizable por API y autoriza su consumo. La clave se guarda fuera de Git. No hay fallback automático a un proveedor de pago ni servicio de nube contratado.

Para los detalles de herramientas, consultar [Eve tools](https://eve.dev/docs/tools); para persistencia, [self-hosting](https://eve.dev/docs/guides/deployment/self-hosting); para SQL, [mssql](https://github.com/tediousjs/node-mssql). El código debe seguir la documentación de las versiones efectivamente instaladas.
