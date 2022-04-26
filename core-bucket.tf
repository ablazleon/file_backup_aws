

# Se crea un task de migración para lo que es necesario una lcoalización nfs y otra s3

resource "aws_s3_bucket" "core_bucket_tf" {
  bucket = "core-bucket-tf"

  tags = {
    Name = "core-bucket-tf"
  }
}

resource "aws_s3_bucket_acl" "core_bucket_acl_tf" {
  bucket = aws_s3_bucket.core_bucket_tf.id
  acl    = "private"
}








