resource "aws_ecs_task_definition" "onlyoffice_task" {
  family                   = "${var.name}-onlyoffice-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = "2048"
  memory = "4096"

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name  = "onlyoffice"
    image = "onlyoffice/documentserver:9.4.0"

    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]

    environment = [
      { name = "JWT_ENABLED", value = "true" },
      { name = "ALLOW_PRIVATE_IP_ADDRESS", value = "true" }
    ]
    secrets = [
      {
        name      = "JWT_SECRET"
        valueFrom = "/company/global/ONLYOFFICE_JWT_SECRET"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_name
        awslogs-region        = var.region
        awslogs-stream-prefix = "onlyoffice"
      }
    }
  }])
}

resource "aws_ecs_service" "onlyoffice_service" {
  name            = "${var.name}-onlyoffice-service"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.onlyoffice_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  enable_execute_command = true

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.onlyoffice_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "onlyoffice"
    container_port   = 80
  }

  # OO takes ~3 minutes to start; give it time before ALB health checks fail the service
  health_check_grace_period_seconds = 300
}
