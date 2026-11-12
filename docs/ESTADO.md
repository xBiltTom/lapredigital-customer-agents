# Estado y continuidad

Actualizado: 12/11/2026. Instrucción vigente: terminar un MVP local en una sola pasada de máximo una hora; reemplaza el plan individual B02–B08.

## Resultado

M01 (5ae8bde): diagnóstico SQL, reglas, interpretación de narrativas por el modelo y propuestas transaccionales.
M02 (f46fd2f): panel React/Vite, chat real, evidencias y aprobación/simulación.
M03: imagen compilada, comprobaciones y runbook; consultar su hash en git log después del commit.

No continuar automáticamente con extensiones: usar la demo y atender los cambios que pida el usuario. Leer README para arrancar; .env de este equipo ya existe y no debe sobrescribirse.

## Servicios y acceso

- SQL Server 2022 en sql-server-local, base LaPreDigital_Customers, America/Lima.
- Eve abierto por el usuario mediante scripts/chat-local, con llavero desbloqueado y modelo ready.
- Panel de desarrollo en http://localhost:5173, proxy al proceso de Eve; scripts/start detecta ese proceso y excluye el backend de pruebas.
- scripts/open-panel abre el acceso del dueño sin imprimir el token. Token en .env privado (600), solo sessionStorage en navegador.
- Imagen compilada probada en http://localhost:3010. SQL/API/UI funcionan; el modelo requiere desbloquear el llavero dentro de ese proceso. No se verificó ese desbloqueo en modo compilado.
- .eve y keyring_state son privados/persistentes, fuera de Git. No reiniciar la terminal con modelo ni reinstalar npm sin necesidad.

## Funcionalidad y controles

El backend verifica el dueño activo en SQL y fija al alumno en la dirección de conversación; las tools no aceptan otro estudiante. Sin SQL libre, bash o archivos generales para el modelo. Los comentarios/mensajes se consideran datos no confiables.

Cumplimiento: ruta vigente, 30 días, sin canceladas, mismo conjunto para numerador/denominador. Mejora: primero y último cronológicos de cada grupo comparable, expresada en pp. Sin tareas/pruebas: no aplicable/sin datos.

Riesgo: umbrales exactos 72/168 y >48/>96 horas, apertura original para reabiertas, dificultad, intención explícita y valoración 1–2 con contexto. Prevalece ALTO conocido; datos incompletos no se fuerzan a BAJO. La clasificación estructurada preexistente no se usa como cálculo actual; se muestra su vigencia temporal.

El modelo registra interpretación con IDs y huella de mensajes/valoraciones. Cambiar esas fuentes invalida el contexto. Cache separada por nombre de base; narrativas ambiguas quedan pendientes. No se inventan caducidad de intención ni frecuencia de contacto.

Evaluación/señales/propuesta/evento se escriben en transacción con bloqueo por alumno. Se revalidan fuentes, nivel, dueño, plan y autorizaciones; deduplicación persistente por operación de negocio. Antes de aprobar/simular se vuelve a comprobar la evaluación y sus fuentes; cambio de propietario/fecha/contenido/estado o contradicción bloquea.

Solo API del dueño aprueba/rechaza/simula. El modelo solo propone. Simular requiere aprobación, deja resultado SIMULACION LOCAL y MensajeSeguimientoId NULL; no crea Mensaje ni acredita C-4. No se tocan pagos, etapas, precios ni rutas.

Permisos operativos en infra/sql/mvp-permissions.sql: SELECT de fuentes, INSERT de evaluación/señales/eventos y INSERT/UPDATE de intervención. Sin sa, DDL o UPDATE de datos académicos para la app. scripts/grant-mvp aplicó esos permisos; no cambió el esquema.

## Verificación realmente ejecutada

- Tipos y 14 pruebas node:test correctos: configuración, auth, paginación, umbrales exactos, vigencia, rutas y comparabilidad.
- Builds web y Eve completos dentro de Docker, sin EXDEV; artefactos en .eve/packaged y apps/web/.dist.
- SQL activo leído: Ana +15 pp, Carla -25 pp/ALTO, Diego no comparable/ALTO, Gabriela pendiente/no aplicable, Hugo evaluación vencida.
- Base aislada LaPreDigital_Customers_MvpTest recreada por scripts/test-mvp: evidencia ajena, bloqueo de Inés, rollback tras fallo intermedio, deduplicación, aprobación previa, simulación sin nuevos mensajes y reintento idempotente. Correcto.
- Playwright Chromium real: login, selección, escritorio 1440 y móvil 390 sin overflow ni errores JS; propuesta → aprobación → simulación por UI apuntando a SQL aislado. Capturas inspeccionadas en tmp/mvp-*.png.
- Chat real de Carla vía /api/chat: consultar_diagnostico + interpretar_contexto, explicación de -25 pp y ALTO. Sesión wrun_01M78QHM0MNTD5V2154X6Q51QP.
- Chat real de Gabriela desde navegador: pendiente con consultar_diagnostico; captura tmp/mvp-chat-real.png.
- Chat real de Inés: ambas herramientas, petición no contacto reconocida (Mensaje 10), servicio conservado y POST de seguimiento rechazado con 409.
- Imagen compilada: build y salud; / público 200; API anónima 401; listado/ficha del dueño 200. Se revisaron 193 artefactos sin contraseña SQL ni token de acceso.
- Hora: GETDATE textual y Date del driver coinciden con Perú; API devuelve offset -05:00.
- Sin envío real, sin MiniMax ni llamadas de modelo en pruebas automáticas.

## Base y antecedentes

Cuatro SQL canónicos conservados. No se recreó ni pobló el OLTP activo; solo la base de prueba. La carga original contiene 14 estudiantes, 501 registros operativos y 39 históricos. Los datos envejecen desde GETDATE de la carga.

Los 29 casos anteriores (24 OK/5 HALLAZGO) no se reejecutaron sobre la base activa en esta entrega. Los cinco huecos del esquema siguen descritos en CONTEXTO.md; las operaciones de la app añaden validaciones, sin proteger cualquier SQL directo.

B01 (795aad2) verificó login y herramienta fija, cuenta SQL, dueño y build. T05 Windows y su conexión nativa son antecedentes; no confundir con el entorno CachyOS actual.

## Límites del MVP

Un proceso local, respuesta de chat por turno (sin streaming de tokens), datos operativos actuales y aprobación humana. Sin cierres congelados/DataMarts/KPI oficiales completos, agenda automática, proveedores de comunicación, portal familiar, referidos, cambios de plan o agentes de otras fases.

No se prometen cuotas del modelo, despliegue con suscripción o persistencia del login real tras recreación. La fuente de verdad de negocio es informe 7.1 con decisiones posteriores del usuario. El código Windows se revisó estáticamente; la demo completa y el navegador se ejecutaron en CachyOS.
