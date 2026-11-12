import {readFile} from 'node:fs/promises';
const db='LaPreDigital_Customers_MvpTest';
process.stdout.write(`USE master; IF DB_ID(N'${db}') IS NOT NULL BEGIN ALTER DATABASE [${db}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [${db}]; END\nGO\n`);
for(const path of ['database/01_crear_customers.sql','database/02_poblar_customers.sql']) {
  process.stdout.write((await readFile(path,'utf8')).replace(/^\uFEFF/,'').replaceAll('LaPreDigital_Customers',db)+'\nGO\n');
}
process.stdout.write(`USE [${db}]; CREATE USER lapredigital_app FOR LOGIN lapredigital_app;\nGO\n`);
for(const path of ['infra/sql/app-read-permissions.sql','infra/sql/mvp-permissions.sql']) process.stdout.write((await readFile(path,'utf8')).replaceAll('LaPreDigital_Customers',db)+'\nGO\n');
