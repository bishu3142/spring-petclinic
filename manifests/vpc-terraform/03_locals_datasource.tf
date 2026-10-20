data "aws_availability_zones" "avalibility_zone" {
  state = "available"
}

locals {
  zones         = slice(data.aws_availability_zones.avalibility_zone.names, 0, 3)
  public_cidrs  = [for i in range(length(local.zones)) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_cidrs = [for i in range(length(local.zones)) : cidrsubnet(var.vpc_cidr, 8, i + 10)]
}