import {readFileSync} from 'node:fs';
// El esquema y la población canónicos siguen siendo la única fuente de verdad.
const uno=readFileSync('database/01_crear_customers.sql','utf8');
let ddl=uno.slice(uno.indexOf('-- M07: temario'));
if(!ddl.startsWith('-- M07:'))throw new Error('No se encontró el bloque del temario');
ddl=ddl.replace(/CREATE TABLE dbo\.(\w+)([\s\S]*?);/g,(sql,name)=>`IF OBJECT_ID('dbo.${name}') IS NULL BEGIN ${sql} END;`)
.replace(/CREATE INDEX IX_MensajeLocal_Hilo([^;]*);/,sql=>`IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_MensajeLocal_Hilo') ${sql}`)
.replace('CREATE TRIGGER dbo.TR_ProgresoTemaUNT_Historial','CREATE OR ALTER TRIGGER dbo.TR_ProgresoTemaUNT_Historial');
const dos=readFileSync('database/02_poblar_customers.sql','utf8');
const seed=dos.slice(dos.indexOf('-- M07: catálogo'));
if(!seed.startsWith('-- M07:'))throw new Error('No se encontró la carga del temario');
console.log('USE LaPreDigital_Customers;\nGO\nSET QUOTED_IDENTIFIER ON;\nSET XACT_ABORT ON;\n'+ddl+'\n'+seed);
console.log(readFileSync('infra/sql/mvp-permissions.sql','utf8'));
