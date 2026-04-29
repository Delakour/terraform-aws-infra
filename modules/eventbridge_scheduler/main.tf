resource "aws_scheduler_schedule" "rag_weekly_update" {
  name = "${var.name}-rag-weekly-update"

  schedule_expression          = "cron(0 6 ? * FRI *)"
  schedule_expression_timezone = "Asia/Jerusalem"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = var.cluster_arn
    role_arn = aws_iam_role.eventbridge_ecs_role.arn


    retry_policy {
      maximum_event_age_in_seconds = 7200
      maximum_retry_attempts       = 5
    }

    ecs_parameters {
      task_definition_arn = var.ecs_task_definition_arn
      launch_type         = "FARGATE"
      task_count          = 1

      network_configuration {
        subnets         = var.private_subnet_ids
        security_groups = [var.ecs_tasks_sg_id]
      }
    }
  }
}
