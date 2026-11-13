// Extrae la carga adicional del script de población canónico. No genera un esquema paralelo.
import {readFileSync} from 'node:fs';
const source=readFileSync('database/02_poblar_customers.sql','utf8');
const a=source.indexOf('-- INICIO AMPLIACION 30 ESTUDIANTES'),b=source.indexOf('-- FIN AMPLIACION 30 ESTUDIANTES',a);
if(a<0||b<0)throw new Error('Falta ampliación en 02');
console.log('USE [LaPreDigital_Customers];\nGO\n'+source.slice(a,b)+'\nGO');
