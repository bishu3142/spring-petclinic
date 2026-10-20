output "ecr_name" {
  value = aws_ecr_repository.devops-ecr.name
}

output "ecs_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_task_definition" {
  value = aws_ecs_task_definition.app
}

output "aws_ecs_service" {
  value = aws_ecs_service.app.id
}
