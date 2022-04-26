
# Se crea un rol que permita el acceso de datasync al bucket
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
# https://docs.aws.amazon.com/datasync/latest/userguide/using-identity-based-policies.html
resource "aws_datasync_location_s3" "core_bucket_loc_tf" {
  s3_bucket_arn = aws_s3_bucket.core_bucket_tf.arn
  subdirectory  = "/migration"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_to_s3_role.arn
  }
  depends_on = [aws_datasync_agent.datasync_agent, aws_iam_role.datasync_to_s3_role]
}

# Se referencia al arn del bucket
# https://www.terraform.io/language/expressions/references


resource "aws_iam_role" "datasync_to_s3_role" {
  name               = "datasync_to_s3_role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json # (not shown)

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
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
  depends_on = [aws_s3_bucket.core_bucket_tf]
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
  }
}

# Se liga con el nfs montado
resource "aws_datasync_location_nfs" "nfs_loc_tf" {
  server_hostname = aws_instance.server_tf.private_ip
  subdirectory    = "/home/ubuntu/share_local_nfs_tf"

  on_prem_config {
    agent_arns = [aws_datasync_agent.datasync_agent.arn]
  }

  depends_on = [aws_datasync_agent.datasync_agent, aws_instance.server_tf]
}

resource "aws_datasync_task" "task" {
  destination_location_arn = aws_datasync_location_s3.core_bucket_loc_tf.arn
  name                     = "task"
  source_location_arn      = aws_datasync_location_nfs.nfs_loc_tf.arn

  options {
    bytes_per_second = -1
  }

  timeouts {
    create = "2m"
  }
  depends_on = [aws_datasync_location_s3.core_bucket_loc_tf, aws_datasync_location_nfs.nfs_loc_tf]

}



