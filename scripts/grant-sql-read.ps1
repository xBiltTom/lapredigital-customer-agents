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
    $grant.CommandText = @'
USE [LaPreDigital_Customers];
GRANT SELECT ON OBJECT::dbo.Estudiante TO [lapredigital_app];
GRANT SELECT ON OBJECT::dbo.Contacto TO [lapredigital_app];
GRANT SELECT ON OBJECT::dbo.Apoderado TO [lapredigital_app];
GRANT SELECT ON OBJECT::dbo.Suscripcion TO [lapredigital_app];
GRANT SELECT ON OBJECT::dbo.PeriodoServicio TO [lapredigital_app];
GRANT SELECT ON OBJECT::dbo.ModalidadPlan TO [lapredigital_app];
GRANT SELECT ON OBJECT::dbo.PlanServicio TO [lapredigital_app];
GRANT SELECT ON OBJECT::dbo.Prestacion TO [lapredigital_app];
GRANT SELECT ON OBJECT::dbo.PlanPrestacion TO [lapredigital_app];
GRANT SELECT ON OBJECT::dbo.BajaServicio TO [lapredigital_app];
GRANT SELECT ON dbo.Pago (PeriodoServicioId, Tipo, Estado, ImportePEN) TO [lapredigital_app];
'@
    [void]$grant.ExecuteNonQuery()
    'Permisos de lectura de T08 concedidos a lapredigital_app; Pago queda limitado a sus columnas de servicio.'
} finally {
    $connection.Dispose()
}
