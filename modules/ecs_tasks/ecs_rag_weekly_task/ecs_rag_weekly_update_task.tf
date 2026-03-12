resource "aws_ecs_task_definition" "rag_weekly_update" {
  family                   = "${var.name}-rag-weekly-update"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "rag-weekly-update"
      image     = var.backend_image
      essential = true

      command = ["python", "-m", "app.application.jobs.weekly_rag_job"]

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]

      secrets = var.ssm_params

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.region
          awslogs-stream-prefix = "rag-weekly-update"
        }
      }
    }
  ])
}
