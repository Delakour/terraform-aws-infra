output "pipe_arn" {
  description = "ARN of the EventBridge Pipe"
  value       = aws_pipes_pipe.sqs_to_ecs.arn
}

output "pipe_name" {
  description = "Name of the EventBridge Pipe"
  value       = aws_pipes_pipe.sqs_to_ecs.name
}

output "pipe_role_arn" {
  description = "ARN of the IAM role used by the pipe"
  value       = aws_iam_role.eventbridge_pipe.arn
}