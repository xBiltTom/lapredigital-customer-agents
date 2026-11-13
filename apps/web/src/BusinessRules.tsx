import { useCallback, useEffect, useState, type FormEvent } from 'react';
import './business-rules.css';
type Parametros = {
  InactividadMediaHoras: number;
  InactividadAltaHoras: number;
  IncidenciaMediaHoras: number;
  IncidenciaAltaHoras: number;
  VigenciaDias: number;
  MaxEstrellasInsatisfaccion: number;
};
type Politica = Parametros & {
  VersionReglas: string;
  Numero: number;
  FechaPublicacion: string;
  CreadaPorId: number | null;
  Motivo: string;
};
const base: Parametros = {
  InactividadMediaHoras: 72,
  InactividadAltaHoras: 168,
  IncidenciaMediaHoras: 48,
  IncidenciaAltaHoras: 96,
  VigenciaDias: 7,
  MaxEstrellasInsatisfaccion: 2,
};
const campos: {
  key: keyof Parametros;
  label: string;
  unit: string;
  max: number;
  help: string;
}[] = [
  {
    key: 'InactividadMediaHoras',
    label: 'Inactividad: riesgo medio',
    unit: 'horas',
    max: 8760,
    help: 'Desde este tiempo sin actividad, inclusive.',
  },
  {
    key: 'InactividadAltaHoras',
    label: 'Inactividad: riesgo alto',
    unit: 'horas',
    max: 8760,
    help: 'Desde este tiempo, inclusive. Debe superar el umbral medio.',
  },
  {
    key: 'IncidenciaMediaHoras',
    label: 'Incidencia: riesgo medio',
    unit: 'horas',
    max: 8760,
    help: 'Cuando una incidencia de servicio/acceso supera este tiempo sin resolución.',
  },
  {
    key: 'IncidenciaAltaHoras',
    label: 'Incidencia: riesgo alto',
    unit: 'horas',
    max: 8760,
    help: 'Cuando supera este tiempo. Se conserva la apertura original si se reabre.',
  },
  {
    key: 'VigenciaDias',
    label: 'Vigencia de la evaluación',
    unit: 'días',
    max: 30,
    help: 'Antigüedad máxima, inclusive, para una evaluación clasificada.',
  },
  {
    key: 'MaxEstrellasInsatisfaccion',
    label: 'Valoración que requiere revisión',
    unit: 'estrellas',
    max: 4,
    help: 'De 1 a este valor. Solo genera riesgo alto si el comentario evidencia insatisfacción.',
  },
];
export function BusinessRules({
  token,
  onBusy,
  onChanged,
}: {
  token: string;
  onBusy: (busy: boolean) => void;
  onChanged: () => void;
}) {
  const [actual, setActual] = useState<Politica | null>(null),
    [historial, setHistorial] = useState<Politica[]>([]),
    [draft, setDraft] = useState<Parametros>(base),
    [error, setError] = useState(''),
    [ok, setOk] = useState(''),
    [saving, setSaving] = useState(false);
  const cargar = useCallback(async () => {
    const r = await fetch('/api/reglas', {
      headers: { authorization: 'Bearer ' + token },
    });
    const d = await r.json();
    if (!r.ok) throw new Error(d.error);
    setActual(d.actual);
    setHistorial(d.historial);
    setDraft(d.actual);
  }, [token]);
  useEffect(() => {
    void cargar().catch((e) => setError(e.message));
  }, [cargar]);
  useEffect(() => {
    onBusy(saving);
    return () => onBusy(false);
  }, [saving, onBusy]);
  const cambios = actual
    ? campos.filter((c) => draft[c.key] !== actual[c.key])
    : [];
  async function publicar(e: FormEvent) {
    e.preventDefault();
    if (!actual || saving) return;
    setSaving(true);
    setError('');
    setOk('');
    try {
      const r = await fetch('/api/reglas', {
        method: 'POST',
        headers: {
          authorization: 'Bearer ' + token,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          ...Object.fromEntries(campos.map((c) => [c.key, draft[c.key]])),
          versionBase: actual.VersionReglas,
        }),
      });
      const d = await r.json();
      if (!r.ok) throw new Error(d.error);
      await cargar();
      onChanged();
      setOk(
        'Cambios guardados. Los siguientes diagnósticos utilizarán estos valores.',
      );
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(false);
    }
  }
  return (
    <main className="rules-page">
      <header className="rules-heading">
        <span className="eyebrow">CONFIGURACIÓN · CUSTOMERS</span>
        <h1>Reglas del negocio</h1>
        <p>
          Ajusta los criterios del riesgo de abandono. Los cambios se guardan
          automáticamente en el historial.
        </p>
      </header>
      {error && (
        <p className="error" role="alert">
          {error}
        </p>
      )}
      {ok && (
        <p className="rules-success" role="status">
          {ok}
        </p>
      )}
      {!actual ? (
        <p>Cargando reglas…</p>
      ) : (
        <>
          <section className="rules-current">
            <div>
              <span className="rules-badge">CONFIGURACIÓN ACTUAL</span>
              <h2>Riesgo de abandono</h2>
              <p>
                Última actualización:{' '}
                {new Date(actual.FechaPublicacion).toLocaleString('es-PE', {
                  timeZone: 'America/Lima',
                })}
              </p>
            </div>
            <p>
              Los nuevos valores se aplican a los próximos diagnósticos. Las
              evaluaciones anteriores conservan su registro.
            </p>
          </section>
          <form onSubmit={publicar}>
            <fieldset disabled={saving} className="rules-fieldset">
              <div className="rules-grid">
                {campos.map((c) => (
                  <label className="rules-field" key={c.key}>
                    <strong>{c.label}</strong>
                    <span className="rules-number">
                      <input
                        type="number"
                        min={1}
                        max={c.max}
                        step={1}
                        required
                        value={Number.isNaN(draft[c.key]) ? '' : draft[c.key]}
                        onChange={(e) => {
                          setOk('');
                          setDraft({
                            ...draft,
                            [c.key]:
                              e.target.value === ''
                                ? NaN
                                : Number(e.target.value),
                          });
                        }}
                      />
                      <span>{c.unit}</span>
                    </span>
                    <small>{c.help}</small>
                  </label>
                ))}
              </div>
              <section className="rules-publish">
                <h3>Cambios pendientes</h3>
                {cambios.length > 0 ? (
                  <ul>
                    {cambios.map((c) => (
                      <li key={c.key}>
                        {c.label}:{' '}
                        <strong>
                          {actual[c.key]} → {String(draft[c.key])} {c.unit}
                        </strong>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p>No hay cambios pendientes.</p>
                )}
                <div className="rules-buttons">
                  <button
                    type="button"
                    onClick={() => {
                      setDraft(actual);
                      setError('');
                    }}
                  >
                    Descartar cambios
                  </button>
                  <button
                    className="rules-primary"
                    type="submit"
                    disabled={!cambios.length || saving}
                  >
                    {saving ? 'Guardando…' : 'Guardar cambios'}
                  </button>
                </div>
              </section>
            </fieldset>
          </form>
          <section className="rules-fixed">
            <h2>Criterios protegidos</h2>
            <p>
              Prevalece la señal de mayor riesgo. Sin información suficiente la
              evaluación queda pendiente. La intención explícita de cancelar/no
              renovar genera riesgo alto; las dificultades académicas activas
              generan riesgo medio. Una valoración baja necesita interpretación
              contextual. Se respetan el plan, las autorizaciones y las
              peticiones de no contacto.
            </p>
            <p>
              Estos criterios, los pagos, el acceso y los KPI conservan sus
              reglas específicas; esta configuración modifica únicamente los
              parámetros de riesgo mostrados arriba.
            </p>
          </section>
          <section className="rules-history">
            <h2>Historial de cambios</h2>
            <p>
              Últimos 100 cambios, con los valores guardados y su responsable.
            </p>
            <div className="rules-table">
              <table>
                <thead>
                  <tr>
                    <th>Registro / fecha</th>
                    <th>
                      Inactividad
                      <br />
                      Medio / alto
                    </th>
                    <th>
                      Incidencias
                      <br />
                      Medio / alto
                    </th>
                    <th>Vigencia / estrellas</th>
                    <th>Responsable</th>
                  </tr>
                </thead>
                <tbody>
                  {historial.map((p) => (
                    <tr key={p.VersionReglas}>
                      <td>
                        <strong>Registro #{p.Numero}</strong>
                        <small>
                          {new Date(p.FechaPublicacion).toLocaleString(
                            'es-PE',
                            { timeZone: 'America/Lima' },
                          )}
                        </small>
                      </td>
                      <td>
                        {p.InactividadMediaHoras} / {p.InactividadAltaHoras} h
                      </td>
                      <td>
                        {p.IncidenciaMediaHoras} / {p.IncidenciaAltaHoras} h
                      </td>
                      <td>
                        {p.VigenciaDias} días
                        <small>
                          Hasta {p.MaxEstrellasInsatisfaccion} estrellas
                        </small>
                      </td>
                      <td>
                        <strong>
                          {p.CreadaPorId
                            ? 'Dueño #' + p.CreadaPorId
                            : 'Configuración inicial'}
                        </strong>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </>
      )}
    </main>
  );
}
