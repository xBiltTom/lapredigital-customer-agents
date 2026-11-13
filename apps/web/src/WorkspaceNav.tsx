export const secciones = [
  ['dashboard', '◫', 'Dashboard', 'Vista general y chat global'],
  ['mensajeria', '✉', 'Mensajería', 'Estudiantes y apoderados'],
  ['alumno', '◎', 'Agente IA', 'Acompañamiento por estudiante'],
  ['estudiantes', '♙', 'Estudiantes', 'Datos personales y objetivos'],
  ['apoderados', '♧', 'Apoderados', 'Contactos y estudiantes vinculados'],
  ['cursos', '▤', 'Cursos y temario', 'Contenido oficial UNT 2027'],
  ['recursos', '▣', 'Recursos', 'Materiales de estudio'],
  ['rutas', '↗', 'Rutas de estudio', 'Versiones y actividades'],
  ['casos', '☷', 'Consultas e incidencias', 'Atención y seguimiento'],
  ['planes', '◇', 'Planes y servicios', 'Catálogo y precios'],
] as const;
export type Vista = (typeof secciones)[number][0];
export function WorkspaceNav({
  active,
  onChange,
  disabled = false,
}: {
  active: Vista;
  onChange: (vista: Vista) => void;
  disabled?: boolean;
}) {
  return (
    <nav className="workspace-nav" aria-label="Espacio de trabajo">
      <span className="side-label">ESPACIO DE TRABAJO</span>
      {secciones.map(([id, icono, titulo, detalle]) => (
        <button
          key={id}
          data-vista={id}
          className={active === id ? 'active' : ''}
          aria-current={active === id ? 'page' : undefined}
          onClick={() => onChange(id)}
          disabled={disabled}
        >
          <span className="workspace-icon">{icono}</span>
          <span>
            {titulo}
            <small>{detalle}</small>
          </span>
          <i />
        </button>
      ))}
    </nav>
  );
}
