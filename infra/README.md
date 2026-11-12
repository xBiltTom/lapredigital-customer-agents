# Infraestructura local del MVP

## Desarrollo

Docker Engine/Compose, Git y shell POSIX. Node 24.22.3 y npm 11.19.1 en imagen oficial fijada por digest. scripts/dev conserva UID/GID del usuario y ejecuta herramientas en contenedores temporales, con dependencias y caché en volúmenes. No instalar Node global.

scripts/chat-local levanta Eve interactivo con D-Bus/llavero. scripts/start detecta el proceso de Eve y levanta web/proxy sin confundir la API de pruebas. scripts/open-panel abre http://localhost:5173 con el acceso local. Repetir start si se cambia el proceso de Eve.

Contenedores sin privilegios para la app; no se monta Docker del host. La prueba de navegador instala librerías del sistema como root solo en su contenedor temporal, con código de prueba controlado.

## SQL existente

sql-server-local es independiente de Compose; mantiene LaPreDigital_Customers y America/Lima. La aplicación no lo recrea. No ejecutar 01/02 al iniciar.

En CachyOS, scripts/provision-sql-app configuró login de lectura y .env privado; scripts/grant-mvp aplicó permisos adicionales acotados al MVP. host.docker.internal se resuelve mediante host-gateway. Nunca dar sa al modelo ni a la app.

Windows conserva provision-sql-app.ps1 y grant-sql-read.ps1, con permisos básicos comunes en infra/sql/app-read-permissions.sql. Aplicar mvp-permissions.sql aparte como administrador para el MVP. Windows revisado estáticamente; ejecución integral en CachyOS.

Los scripts de integración crean/recrean solo LaPreDigital_Customers_MvpTest; no escriben la base activa. La cuenta de app tiene permisos de datos precisos, no DDL.

## Persistencia

- lapredigital-customers_node_modules: dependencias Linux del workspace.
- lapredigital-customers_npm_cache: caché npm.
- lapredigital-customers_eve_state: sesiones/trazas y compilado de dev.
- lapredigital-customers_keyring_state: llavero cifrado; no borrar al reinstalar npm.
- lapredigital-packaged_runtime_state: estado propio de la imagen compilada.
- SQL conserva sus volúmenes existentes, independientes.

No usar down -v, prune global o borrados de volúmenes como rutina. Conservar .env local y el respaldo de SQL fuera de Git. Para copias/restauración de SQL, usar BACKUP/RESTORE de la instancia existente; no reconstruir los datos mediante seed para sustituir un respaldo. Restauración de backups no se ejecutó en esta entrega.

## Imagen compilada

compose.packaged.yaml construye mvp-runtime con frontend y API en 3010. No monta código del host. Build, salud, autorización y consultas SQL se verificaron.

El modelo por suscripción necesita llavero abierto en el proceso. El README incluye un comando interactivo del modo compilado, aún sin verificar ese desbloqueo. Para la presentación usar la demo verificada con chat-local. No se contrató nube ni se consumió MiniMax.

Actualizar la imagen requiere volver a compilar; no asumir migración automática de sesiones entre versiones/modos. El proyecto es un MVP de una instancia local, no una plataforma distribuida.
