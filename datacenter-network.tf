#https://github.com/linuxacademy/content-hashicorp-certified-terraform-associate-foundations/blob/master/section3-hol2/setup.tf

#Create key-pair for logging into EC2
resource "aws_key_pair" "server-key" {
  key_name   = "id_rsa"
  public_key = file("~/.ssh/id_rsa.pub")
}

#Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
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
  cidr_block        = "10.0.0.0/24"
  tags = {
    Name = "sb_tf"
  }
}


#Create SG for allowing TCP/80 & TCP/22, y 2049 nfs
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "Server-Public-IP" {
  value = aws_instance.server_tf.public_ip
}

output "DS-Agent-Public-IP" {
  value = aws_instance.ds-agent_tf.public_ip
}