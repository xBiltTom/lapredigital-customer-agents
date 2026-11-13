import { useEffect, useState, type FormEvent } from 'react';
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
              <div className="admin-metrics">
                <strong>{data.items.length} cursos</strong>
                <strong>{data.total} temas preparados</strong>
              </div>
              <div className="admin-grid">
                {data.items.map((c: Row) => (
                  <button
                    className="admin-card"
                    key={c.Curso}
                    onClick={() => {
                      setError('');
                      api('temas?buscar=' + encodeURIComponent(c.Curso))
                        .then((d) => setTemas(d.items))
                        .catch((e) => setError(e.message));
                    }}
                  >
                    <h3>{c.Curso}</h3>
                    <p>{c._count.ContenidoId} temas · Ver contenido →</p>
                  </button>
                ))}
              </div>
              {temas.length > 0 && (
                <section className="admin-card">
                  <h2>Contenido del curso</h2>
                  {temas.map((t) => (
                    <details key={t.ContenidoId}>
                      <summary>{t.Tema}</summary>
                      <ul>
                        {(JSON.parse(t.Subtemas) as string[]).map((s, i) => (
                          <li key={i}>
                            {typeof s === 'string' ? s : JSON.stringify(s)}
                          </li>
                        ))}
                      </ul>
                    </details>
                  ))}
                </section>
              )}
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
    </main>
  );
}
