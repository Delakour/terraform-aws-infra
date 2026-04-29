output "rag_create_queue_url" {
  value = aws_sqs_queue.rag_create.url
}

output "rag_create_queue_arn" {
  value = aws_sqs_queue.rag_create.arn
}

output "rag_create_queue_name" {
  value = aws_sqs_queue.rag_create.name
}