resource "aws_sqs_queue" "rag_create_dlq" {
  name = "${var.name}-rag-create-dlq"
}

resource "aws_sqs_queue" "rag_create" {
  name                       = "${var.name}-rag-create"
  visibility_timeout_seconds = 4200 # 70 min
  receive_wait_time_seconds  = 20   # long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.rag_create_dlq.arn
    maxReceiveCount     = 5
  })
  tags = merge(var.tags, {
    Name = "${var.name}-sqs-rag-create"
  })
}

# IAM policies
resource "aws_iam_policy" "backend_send_rag_jobs" {
  name = "${var.name}-backend-send-rag-jobs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.rag_create.arn
      }
    ]
  })
}

resource "aws_iam_policy" "rag_worker_sqs" {
  name = "${var.name}-rag-worker-sqs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.rag_create.arn
      }
    ]
  })
}