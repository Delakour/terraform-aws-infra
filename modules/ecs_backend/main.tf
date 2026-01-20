resource "aws_ecs_task_definition" "backend_task" {
  family                   = "${var.name}-backend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = "1024"
  memory = "2048"

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name  = "backend"
    image = "${var.ecr_repo_url}:${var.image_tag}"

    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]

    environment = [
      { name = "QDRANT_URL", value = var.qdrant_url },
      { name = "QDRANT_API_KEY", value = var.qdrant_api_key }
    ]

    secrets = [
      { name = "MONGODB_URL", valueFrom = "/${var.environment}/MONGODB_URL" },
      { name = "MONGODB_NAME", valueFrom = "/global/MONGODB_NAME" },
      { name = "DATABASE_NAME", valueFrom = "/global/DATABASE_NAME" },
      { name = "OPENAI_API_KEY", valueFrom = "/global/OPENAI_API_KEY" },
      { name = "FERNET_KEY", valueFrom = "/global/FERNET_KEY" },
      { name = "AWS_REGION", valueFrom = "/global/AWS_REGION" },
      { name = "S3_LOCAL_FOLDER_NAME", valueFrom = "/${var.environment}/S3_LOCAL_FOLDER_NAME" },
      { name = "S3_BRANDBOOK_NAME", valueFrom = "/${var.environment}/S3_BRANDBOOK_NAME" },
      { name = "S3_STORYPORTAL_NAME", valueFrom = "/${var.environment}/S3_STORYPORTAL_NAME" },
      { name = "GEMINI_API_KEY", valueFrom = "/global/GEMINI_API_KEY" },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "backend_service" {
  name            = "${var.name}-backend-service"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.backend_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "backend"
    container_port   = 8000
  }

  health_check_grace_period_seconds = 60
}
