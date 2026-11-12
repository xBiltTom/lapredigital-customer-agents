# Ejecutar una sola vez en Windows con la cuenta administradora de SQL Server.
# Crea una identidad de lectura sin modificar el esquema ni los datos de negocio.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $root '.env'
if (!(Test-Path -LiteralPath $root -PathType Container)) { throw 'No se encontró la raíz del proyecto.' }
if (Test-Path -LiteralPath $envPath) { throw '.env ya existe; no se sobrescribirá.' }

$connection = New-Object System.Data.SqlClient.SqlConnection -ArgumentList 'Data Source=.;Initial Catalog=master;Integrated Security=SSPI;Encrypt=True;TrustServerCertificate=True'
try {
    $connection.Open()
    $check = $connection.CreateCommand()
    $check.CommandText = "SELECT CASE WHEN DB_ID(N'LaPreDigital_Customers') IS NOT NULL AND SUSER_ID(N'lapredigital_app') IS NULL AND IS_SRVROLEMEMBER(N'sysadmin') = 1 THEN 1 ELSE 0 END"
    if ($check.ExecuteScalar() -ne 1) {
        throw 'La base debe existir, el login no debe existir y la cuenta actual debe ser administradora.'
    }

    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = New-Object byte[] 32
    try { $random.GetBytes($bytes) } finally { $random.Dispose() }
    $password = [Convert]::ToBase64String($bytes)

    $create = $connection.CreateCommand()
    $create.CommandText = "CREATE LOGIN [lapredigital_app] WITH PASSWORD = N'$password', CHECK_POLICY = ON, DEFAULT_DATABASE = [LaPreDigital_Customers]"
    [void]$create.ExecuteNonQuery()

    $create.CommandText = @'
USE [LaPreDigital_Customers];
CREATE USER [lapredigital_app] FOR LOGIN [lapredigital_app];
'@
    [void]$create.ExecuteNonQuery()

    $create.CommandText = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot '../infra/sql/app-read-permissions.sql'))
    [void]$create.ExecuteNonQuery()
    $create.CommandText = "SELECT MIN(PersonalInternoId) FROM dbo.PersonalInterno WHERE Rol=N'DUEÑO' AND Activo=1"
    $ownerId = $create.ExecuteScalar()
    if ($ownerId -is [DBNull]) { throw 'Falta un dueño activo en la base existente.' }
    $ownerToken = [Guid]::NewGuid().ToString('N') + [Guid]::NewGuid().ToString('N')

    $lines = @(
        'SQLSERVER_HOST=host.docker.internal',
        'SQLSERVER_PORT=1433',
        'SQLSERVER_DATABASE=LaPreDigital_Customers',
        'SQLSERVER_USER=lapredigital_app',
        "SQLSERVER_PASSWORD=$password",
        'SQLSERVER_ENCRYPT=true',
        'SQLSERVER_TRUST_SERVER_CERTIFICATE=true',
        "OWNER_PERSONAL_ID=$ownerId",
        "OWNER_ACCESS_TOKEN=$ownerToken"
    )
    [System.IO.File]::WriteAllLines($envPath, $lines, (New-Object System.Text.UTF8Encoding($false)))
    'Usuario SQL de solo lectura creado; credencial local guardada en .env (excluido de Git).'
} finally {
    $connection.Dispose()
}
