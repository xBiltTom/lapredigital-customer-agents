import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type FormEvent,
} from "react";
import { Chatbot } from "./Chatbot";
import { ChatMarkdown } from "./ChatMarkdown";
import { leerRespuesta } from "./chat-stream";
import { CustomersKpis, type DatosKpi } from "./CustomersKpis";

type Fila = {
  id: number;
  codigo: string;
  nombre: string;
  etapa: string;
  servicioActivo: boolean;
  riesgo: string;
  completados: number;
  total: number;
  incidencias: number;
};
type Consulta = {
  ConsultaId: number;
  EstudianteId: number;
  Rol: string;
  Canal: string;
  Pregunta: string;
  Estado: string;
};
type Linea = { rol: "user" | "agent"; texto: string };

export function Dashboard({
  token,
  onAlumno,
  onBusy,
}: {
  token: string;
  onAlumno: (id: number) => void;
  onBusy: (busy: boolean) => void;
}) {
  const [indicadores, setIndicadores] = useState<DatosKpi | null>(null);
  const finalChat = useRef<HTMLDivElement>(null);
  const [alumnos, setAlumnos] = useState<Fila[]>([]);
  const [consultas, setConsultas] = useState<Consulta[]>([]);
  const [chat, setChat] = useState<Linea[]>([]);
  const [cargandoChat, setCargandoChat] = useState(true);
  const [texto, setTexto] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [respuestas, setRespuestas] = useState<Record<number, string>>({});
  const ciclo = useRef<AbortController | null>(null);
  const pendiente = useRef<Promise<void> | null>(null);

  useEffect(() => {
    onBusy(busy);
    return () => onBusy(false);
  }, [busy, onBusy]);

  useEffect(() => {
    finalChat.current?.scrollIntoView({ block: "nearest" });
  }, [chat, consultas.length]);

  const api = useCallback(
    async (path: string, body?: unknown, signal?: AbortSignal) => {
      const response = await fetch(path, {
        method: body ? "POST" : "GET",
        headers: {
          Authorization: "Bearer " + token,
          "Content-Type": "application/json",
        },
        body: body ? JSON.stringify(body) : undefined,
        signal,
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error);
      return data;
    },
    [token],
  );

  const cargar = useCallback(
    async (releer = false) => {
      const signal = ciclo.current?.signal;
      if (!signal || signal.aborted) return;
      if (pendiente.current) {
        await pendiente.current;
        if (!releer) return;
      }
      if (signal.aborted) return;
      // Polling y refrescos comparten la petición. Tras una acción se relee al terminar.
      const consulta = api("/api/dashboard", undefined, signal)
        .then((data) => {
          if (signal.aborted) return;
          setAlumnos(data.alumnos);
          setConsultas(data.consultas);
          setIndicadores(data.indicadores);
        })
        .catch((cause) => {
          if (!signal.aborted) setError((cause as Error).message);
        })
        .finally(() => {
          if (pendiente.current === consulta) pendiente.current = null;
        });
      pendiente.current = consulta;
      await consulta;
    },
    [api],
  );

  useEffect(() => {
    const controller = new AbortController();
    ciclo.current = controller;
    pendiente.current = null;
    setCargandoChat(true);
    api("/api/dashboard/chat", undefined, controller.signal)
      .then((data) => {
        if (!controller.signal.aborted) setChat(data.mensajes);
      })
      .catch((cause) => {
        if (!controller.signal.aborted) setError(cause.message);
      })
      .finally(() => {
        if (!controller.signal.aborted) setCargandoChat(false);
      });
    void cargar();
    const refrescarVisible = () => {
      if (!document.hidden) void cargar();
    };
    const timer = setInterval(refrescarVisible, 12000);
    document.addEventListener("visibilitychange", refrescarVisible);
    return () => {
      controller.abort();
      if (ciclo.current === controller) ciclo.current = null;
      clearInterval(timer);
      document.removeEventListener("visibilitychange", refrescarVisible);
    };
  }, [api, cargar]);

  async function enviar(event: FormEvent) {
    event.preventDefault();
    if (!texto.trim() || busy || cargandoChat) return;
    const mensaje = texto;
    setTexto("");
    setBusy(true);
    setError("");
    setChat((actual) => [
      ...actual,
      { rol: "user", texto: mensaje },
      { rol: "agent", texto: "" },
    ]);
    try {
      const response = await fetch("/api/chat", {
        method: "POST",
        headers: {
          Authorization: "Bearer " + token,
          "Content-Type": "application/json",
          Accept: "application/x-ndjson",
        },
        body: JSON.stringify({ global: true, mensaje }),
      });
      await leerRespuesta(response, (evento) => {
        if (evento.texto !== undefined) {
          setChat((actual) =>
            actual.map((line, index) =>
              index === actual.length - 1
                ? { ...line, texto: evento.texto! }
                : line,
            ),
          );
        }
      });
      await cargar(true);
    } catch (cause) {
      setError((cause as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function responder(consulta: Consulta) {
    setBusy(true);
    try {
      await api(`/api/consultas/${consulta.ConsultaId}/responder`, {
        texto: respuestas[consulta.ConsultaId],
      });
      await cargar(true);
    } catch (cause) {
      setError((cause as Error).message);
    } finally {
      setBusy(false);
    }
  }

  const pendientes = consultas.filter(
    (consulta) => consulta.Estado === "PENDIENTE",
  );

  return (
    <div className="dashboard">
      <header className="dash-heading">
        <div>
          <p className="eyebrow">LAPREDIGITAL · DIRECCIÓN ACADÉMICA</p>
          <h1>
            Tu academia, de un vistazo<span className="heading-dot">.</span>
          </h1>
          <p className="muted">
            Preparación, acompañamiento y conversaciones en un solo lugar.
          </p>
        </div>
        <div className="actions">
          <a
            className="primary"
            href="http://localhost:5180"
            target="_blank"
            rel="noreferrer"
          >
            Abrir portal ↗
          </a>
        </div>
      </header>
      {error && (
        <p className="error" role="alert">
          {error}
        </p>
      )}
      <div className="metrics">
        <section className="metric">
          <p>
            <span className="metric-icon">◉</span> Estudiantes
          </p>
          <strong>{alumnos.length}</strong>
        </section>
        <section className="metric">
          <p>
            <span className="metric-icon">◎</span> Servicio activo
          </p>
          <strong>
            {alumnos.filter((alumno) => alumno.servicioActivo).length}
          </strong>
        </section>
        <section className="metric">
          <p>
            <span className="metric-icon">↗</span> Requieren atención
          </p>
          <strong>
            {alumnos.filter((alumno) => alumno.riesgo === "ALTO").length}
          </strong>
        </section>
        <section className="metric">
          <p>
            <span className="metric-icon">✦</span> Decisiones pendientes
          </p>
          <strong>{pendientes.length}</strong>
        </section>
      </div>
      {indicadores && <CustomersKpis datos={indicadores} />}
      <div className="dash-grid dashboard-data">
        <section className="card">
          <div className="card-heading">
            <h3>Panorama de estudiantes</h3>
            <button className="secondary" onClick={() => void cargar(true)} disabled={busy}>
              Actualizar
            </button>
          </div>
          <div className="academic-table-wrap">
            <table className="academic-table">
              <thead>
                <tr>
                  <th>Estudiante</th>
                  <th>Riesgo</th>
                  <th>Temario</th>
                  <th>Casos abiertos</th>
                </tr>
              </thead>
              <tbody>
                {alumnos.map((alumno) => (
                  <tr key={alumno.id}>
                    <td className="student-cell">
                      <span className="table-avatar">{alumno.nombre[0]}</span>
                      <button
                        disabled={busy}
                        className="student-link"
                        onClick={() => onAlumno(alumno.id)}
                      >
                        {alumno.nombre.replace(" Demo", "")}
                      </button>
                      <small>
                        {alumno.codigo} · {alumno.etapa}
                      </small>
                    </td>
                    <td>
                      <span className={`pill risk-${alumno.riesgo}`}>
                        {alumno.riesgo}
                      </span>
                    </td>
                    <td>
                      <strong className="progress-label">
                        {alumno.total
                          ? Math.round(
                              (100 * alumno.completados) / alumno.total,
                            )
                          : 0}
                        %
                      </strong>
                      <div className="mini-progress">
                        <i
                          style={{
                            width: `${alumno.total ? (100 * alumno.completados) / alumno.total : 0}%`,
                          }}
                        />
                      </div>
                      <small>
                        {alumno.completados} de {alumno.total} temas
                      </small>
                    </td>
                    <td>{alumno.incidencias}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="muted">
            Avance inicial de demostración; los cambios del portal se registran
            con su origen. Completado no implica dominio académico.
          </p>
        </section>
      </div>
      {pendientes.length > 0 && (
        <section className="card dashboard-queries">
          <div className="card-heading">
            <div>
              <h3>Consultas del agente</h3>
              <p className="muted">
                El agente espera una decisión para continuar el mismo hilo.
              </p>
            </div>
            <span className="pill neutral">
              {pendientes.length} pendiente{pendientes.length === 1 ? "" : "s"}
            </span>
          </div>
          <div className="dashboard-query-list">
            {pendientes.map((consulta) => (
              <article className="dashboard-query" key={consulta.ConsultaId}>
                <div className="dashboard-query-meta">
                  <strong>
                    Estudiante #{consulta.EstudianteId} · {consulta.Rol}
                  </strong>
                  <small>{consulta.Canal}</small>
                </div>
                <p>{consulta.Pregunta}</p>
                <div className="dashboard-query-answer">
                  <textarea
                    aria-label={`Respuesta consulta ${consulta.ConsultaId}`}
                    value={respuestas[consulta.ConsultaId] ?? ""}
                    onChange={(event) =>
                      setRespuestas((actual) => ({
                        ...actual,
                        [consulta.ConsultaId]: event.target.value,
                      }))
                    }
                  />
                  <button
                    className="primary"
                    disabled={busy || !respuestas[consulta.ConsultaId]?.trim()}
                    onClick={() => void responder(consulta)}
                  >
                    Responder y comunicar al interesado
                  </button>
                </div>
              </article>
            ))}
          </div>
        </section>
      )}
      <Chatbot
        title="Asistente de dirección"
        subtitle="CONTEXTO GLOBAL · LAPREDIGITAL"
      >
        <p className="chatbot-intro">
          Consulta el panorama general, coordina seguimiento y atiende
          derivaciones.
        </p>

        <div
          className="global-log chatbot-global-log"
          role="log"
          aria-live="polite"
          data-chat-log
        >
          {cargandoChat && (
            <p className="thinking">Recuperando conversación…</p>
          )}
          {!cargandoChat && !chat.length && (
            <div className="chatbot-empty">
              <span aria-hidden="true">✦</span>
              <p>¿A quién debemos acompañar hoy?</p>
              <small>
                Consulta indicadores, riesgos o decisiones pendientes.
              </small>
            </div>
          )}
          {chat.map((line, index) => (
            <div key={index} className={`chat-message ${line.rol}`}>
              <small>{line.rol === "user" ? "TÚ" : "AGENTE"}</small>
              <ChatMarkdown
                texto={line.texto}
                generando={busy && index === chat.length - 1}
              />
            </div>
          ))}
          {pendientes.map((q) => (
            <div className="notice" key={"chat-consulta-" + q.ConsultaId}>
              <strong>El agente necesita tu decisión · #{q.ConsultaId}</strong>
              <small>
                Estudiante #{q.EstudianteId} · {q.Rol}
              </small>
              <p>{q.Pregunta}</p>
              <textarea
                aria-label={"Decisión en chat para consulta " + q.ConsultaId}
                value={respuestas[q.ConsultaId] ?? ""}
                onChange={(e) =>
                  setRespuestas((prev) => ({
                    ...prev,
                    [q.ConsultaId]: e.target.value,
                  }))
                }
              />
              <button
                className="primary"
                disabled={busy || !respuestas[q.ConsultaId]?.trim()}
                onClick={() => void responder(q)}
              >
                Responder al agente y comunicar
              </button>
            </div>
          ))}
          <div ref={finalChat} />
        </div>
        {busy && <p className="thinking">El agente está trabajando…</p>}
        <form className="chat-form chatbot-chat-form" onSubmit={enviar}>
          <textarea
            aria-label="Mensaje al asistente de dirección"
            disabled={cargandoChat || busy}
            value={texto}
            onChange={(event) => setTexto(event.target.value)}
            placeholder="¿A quién debemos acompañar hoy?"
            maxLength={2000}
          />
          <button
            className="send"
            aria-label="Enviar mensaje"
            disabled={busy || cargandoChat || !texto.trim()}
          >
            ↑
          </button>
        </form>
      </Chatbot>
    </div>
  );
}
