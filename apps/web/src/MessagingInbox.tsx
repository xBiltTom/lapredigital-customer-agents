import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type FormEvent,
} from 'react';
import { ChatMarkdown } from './ChatMarkdown';
import './messaging.css';

type Message = {
  MensajeLocalId: number;
  EstudianteId: number;
  ContactoId: number;
  Rol: 'ESTUDIANTE' | 'APODERADO';
  Direccion: 'ENTRANTE' | 'SALIENTE';
  Contenido: string;
  Fecha: string;
  FechaEntrega: string | null;
};
type Thread = Message & {
  contacto: { NombreCompleto: string; Telefono: string | null };
  estudiante: { Codigo: string; contacto: { NombreCompleto: string } };
};
const key = (m: Message) => `${m.EstudianteId}/${m.ContactoId}/${m.Rol}`;
const nombre = (t: Thread) => t.contacto.NombreCompleto.replace(' Demo', '');
const hora = (s: string) =>
  new Date(s).toLocaleTimeString('es-PE', {
    timeZone: 'America/Lima',
    hour: '2-digit',
    minute: '2-digit',
  });
const dia = (s: string) =>
  new Date(s).toLocaleDateString('es-PE', {
    timeZone: 'America/Lima',
    day: 'numeric',
    month: 'short',
  });
function unir(anteriores: Message[], nuevos: Message[]) {
  return [
    ...new Map(
      [...anteriores, ...nuevos].map((m) => [m.MensajeLocalId, m]),
    ).values(),
  ].sort((a, b) => a.MensajeLocalId - b.MensajeLocalId);
}

export function MessagingInbox({
  token,
  onBusy,
}: {
  token: string;
  onBusy: (busy: boolean) => void;
}) {
  const [hilos, setHilos] = useState<Thread[]>([]),
    [seleccion, setSeleccion] = useState<string | null>(null),
    [mensajes, setMensajes] = useState<Message[]>([]),
    [busqueda, setBusqueda] = useState(''),
    [rol, setRol] = useState('TODOS'),
    [texto, setTexto] = useState(''),
    [error, setError] = useState(''),
    [cargando, setCargando] = useState(true),
    [enviando, setEnviando] = useState(false),
    [anteriores, setAnteriores] = useState(false),
    [cargandoAnteriores, setCargandoAnteriores] = useState(false);
  const hilo = hilos.find((t) => key(t) === seleccion),
    final = useRef<HTMLDivElement>(null);
  const api = useCallback(
    async (path: string, body?: unknown, signal?: AbortSignal) => {
      const r = await fetch('/api/mensajeria' + path, {
        method: body ? 'POST' : 'GET',
        headers: {
          authorization: 'Bearer ' + token,
          ...(body ? { 'content-type': 'application/json' } : {}),
        },
        ...(body ? { body: JSON.stringify(body) } : {}),
        signal,
      });
      const d = await r.json();
      if (!r.ok) throw new Error(d.error ?? 'No se pudo cargar la mensajería');
      return d;
    },
    [token],
  );
  const cargarHilos = useCallback(
    async (signal?: AbortSignal) => {
      const d = await api('', undefined, signal);
      if (!signal?.aborted) {
        setHilos(d.items);
        setSeleccion((prev) => prev ?? (d.items[0] ? key(d.items[0]) : null));
      }
    },
    [api],
  );
  useEffect(() => {
    const c = new AbortController();
    void cargarHilos(c.signal).catch((e) => {
      if (e.name !== 'AbortError') setError(e.message);
    });
    const timer = setInterval(() => {
      void cargarHilos(c.signal).catch((e) => {
        if (e.name !== 'AbortError') setError(e.message);
      });
    }, 5000);
    return () => {
      c.abort();
      clearInterval(timer);
    };
  }, [cargarHilos]);
  useEffect(() => {
    setMensajes([]);
    setTexto('');
    setError('');
    setAnteriores(false);
    if (!seleccion) {
      setCargando(false);
      return;
    }
    const c = new AbortController();
    setCargando(true);
    const cargar = async (inicial: boolean) => {
      try {
        const d = await api('/' + seleccion, undefined, c.signal);
        if (c.signal.aborted) return;
        setMensajes((prev) => unir(prev, d.items));
        if (inicial) setAnteriores(d.hayAnteriores);
      } catch (e) {
        if (!c.signal.aborted) setError((e as Error).message);
      } finally {
        if (!c.signal.aborted) setCargando(false);
      }
    };
    void cargar(true);
    const timer = setInterval(() => {
      void cargar(false);
    }, 4000);
    return () => {
      c.abort();
      clearInterval(timer);
    };
  }, [seleccion, api]);
  useEffect(() => {
    onBusy(enviando);
    return () => onBusy(false);
  }, [enviando, onBusy]);
  useEffect(() => {
    final.current?.scrollIntoView({ block: 'nearest' });
  }, [seleccion, mensajes.at(-1)?.MensajeLocalId]);
  async function enviar(e: FormEvent) {
    e.preventDefault();
    if (!seleccion || !texto.trim() || enviando || cargando) return;
    setEnviando(true);
    setError('');
    try {
      const m = await api('/' + seleccion, { texto: texto.trim() });
      setMensajes((prev) => unir(prev, [m]));
      setTexto('');
      await cargarHilos();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setEnviando(false);
    }
  }
  async function cargarMas() {
    if (!seleccion || !mensajes.length) return;
    setCargandoAnteriores(true);
    try {
      const d = await api(
        '/' + seleccion + '?antes=' + mensajes[0].MensajeLocalId,
      );
      setMensajes((prev) => unir(prev, d.items));
      setAnteriores(d.hayAnteriores);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setCargandoAnteriores(false);
    }
  }
  const visibles = hilos.filter(
    (t) =>
      (rol === 'TODOS' || t.Rol === rol) &&
      (
        nombre(t) +
        ' ' +
        t.estudiante.contacto.NombreCompleto +
        ' ' +
        t.estudiante.Codigo
      )
        .toLowerCase()
        .includes(busqueda.toLowerCase()),
  );
  return (
    <main className="inbox-page">
      <header className="inbox-heading">
        <div>
          <span className="eyebrow">ATENCIÓN · CUSTOMERS</span>
          <h1>Mensajería</h1>
          <p>
            Conversaciones con estudiantes y apoderados. Responde directamente
            desde aquí.
          </p>
        </div>
        <span className="inbox-live">● Sincronización activa</span>
      </header>
      {error && (
        <p className="error" role="alert">
          {error}
        </p>
      )}
      <div className="inbox-layout">
        <aside className="inbox-threads" aria-label="Conversaciones">
          <div className="inbox-filters">
            <input
              aria-label="Buscar conversación"
              placeholder="Buscar contacto o estudiante…"
              value={busqueda}
              onChange={(e) => setBusqueda(e.target.value)}
            />
            <select
              aria-label="Filtrar conversaciones por rol"
              value={rol}
              onChange={(e) => setRol(e.target.value)}
            >
              <option value="TODOS">Todos los contactos</option>
              <option value="ESTUDIANTE">Estudiantes</option>
              <option value="APODERADO">Apoderados</option>
            </select>
            <small>{visibles.length} conversaciones · últimos 200 hilos</small>
          </div>
          <div className="inbox-thread-list">
            {visibles.map((t) => (
              <button
                key={key(t)}
                className={
                  'inbox-thread ' + (key(t) === seleccion ? 'selected' : '')
                }
                disabled={enviando || cargandoAnteriores}
                onClick={() => setSeleccion(key(t))}
              >
                <span className={'inbox-avatar ' + t.Rol.toLowerCase()}>
                  {nombre(t)
                    .split(' ')
                    .slice(0, 2)
                    .map((n) => n[0])
                    .join('')}
                </span>
                <span className="inbox-thread-info">
                  <strong>{nombre(t)}</strong>
                  <small>
                    {t.Rol === 'APODERADO' ? 'Apoderado' : 'Estudiante'} ·{' '}
                    {t.estudiante.Codigo}
                  </small>
                  {t.Rol === 'APODERADO' && (
                    <small>
                      De{' '}
                      {t.estudiante.contacto.NombreCompleto.replace(
                        ' Demo',
                        '',
                      )}
                    </small>
                  )}
                  <span className="inbox-preview">
                    {t.Direccion === 'SALIENTE' ? 'LaPreDigital: ' : ''}
                    {t.Contenido}
                  </span>
                </span>
                <time>{dia(t.Fecha)}</time>
              </button>
            ))}
            {!visibles.length && (
              <p className="inbox-empty">
                No hay conversaciones de mensajería para esta búsqueda.
              </p>
            )}
          </div>
        </aside>
        <section
          className="inbox-conversation"
          aria-label="Conversación seleccionada"
        >
          {hilo ? (
            <>
              <header className="inbox-contact">
                <span className={'inbox-avatar ' + hilo.Rol.toLowerCase()}>
                  {nombre(hilo)
                    .split(' ')
                    .slice(0, 2)
                    .map((n) => n[0])
                    .join('')}
                </span>
                <div>
                  <h2>{nombre(hilo)}</h2>
                  <p>
                    {hilo.Rol === 'APODERADO'
                      ? 'Apoderado de ' +
                        hilo.estudiante.contacto.NombreCompleto.replace(
                          ' Demo',
                          '',
                        )
                      : 'Estudiante'}{' '}
                    · {hilo.estudiante.Codigo}
                    {hilo.contacto.Telefono
                      ? ' · ' + hilo.contacto.Telefono
                      : ''}
                  </p>
                </div>
                <span className="inbox-role">
                  {hilo.Rol === 'APODERADO' ? 'APODERADO' : 'ESTUDIANTE'}
                </span>
              </header>
              <div
                className="inbox-log"
                role="log"
                aria-live="polite"
                aria-busy={cargando}
              >
                {cargando ? (
                  <p className="inbox-empty">Recuperando conversación…</p>
                ) : (
                  <>
                    {anteriores && (
                      <button
                        className="inbox-load"
                        onClick={() => void cargarMas()}
                        disabled={cargandoAnteriores}
                      >
                        {cargandoAnteriores
                          ? 'Cargando…'
                          : 'Ver mensajes anteriores'}
                      </button>
                    )}
                    {mensajes.map((m, i) => (
                      <div key={m.MensajeLocalId}>
                        {(i === 0 ||
                          dia(m.Fecha) !== dia(mensajes[i - 1].Fecha)) && (
                          <div className="inbox-day">{dia(m.Fecha)}</div>
                        )}
                        <article
                          className={
                            'inbox-message ' +
                            (m.Direccion === 'SALIENTE'
                              ? 'outgoing'
                              : 'incoming')
                          }
                        >
                          <small className="inbox-sender">
                            {m.Direccion === 'SALIENTE'
                              ? 'LaPreDigital'
                              : nombre(hilo)}
                          </small>
                          <ChatMarkdown texto={m.Contenido} />
                          <footer>
                            {hora(m.Fecha)}
                            {m.Direccion === 'SALIENTE' && (
                              <span
                                title={
                                  m.FechaEntrega
                                    ? 'Recibido en el portal'
                                    : 'Registrado en el canal; recepción pendiente'
                                }
                              >
                                {m.FechaEntrega
                                  ? ' · Recibido ✓✓'
                                  : ' · Enviado ✓'}
                              </span>
                            )}
                          </footer>
                        </article>
                      </div>
                    ))}
                    <div ref={final} />
                  </>
                )}
              </div>
              <form className="inbox-compose" onSubmit={enviar}>
                <label htmlFor="inbox-text">
                  Tu respuesta manual a {nombre(hilo)}
                </label>
                <div>
                  <textarea
                    id="inbox-text"
                    placeholder="Escribe como equipo LaPreDigital…"
                    value={texto}
                    onChange={(e) => setTexto(e.target.value)}
                    maxLength={2000}
                    rows={2}
                    disabled={enviando || cargando}
                  />
                  <button
                    type="submit"
                    disabled={enviando || cargando || !texto.trim()}
                  >
                    {enviando ? 'Enviando…' : 'Enviar →'}
                  </button>
                </div>
                <small>
                  Se publica directamente en el portal. El asistente automático
                  continúa disponible.
                </small>
              </form>
            </>
          ) : (
            <div className="inbox-empty">
              <h2>Selecciona una conversación</h2>
              <p>
                Aquí aparecen los hilos del canal de mensajería del portal,
                separados del chat académico.
              </p>
            </div>
          )}
        </section>
      </div>
    </main>
  );
}
