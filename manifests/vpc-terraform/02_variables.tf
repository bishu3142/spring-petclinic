variable "region" {
  description = "Region valus"
  type        = string
  default     = "us-east-1"
}

variable "environment_name" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "tags" {
  type = map(string)
  default = {
    Terraform = "true"
  }

}