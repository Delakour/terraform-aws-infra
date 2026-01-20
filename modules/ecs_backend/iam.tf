data "aws_caller_identity" "current" {}

resource "aws_iam_role" "execution" {
  name = "${var.name}-ecs-backend-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_ssm" {
  name = "${var.name}-ecs-backend-execution-ssm"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      Resource = [
        "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/global/*",
        "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/*"
      ]
    }]
  })
}

resource "aws_iam_role" "task" {
  name = "${var.name}-ecs-backend-task"

  assume_role_policy = aws_iam_role.execution.assume_role_policy
}

resource "aws_iam_role_policy" "task_s3" {
  name = "${var.name}-ecs-backend-task-s3"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = ["*"]
    }]
  })
}
