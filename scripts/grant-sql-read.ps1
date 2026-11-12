# Ejecutar en Windows con la cuenta administradora de SQL Server.
# Amplía solo los SELECT de lectura que necesita el repositorio de T08.
# No crea logins, no modifica el esquema y no escribe datos de negocio.
$ErrorActionPreference = 'Stop'
$connection = New-Object System.Data.SqlClient.SqlConnection -ArgumentList 'Data Source=.;Initial Catalog=master;Integrated Security=SSPI;Encrypt=True;TrustServerCertificate=True'
try {
    $connection.Open()
    $check = $connection.CreateCommand()
    $check.CommandText = "USE [LaPreDigital_Customers]; SELECT CASE WHEN USER_ID(N'lapredigital_app') IS NOT NULL AND IS_SRVROLEMEMBER(N'sysadmin') = 1 THEN 1 ELSE 0 END"
    if ($check.ExecuteScalar() -ne 1) {
        throw 'La base debe existir, el usuario lapredigital_app debe existir y la cuenta actual debe ser administradora.'
    }

    $grant = $connection.CreateCommand()
    $grant.CommandText = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot '../infra/sql/app-read-permissions.sql'))
    [void]$grant.ExecuteNonQuery()
    'Permisos de lectura de T08 concedidos a lapredigital_app; Pago queda limitado a sus columnas de servicio.'
} finally {
    $connection.Dispose()
}
