# Estado y punto de continuación

Actualizado: 12 de noviembre de 2026. Documento de traspaso para otra sesión o agente.

## Próxima tarea

**T03 del [roadmap](ROADMAP.md): preparar y verificar Node 24.** Después, T04 crea el servidor mínimo y T05 verifica el login local de ChatGPT. No comenzar por instalar un stack diferente ni modificar el esquema SQL.

## Trabajo completado en esta inicialización

- T00: repositorio Git inicializado en main con los archivos originales; origin configurado a git@github.com:xBiltTom/lapredigital-customer-agents.git. El remoto existía y estaba vacío al comprobarlo.
- T01: archivos organizados, configuración npm/editor/Git y comprobación del workspace. Los seis archivos originales se movieron sin cambiar sus bytes, incluidas las consultas personales recientes del 04.
- T02: roadmap con tareas por commit, contexto, arquitectura, instrucciones para agentes y punto de continuación.

Commits previos identificables: T00 = 513d0c9; T01 = 9059457. El hash de T02 y el estado de publicación se consultan en `git log -3 --oneline`, `git status -sb` y `git branch -vv`; no se escribe el hash de un commit dentro de sí mismo.

## Qué existe y qué falta

Existe la base OLTP, sus scripts y este repositorio organizado. No existe todavía apps/server ni apps/web, no se han instalado Eve/React/mssql, no hay agente de negocio implementado ni autenticación de modelo probada. npm run check es la única comprobación de aplicación disponible y revisa estructura/enlaces, no comportamiento funcional.

En el host se observaron Node v26.13.1 y npm 12.2.2. El proyecto declara Node 24 en .nvmrc y engines. La comprobación estructural puede ejecutarse con el Node actual, pero no equivale a haber validado el runtime acordado.

## Validación de esta tarea

- Lectura del esquema/scripts, informe previo de validación y consultas actuales.
- git ls-remote respondió correctamente sobre el origen y no devolvió refs al inicio.
- Comparación byte por byte de los seis originales con T00 después de moverlos.
- Comprobación del workspace, enlaces Markdown locales, exclusiones de secretos y git diff --check.
- No se ejecutaron scripts SQL ni se modificó o reinició el contenedor en esta inicialización.
- El resultado de 29 pruebas SQL (24 OK/5 HALLAZGO), los 20 bloques y DBCC sin infracciones son verificaciones históricas de la revisión anterior. Las consultas añadidas después por el usuario no se declaran revalidadas.

## Pendientes reales

1. Node 24 y dependencias de aplicación.
2. Confirmar el plan de ChatGPT y probar /login con la versión instalada de Eve.
3. Confirmar si los 2.000 créditos MiniMax son de API o de su aplicación; no consumirlos todavía.
4. Comprobar el puerto SQL publicado y configurar el usuario de aplicación. Los datos de .env.example son plantilla, no conexión ya provisionada.
5. Implementar política de contacto con aceptación inicial de términos y revocación posterior; el texto de términos y el registro público de usuarios no están implementados.
6. Cubrir en servicios los cinco huecos conocidos, manteniendo el esquema actual.

## Cómo actualizar este archivo después de una tarea

Indicar la tarea completada, qué se cambió, comandos/pruebas realmente ejecutados y resultado, qué no pudo verificarse y por qué, y el siguiente ID concreto con sus dependencias. Actualizar también su casilla/estado en ROADMAP.md y hacer un único commit de esa tarea. Conservar los hechos de negocio en CONTEXTO.md y las decisiones de diseño en ARQUITECTURA.md.
