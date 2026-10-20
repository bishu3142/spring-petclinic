terraform {
  required_version = ">=1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.0"
    }
  }

  backend "s3" {
    bucket       = "dove-s3-bucket-uka95w2f"
    key          = "dev/ecs/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
    region       = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}