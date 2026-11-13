import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type FormEvent,
} from 'react';
import { ChatMarkdown } from './ChatMarkdown';
import './case-details.css';
type Caso = {
  CasoAtencionId: number;
  EstudianteId: number;
  Tipo: string;
  Ambito: string;
  Estado: string;
  Descripcion: string;
  FechaAperturaOriginal: string;
  FechaLimite: string | null;
  FechaResolucionDefinitiva: string | null;
  Resolucion: string | null;
  ResponsableId: number | null;
};
type Origen = {
  MensajeLocalId: number;
  ContactoId: number;
  Rol: string;
  Contenido: string;
  NombreCompleto: string;
  Telefono: string | null;
  Fecha: string;
};
type Detalle = {
  caso: Caso;
  eventos: {
    EventoCasoId: number;
    Estado: string;
    Detalle: string;
    FechaEvento: string;
    ResponsableId: number | null;
  }[];
  origenes: Origen[];
  estudiante: { codigo: string; nombre: string };
};
const fecha = (s: string | null) =>
  s
    ? new Date(s).toLocaleString('es-PE', {
        timeZone: 'America/Lima',
        dateStyle: 'short',
        timeStyle: 'short',
      })
    : 'Sin definir';
export function CaseDetails({
  id,
  token,
  onClose,
  onChanged,
  onBusy,
}: {
  id: number;
  token: string;
  onClose: () => void;
  onChanged: () => void;
  onBusy: (busy: boolean) => void;
}) {
  const [data, setData] = useState<Detalle | null>(null),
    [error, setError] = useState(''),
    [aviso, setAviso] = useState(''),
    [analisis, setAnalisis] = useState(''),
    [busy, setBusy] = useState(false),
    [analizando, setAnalizando] = useState(false),
    [estado, setEstado] = useState(''),
    [detalle, setDetalle] = useState(''),
    [contacto, setContacto] = useState('');
  const dialog = useRef<HTMLDialogElement>(null);
  const api = useCallback(
    async (path = '', body?: unknown) => {
      const r = await fetch(`/api/casos/${id}${path}`, {
        method: body ? 'POST' : 'GET',
        headers: {
          authorization: 'Bearer ' + token,
          ...(body ? { 'content-type': 'application/json' } : {}),
        },
        ...(body ? { body: JSON.stringify(body) } : {}),
      });
      const d = await r.json();
      if (!r.ok) throw new Error(d.error ?? 'No se pudo completar');
      return d;
    },
    [id, token],
  );
  const cargar = useCallback(async () => {
    const d = await api();
    setData(d);
    setContacto((prev) => prev || String(d.origenes[0]?.MensajeLocalId ?? ''));
  }, [api]);
  useEffect(() => {
    dialog.current?.showModal();
    void cargar().catch((e) => setError(e.message));
  }, [cargar]);
  useEffect(() => {
    onBusy(busy || analizando);
    return () => onBusy(false);
  }, [busy, analizando, onBusy]);
  async function analizar() {
    setAnalizando(true);
    setError('');
    try {
      const d = await api('/analizar', {});
      setAnalisis(d.texto ?? 'Sin análisis disponible');
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setAnalizando(false);
    }
  }
  async function actualizar(e: FormEvent) {
    e.preventDefault();
    if (!data || !estado) return;
    setBusy(true);
    setError('');
    setAviso('');
    try {
      const r = await fetch('/api/admin/casos/' + id, {
        method: 'POST',
        headers: {
          authorization: 'Bearer ' + token,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          Estado: estado,
          EstadoAnterior: data.caso.Estado,
          Detalle: detalle.trim(),
        }),
      });
      const d = await r.json();
      if (!r.ok) throw new Error(d.error);
      setDetalle('');
      setEstado('');
      await cargar();
      onChanged();
      setAviso('Caso actualizado.');
    } catch (e) {
      setError((e as Error).message);
      await cargar().catch(() => {});
    } finally {
      setBusy(false);
    }
  }
  async function comunicar() {
    setBusy(true);
    setError('');
    setAviso('');
    try {
      await api('/comunicar', { mensajeOrigenId: Number(contacto) });
      setAviso(
        'Solución enviada al hilo de mensajería. La recepción se confirma al leer el portal.',
      );
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }
  const c = data?.caso;
  return (
    <dialog
      ref={dialog}
      className="case-detail-dialog"
      onCancel={(e) => {
        e.preventDefault();
        if (!busy && !analizando) onClose();
      }}
      aria-labelledby="case-detail-title"
    >
      <header className="case-detail-header">
        <div>
          <span className="eyebrow">ATENCIÓN AL ESTUDIANTE</span>
          <h2 id="case-detail-title">
            Caso #{id}
            {data ? ' · ' + data.estudiante.nombre.replace(' Demo', '') : ''}
          </h2>
        </div>
        <button
          type="button"
          aria-label="Cerrar detalle del caso"
          disabled={busy || analizando}
          onClick={onClose}
        >
          ×
        </button>
      </header>
      {error && (
        <p className="error" role="alert">
          {error}
        </p>
      )}
      {aviso && (
        <p className="case-detail-success" role="status">
          {aviso}
        </p>
      )}
      {!data || !c ? (
        <p>Cargando caso…</p>
      ) : (
        <>
          <section className="case-detail-summary">
            <span className="pill neutral">
              {c.Tipo} · {c.Ambito} · {c.Estado.replaceAll('_', ' ')}
            </span>
            <p>{c.Descripcion}</p>
            <div>
              <small>Apertura: {fecha(c.FechaAperturaOriginal)}</small>
              <small>
                {Math.max(
                  0,
                  Math.floor(
                    (Date.now() - new Date(c.FechaAperturaOriginal).getTime()) /
                      3600000,
                  ),
                )}{' '}
                horas desde la apertura original
              </small>
              <small>
                Responsable:{' '}
                {c.ResponsableId
                  ? 'Dueño / personal #' + c.ResponsableId
                  : 'Pendiente de asignación'}
              </small>
              {c.FechaLimite && (
                <small>Fecha límite: {fecha(c.FechaLimite)}</small>
              )}
            </div>
            {c.Resolucion && (
              <p>
                <strong>Solución registrada:</strong> {c.Resolucion}
                <small>Resuelto: {fecha(c.FechaResolucionDefinitiva)}</small>
              </p>
            )}
          </section>
          <div className="case-detail-grid">
            <div>
              <section className="case-detail-section">
                <h3>Historial de atención</h3>
                {data.eventos.length ? (
                  data.eventos.map((ev) => (
                    <article className="case-event" key={ev.EventoCasoId}>
                      <strong>{ev.Estado.replaceAll('_', ' ')}</strong>
                      <small>
                        {fecha(ev.FechaEvento)} ·{' '}
                        {ev.ResponsableId
                          ? 'Personal #' + ev.ResponsableId
                          : 'Agente / sistema'}
                      </small>
                      <p>{ev.Detalle}</p>
                    </article>
                  ))
                ) : (
                  <p>No hay eventos registrados.</p>
                )}
              </section>
              {data.origenes.length > 0 && (
                <section className="case-detail-section">
                  <h3>Reportado desde mensajería</h3>
                  {data.origenes.map((o) => (
                    <blockquote key={o.MensajeLocalId}>
                      <strong>
                        {o.NombreCompleto.replace(' Demo', '')} ·{' '}
                        {o.Rol === 'APODERADO' ? 'Apoderado' : 'Estudiante'}
                      </strong>
                      <small>{fecha(o.Fecha)}</small>
                      <p>{o.Contenido}</p>
                    </blockquote>
                  ))}
                </section>
              )}
            </div>
            <div>
              <section className="case-detail-section case-assistant">
                <div className="case-assistant-heading">
                  <h3>Ayuda del agente</h3>
                  <button
                    type="button"
                    disabled={busy || analizando}
                    onClick={() => void analizar()}
                  >
                    {analizando
                      ? 'Analizando…'
                      : analisis
                        ? 'Actualizar análisis'
                        : 'Analizar caso'}
                  </button>
                </div>
                {analisis ? (
                  <ChatMarkdown texto={analisis} />
                ) : (
                  <p>
                    Revisa el contexto, los datos disponibles y los pasos
                    sugeridos para atender este caso.
                  </p>
                )}
                <small>
                  El agente orienta. Tú verificas la solución y decides el
                  cierre.
                </small>
              </section>
              {c.Ambito === 'PAGO' ? (
                <p className="case-detail-section">
                  Caso económico de consulta. Su atención corresponde al dueño /
                  PAYERS.
                </p>
              ) : (
                <section className="case-detail-section">
                  <h3>Actualizar atención</h3>
                  <form onSubmit={actualizar}>
                    <label>
                      Acción
                      <select
                        aria-label="Acción del caso"
                        required
                        value={estado}
                        disabled={busy || analizando}
                        onChange={(e) => setEstado(e.target.value)}
                      >
                        <option value="">Seleccionar…</option>
                        {c.Estado === 'RESUELTA' ? (
                          <option value="REABIERTA">Reabrir caso</option>
                        ) : (
                          <>
                            <option value="EN_ATENCION">
                              {c.Estado === 'EN_ATENCION'
                                ? 'Registrar avance'
                                : 'Comenzar atención'}
                            </option>
                            <option value="RESUELTA">Resolver caso</option>
                          </>
                        )}
                      </select>
                    </label>
                    <label>
                      {estado === 'RESUELTA'
                        ? 'Qué se hizo y qué resultado se verificó'
                        : estado === 'REABIERTA'
                          ? 'Por qué se reabre'
                          : 'Detalle de la atención'}
                      <textarea
                        aria-label="Detalle de atención"
                        required
                        maxLength={1000}
                        value={detalle}
                        disabled={busy || analizando}
                        onChange={(e) => setDetalle(e.target.value)}
                      />
                    </label>
                    <button
                      className="primary"
                      disabled={
                        !estado || !detalle.trim() || busy || analizando
                      }
                    >
                      {busy ? 'Guardando…' : 'Guardar atención'}
                    </button>
                  </form>
                  {c.Estado === 'RESUELTA' && data.origenes.length > 0 && (
                    <div className="case-notify">
                      <h4>Comunicar solución</h4>
                      <label>
                        Contacto del reporte
                        <select
                          aria-label="Contacto para comunicar solución"
                          value={contacto}
                          disabled={busy || analizando}
                          onChange={(e) => setContacto(e.target.value)}
                        >
                          {data.origenes
                            .filter(
                              (o, i, all) =>
                                all.findIndex(
                                  (x) => x.ContactoId === o.ContactoId,
                                ) === i,
                            )
                            .map((o) => (
                              <option
                                key={o.MensajeLocalId}
                                value={o.MensajeLocalId}
                              >
                                {o.NombreCompleto.replace(' Demo', '')} ·{' '}
                                {o.Rol}
                              </option>
                            ))}
                        </select>
                      </label>
                      <button
                        type="button"
                        disabled={!contacto || busy || analizando}
                        onClick={() => void comunicar()}
                      >
                        Enviar solución por mensajería
                      </button>
                    </div>
                  )}
                </section>
              )}
            </div>
          </div>
        </>
      )}
    </dialog>
  );
}
