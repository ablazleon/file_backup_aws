
resource "aws_instance" "server" {
  ami           = "ami-0c6ebbd55ab05f070"
  instance_type = "t2.micro"
  key_name                    = aws_key_pair.webserver-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.subnet.id
  provisioner "remote-exec" {
    inline = [
      # Instalar
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("./mykp.pem")
      host        = self.public_ip
    }
  }
  tags = {
    Name = "server"
  }
}