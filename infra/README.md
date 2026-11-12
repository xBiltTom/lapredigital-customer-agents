# Infraestructura local

SQL Server ya funciona en el contenedor `sql-server-local`. Esta organización no lo reemplaza ni lo reinicia.

Pendiente: documentar puertos, red, volúmenes y mecanismo de recreación que mantenga `America/Lima`; configurar el usuario de aplicación sin usar `sa`; definir la persistencia de sesiones de Eve. Un futuro Compose debe distinguir levantar una aplicación de reconstruir los datos.

La primera versión corre en la computadora del usuario. El despliegue en nube y los canales de mensajes reales quedan para otra fase. No se ha provisionado ningún recurso externo.
