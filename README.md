# LaPreDigital · Agente Académico de CUSTOMERS

Proyecto académico de Ingeniería de Sistemas de la Universidad Nacional de Trujillo. El objetivo es acompañar la preparación de estudiantes mediante un agente que consulte su progreso, explique riesgos y proponga acciones compatibles con su servicio.

## Estado actual

La base OLTP y los escenarios ficticios ya existen. La aplicación, el agente y la interfaz todavía no están implementados. Por decisión del usuario se conserva el esquema actual mientras se desarrolla el prototipo local.

Stack acordado: TypeScript, Node.js 24, Eve/Nitro, React/Vite, SQL Server 2022 en Docker, `mssql`, Zod y Vitest. El acceso inicial al modelo será el login local de ChatGPT de Eve, pendiente de comprobar en esta cuenta. MiniMax queda como alternativa si sus créditos son utilizables por API.

## Organización

| Ruta | Contenido |
| --- | --- |
| [database/](database/README.md) | Creación, población, pruebas y consultas del OLTP |
| [docs/reference/](docs/reference/documento_InteligenciaNegocios.pdf) | Informe del negocio, identificado por el usuario como versión 7.1 |
| [docs/database/](docs/database/REVISION_CUSTOMERS.md) | Revisión y verificaciones previas de la base |
| [apps/](apps/README.md) | Ubicación prevista de backend y frontend |
| [packages/](packages/README.md) | Ubicación prevista de contratos compartidos |
| [infra/](infra/README.md) | Alcance de la configuración local pendiente |
| scripts/ | Comprobaciones del workspace |

## Comprobación disponible

```bash
node --version
npm run check
```

El proyecto declara Node 24 en `.nvmrc` y `package.json`. No tiene dependencias instaladas ni comandos `dev`, `build` o pruebas de aplicación todavía. `npm run check` solo revisa la estructura, los enlaces y las reglas básicas del repositorio; no ejecuta SQL ni llama a modelos.

El archivo `.env.example` es una plantilla sin secretos. No contiene una conexión lista para usar: el puerto publicado y el usuario de aplicación requieren verificación y configuración posterior.

## Base de datos

Los scripts se ejecutan en orden 01 → 02; 03 sirve para verificar y 04 para explorar. No ejecutar 01/02 sobre la base actual para arrancar la aplicación. Consultar [las instrucciones de database](database/README.md).

Última verificación SQL documentada: 12 de noviembre de 2026, 29 casos con 24 OK y 5 hallazgos pendientes. Ese resultado es previo a esta organización del repositorio; en esta tarea no se ha reconstruido ni modificado la base.
