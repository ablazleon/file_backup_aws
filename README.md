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

Setup

En ubuntu 
```
sudo apt-get update

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

git clone https://github.gsissc.myatos.net/A838102/file_backup_aws.git

```