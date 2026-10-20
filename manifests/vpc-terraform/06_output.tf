output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_arn" {
  value = aws_vpc.main.arn
}

output "public_subnet_id" {
  value = [for i in aws_subnet.public_subnet : i.id]
}

output "private_subnet_id" {
  value = [for i in aws_subnet.private_subnet : i.id]
}

output "private_subnet_map" {
  value = { for az, subnet in aws_subnet.private_subnet : az => subnet.id }
}

output "public_subnet_map" {
  value = { for az, subnet in aws_subnet.public_subnet : az => subnet.id }
}


