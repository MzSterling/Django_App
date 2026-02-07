# Look up the existing ECS execution role
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "django" {
  family                   = "django-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  
    # Use the existing role
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
    

  container_definitions = jsonencode([{
    name      = "django-app"
    image     = "${aws_ecr_repository.django_app.repository_url}:latest"
    essential = true
    portMappings = [
      {
        containerPort = 8000
        hostPort      = 8000
      }
    ]
  }])
}

resource "aws_ecs_service" "django_service" {
  name            = "django-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.django.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
}
