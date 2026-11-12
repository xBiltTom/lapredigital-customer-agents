# Backend mínimo de Eve (T04)

Node 24 en Docker, Eve **1.0.0-rc.10**, AI SDK **7.0.137**, Zod **4.6.7**. Las versiones directas y transitivas están fijadas en el package-lock.json raíz. Eve es una versión candidata; cualquier actualización requiere verificar compatibilidad.

Desde la raíz del repositorio:

```bash
./scripts/dev npm ci
./scripts/dev npm run typecheck
./scripts/dev npm run build:server
docker compose up --build -d server
curl http://127.0.0.1:3000/eve/v1/health
docker compose logs --tail 40 server
docker compose stop server
```

Detener el servidor antes de repetir npm ci. Si tu UID/GID difiere de 1000, exportar LOCAL_UID y LOCAL_GID como explica [infraestructura](../../infra/README.md).

`dev:server` ejecuta Eve sin UI ni extensiones predeterminadas. `build:server` compila con Eve y `start:server` inicia el resultado compilado; este último debe ejecutarse desde el mismo volumen de estado donde se hizo el build, con el servicio dev detenido. El servidor solo se publica en 127.0.0.1:3000. Todavía no existe frontend.

`lib/config.ts` valida al cargar el agente `TZ=America/Lima` y `AI_PROVIDER=chatgpt`. Compose suministra ambos valores; `.env.example` es una referencia y no se carga automáticamente. Para comprobar la configuración sin invocar al modelo: `./scripts/dev npm test --workspace=@lapredigital/server`. En un host Windows con el volumen `.eve` separado, `build:server` puede fallar con EXDEV al mover el resultado a `.output`; el servidor de desarrollo sí pasó el chequeo de salud. El build correcto queda pendiente de resolver.

## Alcance actual

- GET /eve/v1/health responde 200 con ok: true.
- POST /eve/v1/session devuelve 401: auth: [] cierra las sesiones hasta configurar el acceso local en T05.
- agent/agent.ts selecciona chatgpt(), pero no inicia login ni hace llamadas por arrancar o compilar. El modelo efectivo que muestra eve info es configuración; no demuestra acceso a ese modelo.
- defaultTools: false y el manifiesto observado dejan la lista de herramientas vacía. No se ofrece bash, archivos ni SQL al modelo.
- No hay conexión SQL, tareas programadas ni comunicaciones reales. La lógica del Agente Académico está pendiente.

El volumen eve_state conserva apps/server/.eve y es compartido por CLI y servidor. No copiar tokens desde el host ni borrar ese volumen como parte de reinstalar dependencias. Según la documentación instalada, `/login` guarda OAuth/credenciales en el almacén de secretos del sistema: la persistencia real de ese almacén dentro de Docker y la compatibilidad de la cuenta requieren prueba interactiva en T05. No se ha probado ninguna respuesta ni herramienta con el modelo.

Eve puede advertir que no tiene proveedor de sandbox al compilar. No existen herramientas que requieran ese proveedor; el fallo EXDEV descrito arriba es independiente del aviso. No montar el socket Docker para eliminarlo.

## Documentación usada de la versión instalada

Dentro del contenedor, desde /workspace:

- node_modules/eve/docs/README.md
- node_modules/eve/docs/getting-started.mdx
- node_modules/eve/docs/agent-config.md
- node_modules/eve/docs/concepts/built-in-tools.md
- node_modules/eve/docs/guides/auth-and-route-protection.md
- node_modules/eve/docs/guides/deployment/self-hosting/index.md
- node_modules/eve/docs/reference/cli/index.md

Para inspeccionar la configuración sin invocar al modelo: `./scripts/dev sh -ec 'cd apps/server; ../../node_modules/.bin/eve info --json'`. El diagnóstico se ejecutó sin errores ni advertencias. Los comandos de compilación/tipos y salud son verificaciones técnicas; no validan reglas del negocio ni autenticación.
