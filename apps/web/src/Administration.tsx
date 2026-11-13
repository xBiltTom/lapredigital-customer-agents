import { useEffect, useRef, useState, type FormEvent } from 'react';
import { secciones, type Vista } from './WorkspaceNav';
// Campos en PascalCase conservan el nombre del modelo SQL y evitan traducciones duplicadas.
type Row = Record<string, any>;
type Field = {
  key: string;
  label: string;
  type?: string;
  options?: { value: string | number; label: string }[];
  required?: boolean;
};
const tipos = [
  'TEXTO',
  'PDF',
  'VIDEO',
  'EJERCICIO',
  'EJEMPLO_RESUELTO',
  'EXAMEN_DESARROLLADO',
  'EVALUACION',
  'SIMULACRO',
];
const opciones = (values: string[]) =>
  values.map((value) => ({ value, label: value.replaceAll('_', ' ') }));
function leerSubtemas(value: unknown): string[] {
  try {
    const parsed =
      typeof value === 'string' ? JSON.parse(value) : (value ?? []);
    return Array.isArray(parsed)
      ? parsed.map((item) =>
          typeof item === 'string' ? item : JSON.stringify(item),
        )
      : [];
  } catch {
    return [];
  }
}
export function Administration({
  vista,
  token,
  onBusy,
  onChanged,
}: {
  vista: Exclude<Vista, 'dashboard' | 'alumno'>;
  token: string;
  onBusy: (busy: boolean) => void;
  onChanged: () => void;
}) {
  const [data, setData] = useState<Row>({ items: [] }),
    [opts, setOpts] = useState<Row>({
      estudiantes: [],
      apoderados: [],
      temas: [],
      recursos: [],
    }),
    [buscar, setBuscar] = useState(''),
    [pagina, setPagina] = useState(1),
    [error, setError] = useState(''),
    [loading, setLoading] = useState(true),
    [saving, setSaving] = useState(false),
    [refresh, setRefresh] = useState(0),
    [edit, setEdit] = useState<{
      resource: string;
      id: number | null;
      values: Row;
      fields: Field[];
      title: string;
    } | null>(null),
    [temas, setTemas] = useState<Row[]>([]);
  const [cursoSeleccionado, setCursoSeleccionado] = useState<string | null>(
    null,
  );
  const [cargandoTemas, setCargandoTemas] = useState(false);
  const [errorTemario, setErrorTemario] = useState('');
  const solicitudTemario = useRef(0);
  const disparadorCurso = useRef<HTMLButtonElement | null>(null);
  const cerrarTemario = useRef<HTMLButtonElement | null>(null);
  async function api(path: string, body?: Row) {
    const r = await fetch('/api/admin/' + path, {
      method: body ? 'POST' : 'GET',
      headers: {
        authorization: 'Bearer ' + token,
        ...(body ? { 'content-type': 'application/json' } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    const result = await r.json();
    if (!r.ok) throw new Error(result.error ?? 'No se pudo cargar');
    return result;
  }
  function abrirCurso(curso: string, trigger: HTMLButtonElement) {
    disparadorCurso.current = trigger;
    const solicitud = ++solicitudTemario.current;
    setCursoSeleccionado(curso);
    setTemas([]);
    setCargandoTemas(true);
    setErrorTemario('');
    api('temas?buscar=' + encodeURIComponent(curso))
      .then((d) => {
        if (solicitud === solicitudTemario.current) setTemas(d.items);
      })
      .catch((e) => {
        if (solicitud === solicitudTemario.current) {
          setErrorTemario(e.message);
        }
      })
      .finally(() => {
        if (solicitud === solicitudTemario.current) setCargandoTemas(false);
      });
  }
  function cerrarCurso() {
    solicitudTemario.current++;
    setCursoSeleccionado(null);
    setTemas([]);
    setCargandoTemas(false);
    setErrorTemario('');
    requestAnimationFrame(() => disparadorCurso.current?.focus());
  }
  useEffect(() => {
    if (cursoSeleccionado) cerrarTemario.current?.focus();
  }, [cursoSeleccionado]);
  useEffect(() => {
    let active = true;
    setLoading(true);
    setError('');
    api(`${vista}?buscar=${encodeURIComponent(buscar)}&pagina=${pagina}`)
      .then((d) => {
        if (active) setData(d);
      })
      .catch((e) => {
        if (active) setError(e.message);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [vista, buscar, pagina, refresh, token]);
  useEffect(() => {
    let active = true;
    api('opciones')
      .then((d) => {
        if (active) setOpts(d);
      })
      .catch((e) => {
        if (active) setError(e.message);
      });
    return () => {
      active = false;
    };
  }, [token, refresh]);
  useEffect(() => {
    onBusy(saving);
    return () => onBusy(false);
  }, [saving, onBusy]);
  const studentOptions = opts.estudiantes.map((x: Row) => ({
    value: x.EstudianteId,
    label: x.Codigo + ' · ' + x.contacto.NombreCompleto,
  }));
  const studentName = (id: number) =>
    studentOptions.find((x: { value: number }) => x.value === id)?.label ??
    `Estudiante ${id}`;
  const contactFields: Field[] = [
    { key: 'NombreCompleto', label: 'Nombre completo', required: true },
    { key: 'Correo', label: 'Correo', type: 'email' },
    { key: 'Telefono', label: 'Teléfono' },
  ];
  function person(row?: Row) {
    const student = vista === 'estudiantes';
    const fields: Field[] = [
      ...contactFields,
      ...(student
        ? [
            { key: 'Codigo', label: 'Código', required: true },
            {
              key: 'UniversidadObjetivo',
              label: 'Universidad objetivo',
              required: true,
            },
            { key: 'CarreraObjetivo', label: 'Carrera objetivo' },
            { key: 'FechaExamen', label: 'Fecha de examen', type: 'date' },
            {
              key: 'DisponibilidadSemanalHoras',
              label: 'Disponibilidad semanal (horas)',
              type: 'number',
            },
            {
              key: 'ApoderadoId',
              label: 'Apoderado',
              type: 'select',
              options: opts.apoderados.map((a: Row) => ({
                value: a.ApoderadoId,
                label: a.contacto.NombreCompleto,
              })),
            },
            { key: 'Parentesco', label: 'Parentesco' },
          ]
        : []),
    ];
    setEdit({
      resource: vista,
      id: row?.[student ? 'EstudianteId' : 'ApoderadoId'] ?? null,
      title:
        (row ? 'Editar ' : 'Registrar ') +
        (student ? 'estudiante' : 'apoderado'),
      fields,
      values: row
        ? { ...row, ...row.contacto }
        : { UniversidadObjetivo: 'Universidad Nacional de Trujillo' },
    });
  }
  function resource(row?: Row) {
    setEdit({
      resource: 'recursos',
      id: row?.RecursoAcademicoId ?? null,
      title: row ? 'Editar recurso' : 'Nuevo recurso',
      values: row ?? { Activo: true, Tipo: 'TEXTO' },
      fields: [
        { key: 'Titulo', label: 'Título', required: true },
        {
          key: 'TemaId',
          label: 'Curso / tema del recurso',
          type: 'select',
          required: true,
          options: opts.temas.map((t: Row) => ({
            value: t.TemaId,
            label: t.curso.Nombre + ' / ' + t.Nombre,
          })),
        },
        {
          key: 'Tipo',
          label: 'Tipo',
          type: 'select',
          required: true,
          options: opciones(tipos),
        },
        { key: 'Ubicacion', label: 'Enlace HTTP/HTTPS', type: 'url' },
        {
          key: 'DuracionEstimadaMin',
          label: 'Duración estimada (minutos)',
          type: 'number',
        },
        {
          key: 'Activo',
          label: 'Disponible para nuevas actividades',
          type: 'checkbox',
        },
      ],
    });
  }
  function newRoute() {
    setEdit({
      resource: 'rutas',
      id: null,
      title: 'Publicar una nueva versión de ruta',
      values: { copiarActividades: true },
      fields: [
        {
          key: 'EstudianteId',
          label: 'Estudiante',
          type: 'select',
          options: studentOptions,
          required: true,
        },
        { key: 'Objetivo', label: 'Objetivo de la ruta', required: true },
        {
          key: 'FechaExamenObjetivo',
          label: 'Fecha de examen objetivo',
          type: 'date',
        },
        {
          key: 'copiarActividades',
          label:
            'Conservar las actividades y resultados de la versión anterior',
          type: 'checkbox',
        },
      ],
    });
  }
  function activity(route: Row) {
    setEdit({
      resource: 'actividades',
      id: null,
      title: 'Añadir actividad a la ruta vigente',
      values: { RutaEstudioId: route.RutaEstudioId },
      fields: [
        {
          key: 'RecursoAcademicoId',
          label: 'Recurso activo',
          type: 'select',
          required: true,
          options: opts.recursos.map((r: Row) => ({
            value: r.RecursoAcademicoId,
            label: r.Titulo,
          })),
        },
        {
          key: 'FechaPlanificada',
          label: 'Día planificado',
          type: 'date',
          required: true,
        },
        {
          key: 'FechaLimite',
          label: 'Día límite',
          type: 'date',
          required: true,
        },
      ],
    });
  }
  function newCase() {
    setEdit({
      resource: 'casos',
      id: null,
      title: 'Registrar consulta o incidencia',
      values: { Tipo: 'CONSULTA', Ambito: 'SERVICIO' },
      fields: [
        {
          key: 'EstudianteId',
          label: 'Estudiante',
          type: 'select',
          options: studentOptions,
          required: true,
        },
        {
          key: 'Tipo',
          label: 'Tipo',
          type: 'select',
          options: opciones(['CONSULTA', 'INCIDENCIA']),
          required: true,
        },
        {
          key: 'Ambito',
          label: 'Ámbito',
          type: 'select',
          options: opciones(['SERVICIO', 'ACCESO']),
          required: true,
        },
        {
          key: 'Descripcion',
          label: 'Descripción',
          type: 'textarea',
          required: true,
        },
      ],
    });
  }
  function caseState(row: Row, Estado: string) {
    setEdit({
      resource: 'casos',
      id: row.CasoAtencionId,
      title: 'Actualizar atención · ' + Estado.replaceAll('_', ' '),
      values: { Estado },
      fields: [
        {
          key: 'Detalle',
          label: 'Detalle de la atención',
          type: 'textarea',
          required: true,
        },
      ],
    });
  }
  async function save(e: FormEvent) {
    e.preventDefault();
    if (!edit) return;
    setSaving(true);
    setError('');
    try {
      const values = { ...edit.values };
      for (const f of edit.fields) {
        if (
          f.type === 'number' ||
          [
            'ApoderadoId',
            'TemaId',
            'EstudianteId',
            'RecursoAcademicoId',
          ].includes(f.key)
        )
          values[f.key] =
            values[f.key] === '' || values[f.key] == null
              ? null
              : Number(values[f.key]);
        else if (f.type === 'checkbox') values[f.key] = !!values[f.key];
        else values[f.key] = values[f.key] ?? '';
      }
      await api(edit.resource + '/' + (edit.id ?? 'nuevo'), values);
      setEdit(null);
      setRefresh((n) => n + 1);
      onChanged();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'No se pudo guardar');
    } finally {
      setSaving(false);
    }
  }
  const title = secciones.find((s) => s[0] === vista)?.[2];
  const descriptions: Record<string, string> = {
    estudiantes:
      'Perfiles, datos de contacto y objetivos académicos. El servicio contratado determina el acceso.',
    apoderados:
      'Un apoderado puede estar vinculado a varios estudiantes. El vínculo familiar no concede acceso al servicio.',
    cursos:
      'Temario preuniversitario UNT 2027. Consulta el contenido preparado para el seguimiento académico.',
    recursos:
      'Materiales utilizados en las actividades de las rutas de estudio.',
    rutas:
      'El dueño publica las rutas. Cada nueva versión conserva las anteriores.',
    casos:
      'Atención de consultas e incidencias de CUSTOMERS, con eventos e historial.',
    planes:
      'Planes y modalidades comerciales disponibles. Contrataciones y pagos permanecen en consulta.',
  };
  return (
    <main className="admin-page">
      <div className="admin-heading">
        <div>
          <span className="eyebrow">ADMINISTRACIÓN · CUSTOMERS</span>
          <h1>{title}</h1>
          <p>{descriptions[vista]}</p>
        </div>
        {['estudiantes', 'apoderados'].includes(vista) ? (
          <button className="admin-primary" onClick={() => person()}>
            + Registrar
          </button>
        ) : vista === 'recursos' ? (
          <button className="admin-primary" onClick={() => resource()}>
            + Recurso
          </button>
        ) : vista === 'rutas' ? (
          <button className="admin-primary" onClick={newRoute}>
            + Publicar versión
          </button>
        ) : vista === 'casos' ? (
          <button className="admin-primary" onClick={newCase}>
            + Nuevo caso
          </button>
        ) : (
          <span className="admin-tag">Solo lectura</span>
        )}
      </div>
      {error && (
        <div role="alert" className="admin-error">
          {error}
        </div>
      )}
      {!['planes', 'rutas', 'cursos'].includes(vista) && (
        <input
          className="admin-search"
          placeholder="Buscar por nombre, código o descripción…"
          aria-label="Buscar registros"
          value={buscar}
          onChange={(e) => {
            setBuscar(e.target.value);
            setPagina(1);
          }}
        />
      )}
      {loading ? (
        <p role="status">Cargando registros…</p>
      ) : (
        <>
          {['estudiantes', 'apoderados'].includes(vista) && (
            <div className="admin-table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Persona</th>
                    <th>Contacto</th>
                    <th>
                      {vista === 'estudiantes'
                        ? 'Objetivo y vínculo'
                        : 'Estudiantes a cargo'}
                    </th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {data.items.map((row: Row) => (
                    <tr key={row.EstudianteId ?? row.ApoderadoId}>
                      <td>
                        <strong>{row.contacto.NombreCompleto}</strong>
                        <small>
                          {row.Codigo ?? 'Apoderado'}{' '}
                          {row.EtapaActual && '· ' + row.EtapaActual}
                        </small>
                      </td>
                      <td>
                        {row.contacto.Correo ?? 'Sin correo'}
                        <small>{row.contacto.Telefono ?? 'Sin teléfono'}</small>
                      </td>
                      <td>
                        {vista === 'estudiantes' ? (
                          <>
                            {row.CarreraObjetivo ?? row.UniversidadObjetivo}
                            <small>
                              {row.apoderado
                                ? row.apoderado.contacto.NombreCompleto +
                                  ' · ' +
                                  row.Parentesco
                                : 'Sin apoderado vinculado'}
                            </small>
                            <small>
                              {row.DisponibilidadSemanalHoras ?? '—'} h/semana ·
                              Examen: {row.FechaExamen ?? 'Sin fecha'}
                            </small>
                          </>
                        ) : (
                          row.estudiantes.map((s: Row) => (
                            <small key={s.EstudianteId}>
                              {s.Codigo} · {s.contacto.NombreCompleto}
                            </small>
                          ))
                        )}
                      </td>
                      <td>
                        <button onClick={() => person(row)}>Editar</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          {vista === 'cursos' && (
            <>
              <div className="admin-metrics course-summary">
                <strong>
                  <span>{data.items.length}</span>
                  <small>Cursos disponibles</small>
                </strong>
                <strong>
                  <span>{data.total}</span>
                  <small>Temas preparados</small>
                </strong>
              </div>
              <div className="admin-grid course-grid">
                {data.items.map((c: Row) => (
                  <button
                    className="course-card"
                    key={c.Curso}
                    aria-haspopup="dialog"
                    aria-label={`Ver temario de ${c.Curso}, ${c._count.ContenidoId} temas`}
                    onClick={(event) =>
                      abrirCurso(c.Curso, event.currentTarget)
                    }
                  >
                    <span className="course-card-top">
                      <span className="course-icon" aria-hidden="true">
                        ▤
                      </span>
                      <span className="course-count">
                        {c._count.ContenidoId}
                        <small>temas</small>
                      </span>
                    </span>
                    <strong className="course-card-title">{c.Curso}</strong>
                    <span className="course-card-foot">
                      <span>UNT · 2027</span>
                      <span>
                        Explorar temario <b aria-hidden="true">↗</b>
                      </span>
                    </span>
                  </button>
                ))}
              </div>
            </>
          )}
          {vista === 'recursos' && (
            <div className="admin-table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Material</th>
                    <th>Curso / tema</th>
                    <th>Disponibilidad</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {data.items.map((r: Row) => (
                    <tr key={r.RecursoAcademicoId}>
                      <td>
                        <strong>{r.Titulo}</strong>
                        <small>
                          {r.Tipo} · {r.DuracionEstimadaMin ?? '—'} min
                        </small>
                        {r.Ubicacion && (
                          <a
                            href={r.Ubicacion}
                            target="_blank"
                            rel="noreferrer"
                          >
                            Abrir material ↗
                          </a>
                        )}
                      </td>
                      <td>
                        {r.tema.curso.Nombre}
                        <small>{r.tema.Nombre}</small>
                      </td>
                      <td>{r.Activo ? 'Activo' : 'Inactivo'}</td>
                      <td>
                        <button onClick={() => resource(r)}>Editar</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          {vista === 'planes' && (
            <>
              <div className="admin-grid">
                {data.items.map((p: Row) => (
                  <section className="admin-card" key={p.PlanServicioId}>
                    <span className="admin-tag">
                      Nivel {p.Nivel} · {p.Activo ? 'Activo' : 'Inactivo'}
                    </span>
                    <h2>{p.Nombre}</h2>
                    {p.modalidades.map((m: Row) => (
                      <p key={m.ModalidadPlanId}>
                        {m.Meses} mes(es){' '}
                        <strong>S/ {Number(m.PrecioPEN).toFixed(2)}</strong>{' '}
                        {!m.Activo && '· Inactiva'}
                      </p>
                    ))}
                  </section>
                ))}
              </div>
              <h2>Contrataciones y pagos</h2>
              <p>
                Últimas 100 suscripciones. Cada periodo muestra el importe
                exigible y los movimientos registrados, sin confundirlos con
                pagos efectivos.
              </p>
              <div className="admin-table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th>Estudiante / suscripción</th>
                      <th>Periodo y acceso</th>
                      <th>Exigible</th>
                      <th>Movimientos de pago</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.suscripciones?.flatMap((s: Row) =>
                      s.periodos.map((p: Row) => (
                        <tr key={p.PeriodoServicioId}>
                          <td>
                            <strong>{studentName(s.EstudianteId)}</strong>
                            <small>
                              #{s.SuscripcionId} · {s.Estado}
                            </small>
                            <small>
                              Renovación automática:{' '}
                              {s.RenovacionAutomatica ? 'Sí' : 'No'}
                            </small>
                          </td>
                          <td>
                            {p.Inicio.slice(0, 10)} → {p.Fin.slice(0, 10)}
                            <small>
                              {p.Tipo} · {p.EstadoAcceso}
                            </small>
                          </td>
                          <td>S/ {Number(p.ImporteExigiblePEN).toFixed(2)}</td>
                          <td>
                            {p.pagos.length
                              ? p.pagos.map((pago: Row) => (
                                  <small key={pago.PagoId}>
                                    {pago.Tipo} · {pago.Estado} · S/{' '}
                                    {Number(pago.ImportePEN).toFixed(2)}
                                  </small>
                                ))
                              : 'Sin pagos registrados'}
                          </td>
                        </tr>
                      )),
                    )}
                  </tbody>
                </table>
              </div>
            </>
          )}
          {vista === 'rutas' && (
            <>
              {data.revisiones?.length > 0 && (
                <section className="admin-card">
                  <h3>{data.revisiones.length} revisiones pendientes</h3>
                  {data.revisiones.map((r: Row) => (
                    <p key={r.RevisionRutaId}>
                      Ruta #{r.RutaEstudioId} · {r.Motivo.replaceAll('_', ' ')}
                      {r.Recomendacion && ' · ' + r.Recomendacion}
                    </p>
                  ))}
                </section>
              )}
              <div className="admin-grid">
                {data.items.map((r: Row) => (
                  <section className="admin-card" key={r.RutaEstudioId}>
                    <span className="admin-tag">
                      Versión {r.VersionNumero} ·{' '}
                      {r.Vigente ? 'Vigente' : 'Histórica'}
                    </span>
                    <h3>{studentName(r.EstudianteId)}</h3>
                    <p>{r.Objetivo}</p>
                    <small>
                      Examen:{' '}
                      {r.FechaExamenObjetivo?.slice(0, 10) ?? 'Sin fecha'}
                    </small>
                    <details>
                      <summary>{r.actividades.length} actividades</summary>
                      {r.actividades.map((a: Row) => (
                        <p key={a.ActividadRutaId}>
                          {a.Orden}.{' '}
                          {opts.recursos.find(
                            (x: Row) =>
                              x.RecursoAcademicoId === a.RecursoAcademicoId,
                          )?.Titulo ?? 'Recurso #' + a.RecursoAcademicoId}
                          <small>
                            {a.Estado} · Límite {a.FechaLimite.slice(0, 10)}
                          </small>
                        </p>
                      ))}
                    </details>
                    {r.Vigente && (
                      <button onClick={() => activity(r)}>
                        + Añadir actividad
                      </button>
                    )}
                  </section>
                ))}
              </div>
            </>
          )}
          {vista === 'casos' && (
            <div className="admin-grid">
              {data.items.map((c: Row) => (
                <section className="admin-card" key={c.CasoAtencionId}>
                  <span className="admin-tag">
                    {c.Tipo} · {c.Estado}
                  </span>
                  <h3>{studentName(c.EstudianteId)}</h3>
                  <p>{c.Descripcion}</p>
                  <small>
                    {c.Ambito} · Apertura {c.FechaAperturaOriginal.slice(0, 10)}
                  </small>
                  {c.Resolucion && (
                    <p>
                      <strong>Resolución: </strong>
                      {c.Resolucion}
                    </p>
                  )}
                  {c.Ambito === 'PAGO' ? (
                    <p>Solo lectura · Atención económica en PAYERS.</p>
                  ) : (
                    <div className="admin-actions">
                      {c.Estado === 'RESUELTA' ? (
                        <button onClick={() => caseState(c, 'REABIERTA')}>
                          Reabrir
                        </button>
                      ) : (
                        <>
                          <button onClick={() => caseState(c, 'EN_ATENCION')}>
                            Atender
                          </button>
                          <button onClick={() => caseState(c, 'RESUELTA')}>
                            Resolver
                          </button>
                        </>
                      )}
                    </div>
                  )}
                </section>
              ))}
            </div>
          )}
          {data.items.length === 0 && (
            <p>No hay registros para esta búsqueda.</p>
          )}
          {data.pagina && (
            <div className="admin-pagination">
              <button
                disabled={pagina === 1}
                onClick={() => setPagina((p) => p - 1)}
              >
                Anterior
              </button>
              <span>
                Página {pagina} · {data.total} registros
              </span>
              <button
                disabled={pagina * 20 >= data.total}
                onClick={() => setPagina((p) => p + 1)}
              >
                Siguiente
              </button>
            </div>
          )}
        </>
      )}
      {edit && (
        <div className="admin-overlay">
          <section
            className="admin-dialog"
            role="dialog"
            aria-modal="true"
            aria-labelledby="admin-dialog-title"
            onKeyDown={(e) => {
              if (e.key === 'Escape' && !saving) {
                setEdit(null);
                setError('');
              }
            }}
          >
            <h2 id="admin-dialog-title">{edit.title}</h2>
            {error && (
              <p role="alert" className="admin-error">
                {error}
              </p>
            )}
            <form onSubmit={save}>
              {edit.fields.map((f) => (
                <label key={f.key}>
                  {f.label}
                  {f.type === 'select' ? (
                    <select
                      required={f.required}
                      value={edit.values[f.key] ?? ''}
                      onChange={(e) =>
                        setEdit({
                          ...edit,
                          values: { ...edit.values, [f.key]: e.target.value },
                        })
                      }
                    >
                      <option value="">Seleccionar…</option>
                      {f.options?.map((o) => (
                        <option key={o.value} value={o.value}>
                          {o.label}
                        </option>
                      ))}
                    </select>
                  ) : f.type === 'textarea' ? (
                    <textarea
                      required={f.required}
                      value={edit.values[f.key] ?? ''}
                      onChange={(e) =>
                        setEdit({
                          ...edit,
                          values: { ...edit.values, [f.key]: e.target.value },
                        })
                      }
                    />
                  ) : (
                    <input
                      type={f.type ?? 'text'}
                      required={f.required}
                      step={f.type === 'number' ? 'any' : undefined}
                      checked={
                        f.type === 'checkbox' ? !!edit.values[f.key] : undefined
                      }
                      value={
                        f.type === 'checkbox'
                          ? undefined
                          : (edit.values[f.key] ?? '')
                      }
                      onChange={(e) =>
                        setEdit({
                          ...edit,
                          values: {
                            ...edit.values,
                            [f.key]:
                              f.type === 'checkbox'
                                ? e.target.checked
                                : e.target.value,
                          },
                        })
                      }
                    />
                  )}
                </label>
              ))}
              {edit.resource === 'estudiantes' && !edit.id && (
                <p>
                  Este formulario crea el perfil. El servicio se habilita
                  mediante contratación o beca autorizada.
                </p>
              )}
              <div className="admin-actions">
                <button
                  type="button"
                  disabled={saving}
                  onClick={() => {
                    setEdit(null);
                    setError('');
                  }}
                >
                  Cancelar
                </button>
                <button className="admin-primary" disabled={saving}>
                  {saving ? 'Guardando…' : 'Guardar'}
                </button>
              </div>
            </form>
          </section>
        </div>
      )}
      {cursoSeleccionado && (
        <div
          className="admin-overlay course-overlay"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) cerrarCurso();
          }}
        >
          <section
            className="admin-dialog course-dialog"
            role="dialog"
            aria-modal="true"
            aria-labelledby="course-dialog-title"
            onKeyDown={(event) => {
              if (event.key === 'Escape') {
                event.preventDefault();
                cerrarCurso();
              }
              if (event.key === 'Tab') {
                const focusable = event.currentTarget.querySelectorAll<HTMLElement>(
                  'button:not(:disabled), summary, a[href], [tabindex]:not([tabindex="-1"])',
                );
                const first = focusable[0];
                const last = focusable[focusable.length - 1];
                if (event.shiftKey && document.activeElement === first) {
                  event.preventDefault();
                  last?.focus();
                } else if (!event.shiftKey && document.activeElement === last) {
                  event.preventDefault();
                  first?.focus();
                }
              }
            }}
          >
            <header className="course-dialog-header">
              <div>
                <span className="course-dialog-eyebrow">TEMARIO UNT · 2027</span>
                <h2 id="course-dialog-title">{cursoSeleccionado}</h2>
                <p>
                  {cargandoTemas
                    ? 'Cargando los temas del curso…'
                    : `${temas.length} temas en este curso`}
                </p>
              </div>
              <button
                ref={cerrarTemario}
                className="course-close"
                type="button"
                aria-label="Cerrar temario"
                onClick={cerrarCurso}
              >
                ×
              </button>
            </header>
            <div className="course-dialog-content">
              {cargandoTemas && (
                <p className="course-loading" role="status">
                  <span aria-hidden="true">◌</span> Preparando el temario…
                </p>
              )}
              {errorTemario && (
                <p className="admin-error" role="alert">
                  {errorTemario}
                </p>
              )}
              {!cargandoTemas && !errorTemario && temas.length === 0 && (
                <p className="course-empty">
                  Este curso todavía no tiene temas disponibles.
                </p>
              )}
              {!cargandoTemas && temas.length > 0 && (
                <div className="course-topic-list">
                  {temas.map((tema, index) => {
                    const subtemas = leerSubtemas(tema.Subtemas);
                    return (
                      <article className="course-topic" key={tema.ContenidoId}>
                        <span className="course-topic-number">
                          {String(index + 1).padStart(2, '0')}
                        </span>
                        <details className="course-topic-details">
                          <summary>
                            <span>{tema.Tema}</span>
                            <small>
                              {subtemas.length}{' '}
                              {subtemas.length === 1 ? 'subtema' : 'subtemas'}
                            </small>
                          </summary>
                          {subtemas.length > 0 ? (
                            <ul>
                              {subtemas.map((subtema, subtemaIndex) => (
                                <li key={`${tema.ContenidoId}-${subtemaIndex}`}>
                                  {subtema}
                                </li>
                              ))}
                            </ul>
                          ) : (
                            <p>Sin subtemas registrados.</p>
                          )}
                        </details>
                      </article>
                    );
                  })}
                </div>
              )}
            </div>
          </section>
        </div>
      )}
    </main>
  );
}
