import {useState,type ReactNode} from 'react';
import type {Diagnostico} from './types';

const fecha=(value:string|null|undefined,soloDia=false)=>value?new Date(value).toLocaleString('es-PE',{
 timeZone:'America/Lima',dateStyle:'medium',...(soloDia?{}:{timeStyle:'short' as const}),
}):'Sin registro';
const numero=(value:number)=>value.toLocaleString('es-PE',{maximumFractionDigits:1});
const etiqueta=(value:string)=>value.replaceAll('_',' ').toLowerCase();

function Dato({label,children}:{label:string;children:ReactNode}){
 return <div><dt>{label}</dt><dd>{children??'Sin registro'}</dd></div>;
}

export function ContactoEstudiante({datos}:{datos:Diagnostico}){
 const {estudiante:e,apoderado:a}=datos.ficha;
 return <section className="card student-contact"><div className="card-heading"><h3>Contacto y perfil del estudiante</h3><span className="pill neutral">{e.codigo}</span></div>
  <dl className="student-data">
   <Dato label="Nombre completo">{e.nombreCompleto}</Dato>
   <Dato label="Correo electrónico">{e.correo}</Dato>
   <Dato label="Teléfono">{e.telefono}</Dato>
   <Dato label="Universidad objetivo">{e.universidadObjetivo}</Dato>
   <Dato label="Carrera objetivo">{e.carreraObjetivo}</Dato>
   <Dato label="Fecha de examen">{fecha(e.fechaExamen,true)}</Dato>
   <Dato label="Disponibilidad semanal">{e.disponibilidadSemanalHoras===null?'Sin registro':`${numero(e.disponibilidadSemanalHoras)} horas`}</Dato>
   <Dato label="Registro del estudiante">{fecha(e.fechaRegistro)}</Dato>
  </dl>
  <h4>Apoderado vinculado</h4>
  {a?<dl className="student-data">
   <Dato label="Nombre completo">{a.nombreCompleto}</Dato>
   <Dato label="Parentesco">{e.parentesco}</Dato>
   <Dato label="Correo electrónico">{a.correo}</Dato>
   <Dato label="Teléfono">{a.telefono}</Dato>
  </dl>:<p className="empty">Sin apoderado registrado.</p>}
 </section>;
}

export function DesempenoAcademico({datos}:{datos:Diagnostico}){
 const [curso,setCurso]=useState('');
 const intentos=[...datos.intentos].sort((a,b)=>b.fecha.localeCompare(a.fecha)||b.id-a.id);
 return <>
  <section className="card"><h3>Temario UNT 2027 · avance por tema</h3><p className="muted">{datos.temario.filter(t=>t.estado==='COMPLETADA').length} / {datos.temario.length} temas completados. Avance de estudio; no acredita dominio. El avance inicial tiene origen CARGA_DEMO.</p><select aria-label="Curso del temario" value={curso} onChange={e=>setCurso(e.target.value)}><option value="">Todos los cursos</option>{[...new Set(datos.temario.map(t=>t.curso))].map(c=><option key={c}>{c}</option>)}</select><div style={{maxHeight:380,overflow:'auto'}}>{datos.temario.filter(t=>!curso||t.curso===curso).map(t=><div className="record" key={t.id}><strong>{t.curso} · {t.tema}</strong><small className="detail-line">{t.estado} · {t.origen??'Sin registro de avance'}</small></div>)}</div></section>
  <section className="card"><div className="card-heading"><h3>Resultados de evaluaciones</h3><span className="pill neutral">{intentos.length} intentos</span></div>
   <p className="muted">Todos los intentos finalizados hasta el corte. Cada porcentaje corresponde a sus aciertos; la mejora del resumen solo compara pruebas del mismo grupo.</p>
   {intentos.length?<div className="academic-table-wrap" tabIndex={0} role="region" aria-label="Resultados de evaluaciones"><table className="academic-table"><thead><tr><th>Intento / fecha</th><th>Grupo y alcance</th><th>Aciertos</th><th>Resultado</th></tr></thead><tbody>
    {intentos.map(i=><tr key={i.id}><td><strong>Intento #{i.id}</strong><small>{fecha(i.fecha)}</small></td><td><strong>{i.grupo??'Sin grupo comparable'}</strong><small>{i.alcance??'Comparabilidad no definida'}</small>{i.escala&&<small>Escala: {i.escala}</small>}{i.dificultad&&<small>Dificultad: {i.dificultad}</small>}</td><td>{i.aciertos} / {i.total}</td><td><strong>{i.total>0?`${numero(100*i.aciertos/i.total)} %`:'Sin datos'}</strong></td></tr>)}
   </tbody></table></div>:<p className="empty">Sin evaluaciones finalizadas registradas.</p>}
  </section>
  <section className="card"><div className="card-heading"><h3>Actividades y versiones de ruta</h3><span className="pill neutral">{datos.actividades.length} actividades</span></div>
   <p className="muted">Incluye rutas anteriores. El cumplimiento del resumen corresponde únicamente a la ruta vigente y su ventana de 30 días.</p>
   {datos.rutas.map(r=><div key={r.id} className="academic-route"><h4>Ruta v{r.version} <span className="pill neutral">{r.vigente?'Vigente':'Anterior'}</span></h4>
    {datos.actividades.filter(a=>a.rutaId===r.id).map(a=><div className="record" key={a.id}><div className="card-heading"><strong>{a.titulo}</strong><span className="pill neutral">{etiqueta(a.estado)}</span></div><small>Actividad #{a.id} · Planificada: {fecha(a.planificada)}</small><small className="detail-line">Límite: {fecha(a.limite)} · Completada: {fecha(a.completada)}</small></div>)}
    {!datos.actividades.some(a=>a.rutaId===r.id)&&<p className="empty">Sin actividades en esta versión.</p>}
   </div>)}
   {!datos.rutas.length&&<p className="empty">Sin ruta académica registrada.</p>}
  </section>
  <section className="card"><h3>Dificultades y revisiones académicas</h3>
   {datos.dificultades.map(d=><div className="record" key={'d'+d.id}><strong>Dificultad #{d.id} · {etiqueta(d.estado)}</strong><p>{d.descripcion}</p></div>)}
   {datos.revisiones.map(r=><div className="record" key={'r'+r.id}><strong>Revisión #{r.id} · {etiqueta(r.estado)}</strong><p>Motivo: {etiqueta(r.motivo)}</p><p>Recomendación: {r.recomendacion??'Sin recomendación registrada'}</p><p>Resultado: {r.resultado??'Sin resultado registrado'}</p></div>)}
   {!datos.dificultades.length&&!datos.revisiones.length&&<p className="empty">Sin dificultades ni revisiones registradas.</p>}
  </section>
 </>;
}
