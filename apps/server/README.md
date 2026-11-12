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

## Alcance actual

- GET /eve/v1/health responde 200 con ok: true.
- POST /eve/v1/session devuelve 401: auth: [] cierra las sesiones hasta configurar el acceso local en T05.
- agent/agent.ts selecciona chatgpt(), pero no inicia login ni hace llamadas por arrancar o compilar. El modelo efectivo que muestra eve info es configuración; no demuestra acceso a ese modelo.
- defaultTools: false y el manifiesto observado dejan la lista de herramientas vacía. No se ofrece bash, archivos ni SQL al modelo.
- No hay conexión SQL, tareas programadas ni comunicaciones reales. La lógica del Agente Académico está pendiente.

El volumen eve_state conserva apps/server/.eve y es compartido por CLI y servidor. No copiar tokens desde el host ni borrar ese volumen como parte de reinstalar dependencias. T05 debe verificar dónde guarda realmente el login esta versión y probar una respuesta y una herramienta inocua. No se afirma todavía persistencia de autenticación ni compatibilidad de la cuenta.

Eve puede advertir que no tiene proveedor de sandbox al compilar. El build pasa y no existen herramientas que requieran ese proveedor. No montar el socket Docker para eliminar el aviso.

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
