import { readFileSync } from 'node:fs';
const source = readFileSync('database/01_crear_customers.sql', 'utf8');
const begin = '-- INICIO ATENCION MENSAJERIA',
  end = '-- FIN ATENCION MENSAJERIA';
const a = source.indexOf(begin),
  b = source.indexOf(end, a);
if (a < 0 || b < 0) throw new Error('Falta el DDL canónico de atención');
console.log(
  "USE [LaPreDigital_Customers]; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;\nIF OBJECT_ID('dbo.AtencionMensaje','U') IS NULL BEGIN\n" +
    source.slice(a + begin.length, b) +
    '\nEND;\nGRANT SELECT,INSERT,UPDATE ON dbo.AtencionMensaje TO lapredigital_app;',
);
