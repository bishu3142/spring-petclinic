resource "aws_ecr_repository" "devops-ecr" {
  name                 = "devops-ecr"
  region               = var.region
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "main" {
  name = "gitops-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "petclinic"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 512
  memory = 1024

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "petclinic-con"
      image = "${aws_ecr_repository.devops-ecr.repository_url}:latest"

      essential              = true
      readonlyRootFilesystem = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])
}

#Load Balancer SG
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  description = "load balancer security group"
  ingress {
    description = "Allow HTTP traffic from internet"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Task SG

resource "aws_security_group" "ecs" {
  name        = "ecs-sg"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  description = "ECS security Group"
  ingress {
    description = "Allow HTTP traffic from internet"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
}

resource "aws_lb" "main" {
  name                       = "petclinic-alb"
  internal                   = false
  load_balancer_type         = "application"
  drop_invalid_header_fields = true

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = data.terraform_remote_state.vpc.outputs.public_subnet_id
}

resource "aws_lb_target_group" "app" {
  name        = "petclinic-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"

  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_ecs_service" "app" {
  name            = "petclinic-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn

  desired_count = 2
  launch_type   = "FARGATE"

  network_configuration {
    subnets = data.terraform_remote_state.vpc.outputs.private_subnet_id

    security_groups = [
      aws_security_group.ecs.id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "petclinic-con"
    container_port   = 8080
  }

  depends_on = [
    aws_lb_listener.http
  ]
}
