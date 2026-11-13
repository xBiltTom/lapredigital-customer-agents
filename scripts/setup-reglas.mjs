// Instalación aditiva sobre una base existente. El DDL y la semilla se leen de 01/02.
import { readFileSync } from 'node:fs';
const schema = readFileSync('database/01_crear_customers.sql', 'utf8');
const seed = readFileSync('database/02_poblar_customers.sql', 'utf8');
function bloque(text, inicio, fin) {
  const a = text.indexOf(inicio),
    b = text.indexOf(fin, a);
  if (a < 0 || b < 0) throw new Error('Falta bloque canónico de reglas');
  return text.slice(a + inicio.length, b).trim();
}
console.log(
  'USE [LaPreDigital_Customers];\nSET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET XACT_ABORT ON;\nGO',
);
console.log(
  "IF OBJECT_ID('dbo.PoliticaRiesgo','U') IS NULL BEGIN\n" +
    bloque(
      schema,
      '-- INICIO TABLA POLITICA RIESGO',
      '-- FIN TABLA POLITICA RIESGO',
    ) +
    '\nEND;\nGO',
);
console.log(
  "IF NOT EXISTS(SELECT 1 FROM dbo.PoliticaRiesgo WHERE VersionReglas='INFORME_7.1') BEGIN\n" +
    bloque(
      seed,
      '-- INICIO SEMILLA POLITICA RIESGO',
      '-- FIN SEMILLA POLITICA RIESGO',
    ) +
    '\nEND;\nGO',
);
console.log(
  bloque(
    schema,
    '-- INICIO PROTECCION POLITICA RIESGO',
    '-- FIN PROTECCION POLITICA RIESGO',
  ).replace('CREATE TRIGGER', 'CREATE OR ALTER TRIGGER') + '\nGO',
);
console.log(
  "IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_EvaluacionRiesgo_Politica') ALTER TABLE dbo.EvaluacionRiesgo ADD CONSTRAINT FK_EvaluacionRiesgo_Politica FOREIGN KEY(VersionReglas) REFERENCES dbo.PoliticaRiesgo(VersionReglas);\nGO",
);
const a = schema.indexOf('CREATE TRIGGER dbo.TR_SenalRiesgo_Evidencia'),
  b = schema.indexOf('\nGO', a);
console.log(
  schema.slice(a, b).replace('CREATE TRIGGER', 'CREATE OR ALTER TRIGGER') +
    '\nGO',
);
console.log('GRANT SELECT, INSERT ON dbo.PoliticaRiesgo TO lapredigital_app;');
