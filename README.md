# files_backup_aws

En este repo se pracitca con la creación de una arquitectura en aws.

- 1. Se crear un provider-main.tf donde se inicia una isntancia de ejemplo
- 2. Se crea un storage gateway
- 3. Se crea un datasync

Testing: se comprueba lo siguiente en la siguiente arquitectura

![Arquitectura](./architecture.png)

- A se crea un fichero de nombre file_name en el servidor nfs
- B se realiza la task para emigrar file_name al bucket, que aparece vacío inicialmente
- C una vez se ha migrado file_name al bucket, a la key donde se ha montado la carpeta compartida se borra la caché
- D se monta la carpeta sobre el cliente nfs del application_server y se observa que ahora sí aparece file_name