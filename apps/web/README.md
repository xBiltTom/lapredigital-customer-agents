# Panel React/Vite

Desde la raíz: ./scripts/start y ./scripts/open-panel. El modelo necesita una terminal ./scripts/chat-local con el llavero abierto. URL: http://localhost:5173.

React 19.3.1, Vite 8.3.8 y TypeScript, fijados en lockfile. Sin credenciales SQL ni claves del modelo. Token del dueño solo en sessionStorage, nunca VITE_* incrustado. El proxy apunta al Eve local detectado por scripts/start.

App.tsx gestiona selección, carga, errores y conversación separada por alumno; el chat se renderiza como texto, sin HTML arbitrario. Las respuestas obsoletas no reemplazan otra ficha. La API valida incluso las acciones deshabilitadas en UI.

Build: ./scripts/dev npm run build:web. Resultado .dist, fuera de Git y copiado a la imagen compilada. El backend sirve esos assets sin Vite en 3010.

scripts/test-browser dirige escrituras a SQL aislado. Las pruebas del modelo real son explícitas y separadas; no se ejecutan automáticamente.
