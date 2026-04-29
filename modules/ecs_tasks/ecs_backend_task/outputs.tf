output "execution_role_arn" {
  value = aws_iam_role.execution.arn
}

output "task_role_arn" {
  value = aws_iam_role.task.arn
}

output "task_definition_arn" {
  description = "ARN of the backend task definition"
  value       = aws_ecs_task_definition.backend_task.arn
}

output "task_definition_family" {
  description = "Family name of the backend task definition"
  value       = aws_ecs_task_definition.backend_task.family
}