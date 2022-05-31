# files_backup_aws

En este repo se pracitca con la creación de una arquitectura en aws.

- 1. Se crear un provider-main.tf donde se inicia una isntancia de ejemplo
- 2. Se crea un storage gateway
- 3. Se crea un datasync

Testing:

- [terraform-aws-core-bucket-test.go](https://github.com/gruntwork-io/terratest/blob/master/examples/terraform-aws-s3-example/main.tf), [checks](https://github.com/gruntwork-io/terratest/blob/master/test/terraform_aws_s3_example_test.go) that many properties desired in the creation appears in the bucket resulted.
- [terraform-aws-example](https://github.com/gruntwork-io/terratest/tree/master/examples/terraform-aws-example) ,[checks](https://github.com/gruntwork-io/terratest/blob/master/test/terraform_aws_example_test.go) the tag that the instance tag, owns the name that it is given as a variable.
- [terraform-ssh-example](https://github.com/gruntwork-io/terratest/blob/master/examples/terraform-ssh-example/main.tf), [checks](https://github.com/gruntwork-io/terratest/blob/master/test/terraform_ssh_example_test.go) that it can be connceted to a public and a private instance, checking that the echo of what it is output is what it is input.
