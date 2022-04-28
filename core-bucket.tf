

# Se crea un task de migración para lo que es necesario una lcoalización nfs y otra s3
# Forzar la destrucción del bucket
# https://medium.com/interleap/terraform-destroy-replace-buckets-cf9d63d0029d
# Crear un folder
# # https://stackoverflow.com/questions/37491893/how-to-create-a-folder-in-an-amazon-s3-bucket-using-terraform
resource "aws_s3_bucket" "core_bucket_tf" {
  bucket = "core-bucket-tf"
  key = "migration/"
  content_type = "application/x-directory"
  force_destroy = true

  tags = {
    Name = "core-bucket-tf"
  }
}

resource "aws_s3_bucket_acl" "core_bucket_acl_tf" {
  bucket = aws_s3_bucket.core_bucket_tf.id
  acl    = "private"
}








