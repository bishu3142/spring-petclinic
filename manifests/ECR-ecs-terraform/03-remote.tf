data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "dove-s3-bucket-uka95w2f"
    key    = "dev/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

output "vpc_id" {
  value = data.terraform_remote_state.vpc.outputs.vpc_id
}

output "private_subnet_ids" {
  value = data.terraform_remote_state.vpc.outputs.private_subnet_id
}

output "public_subnet_ids" {
  value = data.terraform_remote_state.vpc.outputs.public_subnet_id
}