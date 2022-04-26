# Se crea una conexión con el agente
resource "aws_datasync_agent" "datasync_agent" {
  ip_address = aws_instance.ds-agent_tf.public_ip
  name       = "datasync_agent"
  # Depende que se cree la conexión con el agente de que se haya creado la vm agente
  depends_on = [aws_instance.ds-agent_tf]
}

# Se crea un task de migración para lo que es necesario una lcoalización nfs y otra s3

resource "aws_s3_bucket" "core_bucket_tf" {
  bucket = "core_bucket_tf"

  tags = {
    Name        = "core_bucket_tf"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "core_bucket_acl_tf" {
  bucket = aws_s3_bucket.core_bucket_tf.id
  acl    = "private"
}

# Se crea un rol que permita el acceso de datasync al bucket
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
# https://docs.aws.amazon.com/datasync/latest/userguide/using-identity-based-policies.html
resource "aws_datasync_location_s3" "core_bucket_loc_tf" {
  s3_bucket_arn = aws_s3_bucket.core_bucket_tf.arn
  subdirectory  = "/migration"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_to_s3_role.arn
  }
  depends_on = [aws_datasync_agent.datasync_agent, aws_s3_bucket.core_bucket_tf, aws_iam_role.datasync_to_s3_role]
}

resource "aws_iam_role" "datasync_to_s3_role" {
  name = "test_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ],
        "Effect" : "Allow",
        "Resource" : "${aws_s3_bucket.core_bucket_tf.arn}"
      },
      {
        "Action" : [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListMultipartUploadParts",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
          "s3:PutObject"
        ],
        "Effect" : "Allow",
        "Resource" : "${aws_s3_bucket.core_bucket_tf.arn}/*"
      }
    ]
  })

}


