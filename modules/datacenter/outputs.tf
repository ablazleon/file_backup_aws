output "Server-Public-IP" {
  value = aws_instance.server_tf.public_ip
}

output "DS-Agent-Public-IP" {
  value = aws_instance.ds-agent_tf.public_ip
}

output "SG-Agent-Public-IP" {
  value = aws_instance.sg-agent_tf.public_ip
}

output "NFSServer-Private-IP" {
  value = aws_instance.server_tf.private_ip
}

output "disk-device-name" {
  value = aws_volume_attachment.ebs_att_tf.device_name
}