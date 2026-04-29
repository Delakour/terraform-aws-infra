output "rag_create_queue_url" {
  description = "SQS queue URL for local RAG creation"
  value       = module.sqs_rag_create.rag_create_queue_url
}

output "rag_create_queue_arn" {
  description = "SQS queue ARN for local RAG creation"
  value       = module.sqs_rag_create.rag_create_queue_arn
}

output "rag_create_queue_name" {
  description = "SQS queue name"
  value       = module.sqs_rag_create.rag_create_queue_name
}