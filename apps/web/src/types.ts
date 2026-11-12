export type Alumno={estudianteId:number;codigo:string;nombreCompleto:string;etapaActual:string;carreraObjetivo:string|null};
export type Diagnostico={
 temario:{id:number;curso:string;tema:string;subtemas:string;estado:string;origen:string|null}[];
 estudianteId:number;corte:string;inicio:string;narrativaPendiente:boolean;
 ficha:{estudiante:{codigo:string;nombreCompleto:string;correo:string|null;telefono:string|null;etapaActual:string;carreraObjetivo:string|null;universidadObjetivo:string;disponibilidadSemanalHoras:number|null;fechaExamen:string|null;parentesco:string|null;fechaRegistro:string};apoderado:{nombreCompleto:string;correo:string|null;telefono:string|null}|null;servicioActual:{plan:string;fin:string;becaPorcentaje:number;cobrosConfirmados:number;importeCobradoPEN:number;renovacionAutomatica:boolean}|null;historial:{periodoServicioId:number;plan:string;tipo:string;inicio:string;fin:string}[];prestaciones:{codigo:string;descripcion:string}[]};
 ruta:{id:number;version:number}|null;rutas:{id:number;version:number;vigente:boolean}[];cumplimiento:{planificadas:number;completadas:number;porcentaje:number|null};
 intentos:{id:number;grupoId:number|null;grupo:string|null;alcance:string|null;escala:string|null;dificultad:string|null;fecha:string;aciertos:number;total:number}[];
 mejoras:{grupoId:number;grupo:string;alcance:string;inicialPct:number;posteriorPct:number|null;mejoraPP:number|null;inicialId:number;posteriorId:number|null}[];
 riesgo:{estado:string;nivel:string|null;mayorObservado:string|null;senales:{codigo:string;nivel:string;fuente:string;id:number;fecha:string}[]};
 uso:{id:number;fecha:string}|null;frecuencia:{recientes:number;anteriores:number};satisfaccion:number|null;
 actividades:{id:number;rutaId:number;titulo:string;estado:string;planificada:string;limite:string;completada:string|null}[];
 casos:{id:number;estado:string;ambito:string;descripcion:string;apertura:string}[];
 dificultades:{id:number;estado:string;descripcion:string}[];
 mensajes:{id:number;contenido:string;intencion:string|null}[];valoraciones:{id:number;estrellas:number;comentario:string|null;aspecto:string}[];
 revisiones:{id:number;estado:string;motivo:string;recomendacion:string|null;resultado:string|null}[];
 acciones:{id:number;tipo:string;estado:string;recomendacion:string;resultado:string|null}[];
 seguimiento:{permitido:boolean;causas:string[];canales:string[]};
 evaluacionGuardada:{id:number;fecha:string;nivel:string|null;vigente:boolean}|null;
};
