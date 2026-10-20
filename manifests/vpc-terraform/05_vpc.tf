resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(
    var.tags, { name = "${var.environment_name}-vpc" }
  )
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "public_subnet" {
  for_each                = { for idx, az in local.zones : az => local.public_cidrs[idx] }
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = merge(
    var.tags, { name = "${var.environment_name}-public-subnet" }
  )
}

resource "aws_subnet" "private_subnet" {
  for_each          = { for idx, az in local.zones : az => local.private_cidrs[idx] }
  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(
    var.tags, { name = "${var.environment_name}-private-subnet" }
  )

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags, { name = "${var.environment_name}-igw" }
  )
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags, { name = "${var.environment_name}-public_route" }
  )
}

resource "aws_route_table_association" "public_rt_assoc" {
  for_each       = aws_subnet.public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route.id

}

resource "aws_eip" "eip" {
  tags = merge(
    var.tags, { name = "${var.environment_name}-eip" }
  )
}

resource "aws_nat_gateway" "nat-igw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = values(aws_subnet.private_subnet)[0].id

  tags = merge(
    var.tags, { name = "${var.environment_name}-nat-igw" }
  )

  depends_on = [aws_internet_gateway.igw]
}


resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-igw.id
  }

  tags = merge(
    var.tags, { name = "${var.environment_name}-private_route" }
  )
}

resource "aws_route_table_association" "private_rt_assoc" {
  for_each       = aws_subnet.private_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route.id
}


