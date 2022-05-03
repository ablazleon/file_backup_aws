resource "aws_storagegateway_gateway" "sg_tf" {
  gateway_ip_address       = aws_instance.sg-agent_tf.public_ip
  gateway_name             = "sg_tf"
  gateway_timezone         = "GMT+1:00"
  gateway_type             = "FILE_S3"
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.log_group_sg_tf.arn
  timeouts {
    create = "4m"
  }

  depends_on = [aws_instance.sg-agent_tf, aws_cloudwatch_log_group.log_group_sg_tf]
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
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json # (not shown)

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


resource "aws_ebs_volume" "v_sg_agent_tf" {
  availability_zone = aws_subnet.subnet.availability_zone
  size              = 150

  depends_on = [aws_subnet.subnet]
}

resource "aws_volume_attachment" "ebs_att_tf" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.v_sg_agent_tf.id
  instance_id = aws_instance.sg-agent_tf.id

  depends_on = [aws_ebs_volume.v_sg_agent_tf, aws_instance.sg-agent_tf]

}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group
resource "aws_cloudwatch_log_group" "log_group_sg_tf" {
  name = "log_group_sg_tf"
}

data "aws_storagegateway_local_disk" "ld_sg_tf" {
  depends_on  = [aws_volume_attachment.ebs_att_tf]
  disk_node   = aws_volume_attachment.ebs_att_tf.device_name
  gateway_arn = aws_storagegateway_gateway.sg_tf.arn
}

resource "aws_storagegateway_cache" "sg_c_tf" {
  disk_id     = data.aws_storagegateway_local_disk.ld_sg_tf.disk_id
  gateway_arn = aws_storagegateway_gateway.sg_tf.arn

  depends_on = [aws_storagegateway_gateway.sg_tf]
}



