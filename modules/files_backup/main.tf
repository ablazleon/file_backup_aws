
#### BUCKET

# Se crea un task de migración para lo que es necesario una lcoalización nfs y otra s3
# Forzar la destrucción del bucket
# https://medium.com/interleap/terraform-destroy-replace-buckets-cf9d63d0029d
# Crear un folder
resource "aws_s3_bucket" "core_bucket_tf" {
  bucket        = "core-bucket-tf"
  force_destroy = true
  tags = {
    Name = "core-bucket-tf"
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


#### DATASYNC

# Se crea una conexión con el agente
resource "aws_datasync_agent" "datasync_agent_tf" {
  ip_address = var.DS-Agent-Public-IP
  name       = "datasync_agent"
  # Depende que se cree la conexión con el agente de que se haya creado la vm agente

}

#### DATASYNC NFS TO S3

# Se crea un rol que permita el acceso de datasync al bucket
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
# https://docs.aws.amazon.com/datasync/latest/userguide/using-identity-based-policies.html
resource "aws_datasync_location_s3" "core_bucket_loc_tf" {
  s3_bucket_arn = aws_s3_bucket.core_bucket_tf.arn
  subdirectory  = "/migration"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_to_s3_role.arn
  }
  depends_on = [aws_datasync_agent.datasync_agent_tf, aws_iam_role.datasync_to_s3_role]
}

# Se referencia al arn del bucket
# https://www.terraform.io/language/expressions/references


resource "aws_iam_role" "datasync_to_s3_role" {
  name               = "datasync_to_s3_role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy_datasync.json # (not shown)

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

data "aws_iam_policy_document" "instance_assume_role_policy_datasync" {
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
  server_hostname = var.NFSServer-Private-IP
  subdirectory    = "/home/ubuntu/share_local_nfs_tf"

  on_prem_config {
    agent_arns = [aws_datasync_agent.datasync_agent_tf.arn]
  }

  depends_on = [aws_datasync_agent.datasync_agent_tf]
}

resource "aws_datasync_task" "task" {
  destination_location_arn = aws_datasync_location_s3.core_bucket_loc_tf.arn
  name                     = "task"
  source_location_arn      = aws_datasync_location_nfs.nfs_loc_tf.arn

  /*
  # Corre cada hora
  schedule {
    schedule_expression = "cron(0 1 ? * * *)"
  }
  */

  options {
    bytes_per_second = -1
  }

  timeouts {
    create = "1m"
  }
  depends_on = [aws_datasync_location_s3.core_bucket_loc_tf, aws_datasync_location_nfs.nfs_loc_tf]
}

#### STORAGE GATEWAY

resource "aws_storagegateway_gateway" "sg_tf" {
  gateway_ip_address       = var.SG-Agent-Public-IP
  gateway_name             = "sg_tf"
  gateway_timezone         = "GMT+1:00"
  gateway_type             = "FILE_S3"
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.log_group_sg_tf.arn
  timeouts {
    create = "4m"
  }

  depends_on = [aws_cloudwatch_log_group.log_group_sg_tf]
}

resource "aws_storagegateway_nfs_file_share" "nfs_fs_tf" {
  client_list     = ["0.0.0.0/0"]
  gateway_arn     = aws_storagegateway_gateway.sg_tf.arn
  location_arn    = "${aws_s3_bucket.core_bucket_tf.arn}/migration/"
  role_arn        = aws_iam_role.sg_s3_role.arn
  file_share_name = "nfs_fs_tf"
  nfs_file_share_defaults {
    directory_mode = "0777"
    file_mode      = "0666"
    group_id       = "65534"
    owner_id       = "65534"
  }

  timeouts {
    create = "3m"
  }
  # Dependencia con la carpeta migration
  depends_on = [aws_storagegateway_gateway.sg_tf, aws_iam_role.sg_s3_role, aws_s3_bucket.core_bucket_tf]
}

resource "aws_iam_role" "sg_s3_role" {
  name               = "sg_s3_role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy_storagegateway.json # (not shown)

  inline_policy {
    name = "sg_policy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:GetAccelerateConfiguration",
            "s3:GetBucketLocation",
            "s3:GetBucketVersioning",
            "s3:ListBucket",
            "s3:ListBucketVersions",
            "s3:ListBucketMultipartUploads"
          ],
          "Effect" : "Allow",
          "Resource" : "${aws_s3_bucket.core_bucket_tf.arn}"
        },
        {
          "Action" : [
            "s3:AbortMultipartUpload",
            "s3:DeleteObject",
            "s3:DeleteObjectVersion",
            "s3:GetObject",
            "s3:GetObjectAcl",
            "s3:GetObjectVersion",
            "s3:ListMultipartUploadParts",
            "s3:PutObject",
            "s3:PutObjectAcl"
          ],
          "Effect" : "Allow",
          "Resource" : "${aws_s3_bucket.core_bucket_tf.arn}/*"
        }
      ]
    })
  }
  depends_on = [aws_s3_bucket.core_bucket_tf]
}


#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group
resource "aws_cloudwatch_log_group" "log_group_sg_tf" {
  name = "log_group_sg_tf"
}

data "aws_storagegateway_local_disk" "ld_sg_tf" {
  disk_node   = var.disk-device-name
  gateway_arn = aws_storagegateway_gateway.sg_tf.arn
}

resource "aws_storagegateway_cache" "sg_c_tf" {
  disk_id     = data.aws_storagegateway_local_disk.ld_sg_tf.disk_id
  gateway_arn = aws_storagegateway_gateway.sg_tf.arn

  depends_on = [aws_storagegateway_gateway.sg_tf]
}

data "aws_iam_policy_document" "instance_assume_role_policy_storagegateway" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["storagegateway.amazonaws.com"]
    }
  }
}
