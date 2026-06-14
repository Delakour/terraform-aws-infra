resource "aws_ecs_task_definition" "rag_worker" {
  family                   = "${var.name}-rag-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024" # Same as backend for consistency
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "rag-worker"
      image     = var.backend_image
      essential = true

      # Command to run worker in single-job mode
      command = [
        "python",
        "-m",
        "app.application.jobs.rag_worker",
        "--mode",
        "single"
      ]

      environment = [
        {
          name  = "WORKER_MODE"
          value = "single"
        }
      ]

      secrets = var.ssm_params

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.region
          awslogs-stream-prefix = "rag-worker"
        }
      }
    }
  ])

  tags = var.tags
}
