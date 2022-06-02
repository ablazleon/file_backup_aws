terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket  = "file-backup-aws-tf-estado"
    region = "eu-west-1"
    key = "state/prod/terraform.state"
  }
}

module "files_backup" {

  source = "../modules/files_backup/"

  disk-device-name = var.disk-device-name
  DS-Agent-Public-IP = var.DS-Agent-Public-IP
  NFSServer-Private-IP = var.NFSServer-Private-IP
  SG-Agent-Public-IP = var.SG-Agent-Public-IP

}