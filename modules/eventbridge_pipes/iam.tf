resource "aws_iam_role" "eventbridge_pipe" {
  name = "${var.name}-eventbridge-pipe-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pipes.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Permission to read from SQS
resource "aws_iam_role_policy" "sqs_source" {
  name = "${var.name}-pipe-sqs-source"
  role = aws_iam_role.eventbridge_pipe.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

# Permission to run ECS tasks
resource "aws_iam_role_policy" "ecs_target" {
  name = "${var.name}-pipe-ecs-target"
  role = aws_iam_role.eventbridge_pipe.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask"
        ]
        Resource = var.ecs_task_definition_arn
        Condition = {
          ArnEquals = {
            "ecs:cluster" = var.ecs_cluster_arn
          }
        }
      }
    ]
  })
}

# Permission to pass IAM roles to ECS
resource "aws_iam_role_policy" "pass_role" {
  name = "${var.name}-pipe-pass-role"
  role = aws_iam_role.eventbridge_pipe.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          var.ecs_task_execution_role_arn,
          var.ecs_task_role_arn
        ]
      }
    ]
  })
}