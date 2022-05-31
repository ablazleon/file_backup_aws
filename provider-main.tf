
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
    key = "state"
  }
}
