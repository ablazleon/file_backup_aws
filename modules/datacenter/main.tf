#https://github.com/linuxacademy/content-hashicorp-certified-terraform-associate-foundations/blob/master/section3-hol2/setup.tf

#Create key-pair for logging into EC2
resource "aws_key_pair" "server-key" {
  key_name   = "id_rsa"
  public_key = file(".ssh/id_rsa.pub")
}

#Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.1.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "datacenter-vpc-tf"
  }

}

#Create IGW
resource "aws_internet_gateway" "igw-tf" {
  vpc_id = aws_vpc.vpc.id
}

#Get main route table to modify
data "aws_route_table" "main_route_table-tf" {
  filter {
    name   = "association.main"
    values = ["true"]
  }
  filter {
    name   = "vpc-id"
    values = [aws_vpc.vpc.id]
  }
}

#Create route table
resource "aws_default_route_table" "internet_route" {
  default_route_table_id = data.aws_route_table.main_route_table-tf.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-tf.id
  }
  tags = {
    Name = "Datacenter-RouteTable-tf"
  }
}

#Get all available AZ's in VPC for master region
data "aws_availability_zones" "azs" {
  state = "available"
}

#Create subnet # 1
resource "aws_subnet" "subnet" {
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.1.0.0/24"
  tags = {
    Name = "sb_tf"
  }
}

#Create SG for allowing all ports
resource "aws_security_group" "sg" {
  name        = "sg"
  description = "Allow TCP/80 & TCP/22"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow traffic from TCP/80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow traffic from NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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
          sudo echo "hola" > /home/ubuntu/share_local_nfs_tf/${var.file_name}
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

resource "aws_instance" "sg-agent_tf" {
  ami                         = "ami-008ded4ccf064a9fa"
  instance_type               = "m5.2xlarge"
  key_name                    = aws_key_pair.server-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.subnet.id
  tags = {
    Name = "sg-agent_tf"
  }

}

#### Volumes

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
