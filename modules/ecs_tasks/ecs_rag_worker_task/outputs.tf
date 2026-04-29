output "task_definition_arn" {
  description = "ARN of the RAG worker task definition"
  value       = aws_ecs_task_definition.rag_worker.arn
}

output "task_definition_family" {
  description = "Family name of the RAG worker task definition"
  value       = aws_ecs_task_definition.rag_worker.family
}

output "execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = aws_iam_role.task.arn
}
