
resource "aws_instance" "server_tf" {
  ami                         = "ami-0c6ebbd55ab05f070"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.server-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.subnet.id
  user_data                   = <<EOF
          #! /bin/bash
          sudo apt-get update
          EOF
  tags = {
    Name = "server"
  }
}

resource "aws_instance" "ds-agent_tf" {
  ami                         = "ami-099ed32be5f65d949"
  instance_type               = "m5.2xlarge"
  key_name                    = aws_key_pair.server-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.subnet.id
  tags = {
    Name = "ds-agent_tf"
  }
}