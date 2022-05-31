
# Updated to v4 and then terraform init -upgrade
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-4-upgrade
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
  region  = "eu-west-3"
}

terraform {
  backend "s3" {
    bucket  = "file-backup-aws-tf-estado"
    region = "eu-west-3"
    key = "state/stage/terraform.state"
  }
}

module "datacenter" {
  source = "../modules/datacenter/"

  file_name = "hola"
}

module "files_backup" {

  source = "../modules/files_backup/"

  ebs-device-name = module.datacenter.ebs-device-name
  DS-Agent-Public-IP = module.datacenter.DS-Agent-Public-IP
  NFSServer-Private-IP = module.datacenter.NFSServer-Private-IP
  SG-Agent-Public-IP = module.datacenter.SG-Agent-Public-IP

  depends_on = [ module.datacenter ]
}

