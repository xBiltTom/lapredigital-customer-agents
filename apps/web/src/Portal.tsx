import { useEffect, useRef, useState, type FormEvent } from 'react';
import { ChatMarkdown } from './ChatMarkdown';

type ModoPortal = 'ACADEMIA' | 'MENSAJERIA';
type RolPortal = 'ESTUDIANTE' | 'APODERADO';
type Tema = {
  id: number;
  curso: string;
  tema: string;
  subtemas: string;
  estado: string;
};
type Mensaje = {
  MensajeLocalId: number;
  Direccion: string;
  Contenido: string;
  FechaEntrega: string | null;
};
type Alumno = { estudianteId: number; nombreCompleto: string };
type FichaPortal = {
  nombre: string;
  nombreContacto: string;
  telefonoContacto: string | null;
  parentesco: string | null;
  rol: RolPortal;
  plan: string | null;
  temario: Tema[];
};

export function Portal() {
  const finalChat = useRef<HTMLDivElement>(null);
  const [owner, setOwner] = useState(
    () => sessionStorage.getItem('portal.owner') ?? '',
  );
  const [key, setKey] = useState('');
  const [token, setToken] = useState(() => {
    const fromHash = new URLSearchParams(location.hash.slice(1)).get('acceso');
    if (fromHash) {
      history.replaceState(null, '', location.pathname);
      sessionStorage.setItem('portal.actor', fromHash);
    }
    return fromHash ?? sessionStorage.getItem('portal.actor') ?? '';
  });
  const [alumnos, setAlumnos] = useState<Alumno[]>([]);
  const [alumnosCargando, setAlumnosCargando] = useState(false);
  const [estudianteId, setEstudianteId] = useState(0);
  const [rol, setRol] = useState<RolPortal>('ESTUDIANTE');
  const [apoderadoDisponible, setApoderadoDisponible] = useState(false);
  const [nombreApoderado, setNombreApoderado] = useState('');
  const [verificandoApoderado, setVerificandoApoderado] = useState(false);
  const [abriendo, setAbriendo] = useState(false);
  const [modo, setModo] = useState<ModoPortal>('ACADEMIA');
  const [ficha, setFicha] = useState<FichaPortal | null>(null);
  const [mensajes, setMensajes] = useState<Mensaje[]>([]);
  const [mensajesCargando, setMensajesCargando] = useState(false);
  const [texto, setTexto] = useState('');
  const [curso, setCurso] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const identidadActual = useRef(token);
  const canalActual = useRef(modo);
  identidadActual.current = token;
  canalActual.current = modo;

  async function api<T = any>(path: string, body?: unknown, asOwner = false) {
    const response = await fetch(path, {
      method: body ? 'POST' : 'GET',
      headers: {
        Authorization: `Bearer ${asOwner ? owner : token}`,
        'Content-Type': 'application/json',
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error ?? 'No se pudo completar la solicitud.');
    return data as T;
  }

  useEffect(() => {
    if (!owner) return;
    sessionStorage.setItem('portal.owner', owner);
    let vigente = true;
    setAlumnosCargando(true);
    api<{ items: Alumno[] }>('/api/estudiantes', undefined, true)
      .then((data) => {
        if (!vigente) return;
        const items = data.items ?? [];
        setAlumnos(items);
        setEstudianteId((actual) =>
          items.some((alumno) => alumno.estudianteId === actual)
            ? actual
            : (items[0]?.estudianteId ?? 0),
        );
      })
      .catch((cause) => {
        if (vigente) setError((cause as Error).message);
      })
      .finally(() => {
        if (vigente) setAlumnosCargando(false);
      });
    return () => {
      vigente = false;
    };
  }, [owner]);

  useEffect(() => {
    if (!owner || !alumnos.some((alumno) => alumno.estudianteId === estudianteId)) {
      setApoderadoDisponible(false);
      setNombreApoderado('');
      setVerificandoApoderado(false);
      return;
    }

    let vigente = true;
    setApoderadoDisponible(false);
    setNombreApoderado('');
    setVerificandoApoderado(true);
    api<any>(`/api/estudiantes/${estudianteId}`, undefined, true)
      .then((data) => {
        if (!vigente) return;
        const apoderado = data.ficha?.apoderado;
        const tienePrestacion = data.ficha?.prestaciones?.some(
          (prestacion: { codigo: string }) =>
            prestacion.codigo === 'REPORTES_APODERADO',
        );
        setNombreApoderado(apoderado?.nombreCompleto ?? '');
        setApoderadoDisponible(Boolean(apoderado?.nombreCompleto && tienePrestacion));
      })
      .catch((cause) => {
        if (vigente) setError((cause as Error).message);
      })
      .finally(() => {
        if (vigente) setVerificandoApoderado(false);
      });
    return () => {
      vigente = false;
    };
  }, [owner, estudianteId, alumnos]);

  async function cargarFicha() {
    const data = await api<FichaPortal>('/api/portal/ficha');
    if (identidadActual.current === token) setFicha(data);
  }

  async function cargarMensajes(mostrarCarga = false) {
    if (mostrarCarga) setMensajesCargando(true);
    try {
      const data = await api<Mensaje[]>(`/api/portal/mensajes/${modo}`);
      if (identidadActual.current === token && canalActual.current === modo)
        setMensajes(data);
    } catch (cause) {
      if (identidadActual.current === token && canalActual.current === modo)
        setError((cause as Error).message);
    } finally {
      if (
        mostrarCarga &&
        identidadActual.current === token &&
        canalActual.current === modo
      ) {
        setMensajesCargando(false);
      }
    }
  }

  useEffect(() => {
    if (!token) return;
    sessionStorage.setItem('portal.actor', token);
    setFicha(null);
    setMensajes([]);
    setError('');
    cargarFicha().catch((cause) => setError((cause as Error).message));
  }, [token]);

  useEffect(() => {
    if (!token) return;
    setMensajes([]);
    void cargarMensajes(true);
    const timer = setInterval(() => void cargarMensajes(), 2500);
    return () => clearInterval(timer);
  }, [token, modo]);

  async function abrir() {
    if (!estudianteId || (rol === 'APODERADO' && !apoderadoDisponible)) return;
    setAbriendo(true);
    setError('');
    try {
      const access = await api<{ token: string }>(
        '/api/portal/acceso',
        { e: estudianteId, rol },
        true,
      );
      setToken(access.token);
      setCurso('');
    } catch (cause) {
      setError((cause as Error).message);
    } finally {
      setAbriendo(false);
    }
  }

  async function enviar(event: FormEvent) {
    event.preventDefault();
    if (busy || !texto.trim()) return;
    const mensaje = texto;
    setTexto('');
    setBusy(true);
    try {
      await api(`/api/portal/mensajes/${modo}`, { texto: mensaje });
      await cargarMensajes();
      await cargarFicha();
    } catch (cause) {
      setError((cause as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function avanzar(tema: Tema, estado: string) {
    try {
      await api('/api/portal/progreso', { contenidoId: tema.id, estado });
      await cargarFicha();
    } catch (cause) {
      setError((cause as Error).message);
    }
  }

  useEffect(() => {
    finalChat.current?.scrollIntoView({ block: 'nearest' });
  }, [mensajes.length, modo]);

  function cambiarModo(siguiente: ModoPortal) {
    if (busy || siguiente === modo) return;
    setTexto('');
    setModo(siguiente);
  }

  const limpiar = (nombre: string) => nombre.replace(' Demo', '');
  const nombreContacto = limpiar(ficha?.nombreContacto ?? ficha?.nombre ?? '');
  const nombreEstudiante = limpiar(ficha?.nombre ?? '');
  const esMensajeria = modo === 'MENSAJERIA';
  const nombreBot = esMensajeria
    ? 'Seguimiento LaPreDigital'
    : 'Asistente de estudio';
  const cursos = [...new Set(ficha?.temario.map((tema) => tema.curso) ?? [])];
  const alumnoSeleccionado = alumnos.find(
    (alumno) => alumno.estudianteId === estudianteId,
  );

  return (
    <div className={`portal ${esMensajeria ? 'messenger' : ''}`}>
      <header className="portal-header">
        <a className="portal-brand" href="/" aria-label="LaPreDigital, inicio">
          <span className="portal-brand-mark" aria-hidden="true">L</span>
          <span>
            <strong>LaPreDigital</strong>
            <small>Tu preparación, a tu ritmo</small>
          </span>
        </a>
        <nav className="portal-mode-switch" aria-label="Cambiar zona">
          <button
            type="button"
            className={`portal-mode ${modo === 'ACADEMIA' ? 'active' : ''}`}
            aria-pressed={modo === 'ACADEMIA'}
            onClick={() => cambiarModo('ACADEMIA')}
            disabled={busy}
          >
            <span className="portal-mode-icon" aria-hidden="true">◫</span>
            <span className="portal-mode-copy">
              <strong>Academia</strong>
              <small>Temario y ejercicios</small>
            </span>
            <span className="portal-mode-indicator" aria-hidden="true" />
          </button>
          <button
            type="button"
            className={`portal-mode ${modo === 'MENSAJERIA' ? 'active' : ''}`}
            aria-pressed={modo === 'MENSAJERIA'}
            onClick={() => cambiarModo('MENSAJERIA')}
            disabled={busy}
          >
            <span className="portal-mode-icon" aria-hidden="true">▤</span>
            <span className="portal-mode-copy">
              <strong>Mensajería</strong>
              <small>Seguimiento y ayuda</small>
            </span>
            <span className="portal-mode-indicator" aria-hidden="true" />
          </button>
        </nav>
      </header>

      <section className="portal-control" aria-label="Simulación local">
        <details className="simulator-control" open={!token}>
          <summary>
            <span className="simulator-control-icon" aria-hidden="true">◎</span>
            <span className="simulator-control-copy">
              <strong>Simulación local</strong>
              <small>
                {ficha
                  ? `Sesión activa · ${nombreContacto} · ${ficha.rol === 'APODERADO' ? 'Apoderado' : 'Estudiante'}`
                  : 'Elige a quién quieres ver en el portal'}
              </small>
            </span>
            <span className="simulator-control-action">
              {token ? 'Cambiar vista' : 'Configurar'}
            </span>
          </summary>
          <div className="simulator-control-body">
            {!owner ? (
              <form
                className="simulator-login"
                onSubmit={(event) => {
                  event.preventDefault();
                  setOwner(key.trim());
                }}
              >
                <label htmlFor="simulator-owner-key">Acceso del dueño</label>
                <div>
                  <input
                    id="simulator-owner-key"
                    type="password"
                    placeholder="Token local para iniciar la simulación"
                    value={key}
                    onChange={(event) => setKey(event.target.value)}
                  />
                  <button className="primary">Entrar al control</button>
                </div>
              </form>
            ) : (
              <div className="simulator-form">
                <label className="simulator-field">
                  <span>Participante</span>
                  <select
                    aria-label="Seleccionar estudiante de la simulación"
                    value={estudianteId || ''}
                    onChange={(event) => {
                      setEstudianteId(Number(event.target.value));
                      setRol('ESTUDIANTE');
                      setError('');
                    }}
                    disabled={alumnosCargando || alumnos.length === 0 || abriendo}
                  >
                    <option value="" disabled>
                      {alumnosCargando ? 'Cargando estudiantes…' : 'Selecciona estudiante'}
                    </option>
                    {alumnos.map((alumno) => (
                      <option value={alumno.estudianteId} key={alumno.estudianteId}>
                        {limpiar(alumno.nombreCompleto)}
                      </option>
                    ))}
                  </select>
                </label>

                <fieldset className="simulator-persona" disabled={abriendo}>
                  <legend>Ver el portal como</legend>
                  <div className="simulator-persona-options">
                    <button
                      type="button"
                      className={`simulator-persona-card ${rol === 'ESTUDIANTE' ? 'active' : ''}`}
                      aria-pressed={rol === 'ESTUDIANTE'}
                      onClick={() => setRol('ESTUDIANTE')}
                    >
                      <span className="persona-avatar student" aria-hidden="true">E</span>
                      <span className="persona-copy">
                        <strong>Estudiante</strong>
                        <small>Su propia preparación</small>
                      </span>
                      <span className="persona-check" aria-hidden="true">✓</span>
                    </button>
                    {apoderadoDisponible && (
                      <button
                        type="button"
                        className={`simulator-persona-card ${rol === 'APODERADO' ? 'active' : ''}`}
                        aria-pressed={rol === 'APODERADO'}
                        onClick={() => setRol('APODERADO')}
                      >
                        <span className="persona-avatar guardian" aria-hidden="true">A</span>
                        <span className="persona-copy">
                          <strong>Apoderado</strong>
                          <small>{limpiar(nombreApoderado)}</small>
                        </span>
                        <span className="persona-check" aria-hidden="true">✓</span>
                      </button>
                    )}
                  </div>
                  {verificandoApoderado ? (
                    <small className="simulator-hint" role="status">
                      Comprobando si hay una vista de apoderado disponible…
                    </small>
                  ) : !apoderadoDisponible && estudianteId ? (
                    <small className="simulator-hint">
                      Este estudiante no tiene una vista de apoderado disponible.
                    </small>
                  ) : null}
                </fieldset>

                <div className="simulator-submit-row">
                  <span>
                    {alumnoSeleccionado
                      ? `Se abrirá el portal de ${limpiar(alumnoSeleccionado.nombreCompleto)}.`
                      : 'Selecciona un estudiante para continuar.'}
                  </span>
                  <button
                    className="primary simulator-open"
                    type="button"
                    onClick={abrir}
                    disabled={
                      !estudianteId ||
                      alumnosCargando ||
                      verificandoApoderado ||
                      abriendo ||
                      (rol === 'APODERADO' && !apoderadoDisponible)
                    }
                  >
                    {abriendo ? 'Abriendo…' : token ? 'Aplicar vista' : 'Abrir portal'}
                    {!abriendo && <span aria-hidden="true">→</span>}
                  </button>
                </div>
              </div>
            )}
          </div>
        </details>
      </section>

      {error && <p className="error portal-error" role="alert">{error}</p>}

      {ficha ? (
        <main className="portal-main">
          <section className={`portal-welcome portal-welcome-${modo.toLowerCase()}`}>
            <div className={`portal-zone-summary ${esMensajeria ? 'messaging' : 'academic'}`} key={modo} aria-live="polite">
              <span className="portal-zone-summary-icon" aria-hidden="true">
                {esMensajeria ? '▤' : '◫'}
              </span>
              <span className="portal-zone-summary-copy">
                <small>ZONA ACTIVA</small>
                <strong>{esMensajeria ? 'Mensajería y seguimiento' : 'Academia y estudio'}</strong>
                <span>
                  {esMensajeria
                    ? 'Conversa con el asistente y mantén el ritmo de preparación.'
                    : 'Consulta el temario y aprende con el asistente académico.'}
                </span>
              </span>
              <span className="portal-zone-summary-tag">
                {esMensajeria ? 'ACOMPAÑAMIENTO' : 'APRENDIZAJE'}
              </span>
            </div>
            <p className="eyebrow">
              {ficha.rol === 'APODERADO' ? 'ACOMPAÑA SU FUTURO' : 'CONSTRUYE TU FUTURO'}
            </p>
            <h1>
              {esMensajeria
                ? 'Tus conversaciones'
                : ficha.rol === 'APODERADO'
                  ? `El progreso de ${nombreEstudiante}`
                  : `Hola, ${nombreContacto.split(' ')[0]}`}
            </h1>
            <p>
              {esMensajeria
                ? 'Recordatorios, acompañamiento y continuidad académica.'
                : `${ficha.plan ?? 'Sin servicio vigente'} · Tu camino hacia la UNT 2027`}
            </p>
          </section>

          <div
            className={`portal-zone ${esMensajeria ? 'portal-conversation' : 'portal-grid'}`}
            key={modo}
            role="region"
            aria-label={esMensajeria ? 'Zona de mensajería' : 'Zona de academia'}
          >
            {esMensajeria && (
              <aside className="conversation-sidebar">
                <div className="conversation-title">
                  <span>Conversaciones</span>
                  <span aria-hidden="true">◷</span>
                </div>
                <p className="conversation-note">Cuenta de {nombreContacto}</p>
                <div className="contact-selected">
                  <span className="contact-avatar">L</span>
                  <div>
                    <strong>{nombreBot}</strong>
                    <small>LaPreDigital · Acompañamiento</small>
                  </div>
                </div>
                <div className="conversation-purpose">
                  <span aria-hidden="true">✦</span>
                  <h3>Seguimiento que acompaña.</h3>
                  <p>
                    Actividades pendientes, recordatorios y ayuda para mantener el ritmo de preparación.
                  </p>
                  <small>Esta conversación es independiente del asistente de estudio.</small>
                </div>
              </aside>
            )}

            {modo === 'ACADEMIA' && (
              <section className="card study-card">
                <div className="study-heading">
                  <span aria-hidden="true">◫</span>
                  <div>
                    <p className="eyebrow">MI RUTA · UNT 2027</p>
                    <h2>{ficha.rol === 'APODERADO' ? 'Preparación del estudiante' : 'Mi preparación'}</h2>
                  </div>
                  <span className="study-count">
                    {ficha.temario.filter((tema) => tema.estado === 'COMPLETADA').length}
                    <small>/{ficha.temario.length} temas</small>
                  </span>
                </div>
                <p className="muted study-progress-copy">
                  Avance de estudio; no acredita dominio.
                </p>
                <div className="study-filter">
                  <label htmlFor="portal-course-filter">Filtrar por curso</label>
                  <select
                    id="portal-course-filter"
                    value={curso}
                    onChange={(event) => setCurso(event.target.value)}
                  >
                    <option value="">Todos los cursos</option>
                    {cursos.map((nombreCurso) => <option key={nombreCurso}>{nombreCurso}</option>)}
                  </select>
                </div>
                <div className="study-topics">
                  {ficha.temario
                    .filter((tema) => !curso || tema.curso === curso)
                    .map((tema) => (
                      <article className="record study-topic" key={tema.id}>
                        <div className="study-topic-heading">
                          <span className="study-topic-course">{tema.curso}</span>
                          <span className={`study-status status-${tema.estado.toLowerCase()}`}>
                            {tema.estado.replace('_', ' ')}
                          </span>
                        </div>
                        <h3>{tema.tema}</h3>
                        <p>{JSON.parse(tema.subtemas).join(' · ') || 'Tema general'}</p>
                        {ficha.rol === 'ESTUDIANTE' ? (
                          <label className="study-state-control">
                            <span>Mi avance</span>
                            <select
                              aria-label={`Estado de ${tema.tema}`}
                              value={tema.estado}
                              onChange={(event) => avanzar(tema, event.target.value)}
                            >
                              <option value="PENDIENTE">Pendiente</option>
                              <option value="EN_CURSO">En curso</option>
                              <option value="COMPLETADA">Completado</option>
                            </select>
                          </label>
                        ) : (
                          <span className="study-observer-label">Avance del estudiante</span>
                        )}
                      </article>
                    ))}
                  {!ficha.temario.length && (
                    <p className="empty">El temario todavía no tiene temas disponibles.</p>
                  )}
                  {!!ficha.temario.length && !ficha.temario.some((tema) => !curso || tema.curso === curso) && (
                    <p className="empty">No hay temas para este curso.</p>
                  )}
                </div>
              </section>
            )}

            <section className="card portal-chat">
              <header>
                <span className={`contact-avatar ${esMensajeria ? 'messaging-avatar' : 'academic-avatar'}`} aria-hidden="true">
                  {esMensajeria ? '▤' : '✦'}
                </span>
                <div className="portal-chat-title">
                  <h3>{nombreBot}</h3>
                  <small>
                    {esMensajeria
                      ? 'Asistente de seguimiento · LaPreDigital'
                      : 'Tu ayuda con conceptos, ejercicios y plataforma'}
                  </small>
                </div>
                <span className={`recipient-badge ${ficha.rol === 'APODERADO' ? 'guardian' : ''}`}>
                  {esMensajeria
                    ? 'SEGUIMIENTO'
                    : ficha.rol === 'APODERADO' ? 'APODERADO' : 'ESTUDIANTE'}
                </span>
              </header>
              <div className="chat-identity">
                <span className="identity-led" />
                {esMensajeria
                  ? `Tu cuenta: ${nombreContacto} · ${ficha.rol === 'APODERADO' ? `Apoderado de ${nombreEstudiante}` : 'Estudiante'}`
                  : `Sesión de ${nombreContacto} · ${ficha.rol === 'APODERADO' ? `Reporte de ${nombreEstudiante}` : 'Asistente académico'}`}
              </div>
              <div className="portal-messages" aria-live="polite" aria-busy={mensajesCargando}>
                {mensajesCargando ? (
                  <div className="portal-message-loading" role="status">
                    <span className="loading-dots"><i /><i /><i /></span>
                    <span>Abriendo {esMensajeria ? 'mensajería' : 'academia'}…</span>
                  </div>
                ) : !mensajes.length ? (
                  <p className="empty portal-empty">
                    {esMensajeria
                      ? 'Aquí llegan tus recordatorios y mensajes de acompañamiento.'
                      : '¿Qué aprendemos hoy? Pregúntame sobre un tema, un ejercicio o cómo usar la plataforma.'}
                  </p>
                ) : (
                  mensajes.map((mensaje) => (
                    <div
                      className={`chat-message ${mensaje.Direccion === 'ENTRANTE' ? 'user' : 'agent'}`}
                      key={mensaje.MensajeLocalId}
                    >
                      <ChatMarkdown texto={mensaje.Contenido} />
                      <small>
                        {mensaje.Direccion === 'SALIENTE' ? nombreBot : nombreContacto}
                        {mensaje.FechaEntrega ? ' · Recibido ✓✓' : ''}
                      </small>
                    </div>
                  ))
                )}
                <div ref={finalChat} />
              </div>
              {busy && <p className="thinking">{nombreBot} está escribiendo…</p>}
              <form className="chat-form" onSubmit={enviar}>
                <textarea
                  value={texto}
                  onChange={(event) => setTexto(event.target.value)}
                  aria-label="Tu mensaje"
                  placeholder={
                    esMensajeria
                      ? `Responder como ${nombreContacto.split(' ')[0]}…`
                      : 'Pregunta sobre un tema o ejercicio…'
                  }
                  maxLength={2000}
                />
                <button className="send" disabled={busy || !texto.trim()} aria-label="Enviar mensaje">
                  ↑
                </button>
              </form>
            </section>
          </div>
        </main>
      ) : (
        <section className="portal-onboarding" aria-live="polite">
          <span aria-hidden="true">✦</span>
          <h1>Tu espacio de preparación</h1>
          <p>Configura una sesión para explorar Academia y Mensajería como un participante.</p>
          {!token && <small>La simulación se ejecuta localmente y no envía mensajes a proveedores externos.</small>}
        </section>
      )}
    </div>
  );
}
