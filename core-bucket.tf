

# Se crea un task de migración para lo que es necesario una lcoalización nfs y otra s3
# Forzar la destrucción del bucket
# https://medium.com/interleap/terraform-destroy-replace-buckets-cf9d63d0029d
# Crear un folder

resource "aws_s3_bucket" "core_bucket_tf" {
  bucket = "core-bucket-tf-new"
  force_destroy = false
  tags = {
    Name = "core-bucket-tf-new"
  }
}

# Se crea un objeto con una carpeta
# https://stackoverflow.com/questions/37491893/how-to-create-a-folder-in-an-amazon-s3-bucket-using-terraform
resource "aws_s3_object" "core_bucket_folder_tf" {
  bucket = aws_s3_bucket.core_bucket_tf.id
  key    = "migration/"
}

resource "aws_s3_bucket_acl" "core_bucket_acl_tf" {
  bucket = aws_s3_bucket.core_bucket_tf.id
  acl    = "private"
}








