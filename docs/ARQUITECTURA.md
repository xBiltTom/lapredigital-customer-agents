# Arquitectura del MVP

React/Vite en 5173 usa /api mediante proxy hacia Eve/Nitro en 3000. Una imagen compilada sirve el mismo frontend/API en 3010 sin bind mounts de código. SQL Server existente conserva los hechos; el modelo ChatGPT usa el llavero local desbloqueado.

## Dashboard, portal y transporte local

Un solo Eve sirve tres contextos: dueño global, dueño con alumno fijado y participante. El dashboard conserva la dirección dueno:<id>:global en el canal panel. El canal portal mantiene participante:<alumno>:<rol>:<canal>; no comparte su historial con el chat interno del dueño.

El servicio Docker portal reutiliza el frontend React/Vite en 5180 y proxy al mismo backend, con vistas academia/mensajería. Su control local autentica al dueño para emitir acceso firmado de ocho horas ligado a alumno/contacto/rol. Las rutas participantes revalidan vínculo y plan; el agente no dispone del token del dueño como dato de herramientas. Acceso de apoderado exige REPORTES_APODERADO vigente.

TemarioUNT guarda documento y edición; ContenidoUNT guarda los temas con curso/subtemas; ProgresoTemaUNT registra estado/origen e historial anterior. El avance no reemplaza ActividadRuta ni IntentoEvaluacion. El portal genera EventoUso de estudio y el dashboard distingue sus métricas.

MensajeCanalLocal separa el transporte del ledger de proveedores externos. La herramienta valida permisos de PLATAFORMA y finalidad, plan, narrativas y no contacto. La bandeja confirma entrega al leer; el contexto del agente no confirma entrega. ConsultaDueno conecta una duda del participante con el dashboard. Responder por tarjeta o herramienta comunica una decisión autorizada en la conversación del participante.

## Identidad

Bearer local del dueño resuelto a PersonalInterno con Rol N'DUEÑO' y Activo=1. El token no incorpora un contactoId elegido por el cliente y permanece solo en sessionStorage del navegador. Salud pública; datos/acciones protegidos.

Cada conversación del panel se identifica por dueño + alumno + dirección principal estable. El canal pasa ese alumno en auth.attributes y las tools no aceptan un ID diferente. El backend mantiene la autorización en todas sus operaciones.

El acceso interno familiar exige REPORTES_APODERADO vigente; no existe un portal familiar ni autenticación multiusuario de producción.

## Conocimiento del servicio

agent/instructions.md fija identidad, permisos y comportamiento. agent/instructions/10-plataforma.md aporta contexto institucional permanente del informe 7.1: planes, embudo, acompañamiento, indicadores y reglas. Eve carga ambos como instrucciones de sistema, también para sesiones existentes al recargar. El catálogo del informe sirve para explicar; los datos actuales de contratación y efectos de operaciones se verifican mediante herramientas. No se presenta toda la plataforma como simulada; cada resultado conserva su estado verificado.

## Lógica y evidencia

lib/domain.ts calcula umbrales, vigencia, cumplimiento y mejora. lib/diagnostico.ts consulta fuentes parametrizadas con corte GETDATE. Sin tareas/pruebas comparables hay no aplicable/sin datos; pendiente no se fuerza a bajo.

El modelo trata mensajes/comentarios como datos no confiables y propone interpretación con IDs y huella. El backend valida pertenencia y descarta el contexto si cambian las narrativas. Cache privada por base de datos. No se inventan caducidad de intención ni frecuencia de contacto.

Datos operativos actuales; no se reconstruye un cierre mensual histórico a partir de estados mutables.

## Propuestas

lib/propuestas.ts guarda evaluación/señales/intervención/evento dentro de transacción con bloqueo por alumno. Revalida las fuentes, su nivel y pertenencia, el dueño, servicio, plan y permisos. La clave de negocio persistente evita duplicados. Antes de aprobar/simular se comprueba de nuevo la evaluación y sus fuentes.

El modelo solo propone. El dueño aprueba/rechaza/simula por API. Simulación deja MensajeSeguimientoId NULL, resultado explícito y ningún mensaje enviado: no acredita C-4. No hay cobros ni cambios de ruta/plan/etapa.

Permisos acotados: SELECT de fuentes, INSERT de evaluación/señales/eventos e INSERT/UPDATE de intervención. Sin sa ni DDL. Las validaciones de la app no protegen cualquier SQL directo; los cinco huecos del esquema siguen documentados.

## Runtime

Node 24 en Docker, npm workspaces. Build en .eve/packaged conserva staging/output en el mismo almacenamiento. La imagen copia código/artefactos/dependencias y frontend, sin .env o estado privado del host. No hay Next/Nest, Redis, colas o framework propio.

Sesiones/trazas en Eve; llavero cifrado separado y desbloqueado por scripts/chat-local. No se copiaron tokens de Codex. No se afirma intercambio de sesiones entre dev/compilado ni persistencia del login tras recreación.

SQL DATETIME2 y GETDATE peruanos; mssql useUTC:false y Node America/Lima. La API serializa Date con offset -05:00; se comprobó contra la hora textual SQL.

## Verificación y límites

Pruebas de escritura solo en LaPreDigital_Customers_MvpTest. Navegador con UI real y esa API; chats reales verificados aparte para evitar consumo automático.

Un proceso local; POST /api/chat transmite texto y nombres de herramientas por NDJSON sin razonamiento interno. GET /api/estudiantes/:id/chat recupera el historial de la dirección principal desde Eve, validando al dueño y al alumno. El cliente usa Streamdown para Markdown y bloquea imágenes/HTML incrustado. Sin DataMarts/cierres congelados, agenda, KPI oficiales completos, proveedores de comunicación ni extensiones del embudo. La modalidad ChatGPT local no garantiza API/VPS; MiniMax no se consumió.
