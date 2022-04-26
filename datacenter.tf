
# Se monta un servidor nfs
# https://www.tecmint.com/install-nfs-server-on-ubuntu/

# Modificar el exports, con el rango de ip pirvada sacada de la subnet
# https://linuxize.com/post/create-a-file-in-linux/#:~:text=To%20create%20a%20new%20file%20run%20the%20cat%20command%20followed,D%20to%20save%20the%20files.
resource "aws_instance" "server_tf" {
  ami                         = "ami-06ad2ef8cd7012912"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.server-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.subnet.id
  user_data                   = <<-EOF
          #!/bin/bash
          sudo apt update
          sudo apt install nfs-kernel-server -y
          sudo mkdir -p /home/ubuntu/share_local_nfs_tf
          sudo chown -R nobody:nogroup /home/ubuntu/share_local_nfs_tf
          sudo chmod 777 /home/ubuntu/share_local_nfs_tf
          sudo echo "/home/ubuntu/share_local_nfs_tf  10.1.0.0/24(rw,sync,no_subtree_check)" > /etc/exports
          sudo echo "hola" > /home/ubuntu/share_local_nfs_tf/ejemplo
          sudo exportfs -a
          sudo systemctl restart nfs-kernel-server
          EOF
  tags = {
    Name = "server_tf"
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