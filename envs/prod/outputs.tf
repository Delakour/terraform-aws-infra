output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "private_route_table_id" {
  value = module.vpc.private_route_table_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "backend_api_domain" {
  value = aws_route53_record.backend_prod.fqdn
}

output "frontend_bucket_name" {
  value = module.frontend_bucket.bucket_name
}

output "cloudfront_domain" {
  value = module.frontend_bucket.bucket_domain_name
}

output "rag_create_queue_url" {
  description = "SQS queue URL for RAG creation"
  value       = module.sqs_rag_create.rag_create_queue_url
}

output "rag_create_queue_arn" {
  description = "SQS queue ARN for RAG creation"
  value       = module.sqs_rag_create.rag_create_queue_arn
}

output "rag_worker_pipe_arn" {
  description = "ARN of the EventBridge Pipe for RAG worker"
  value       = module.eventbridge_pipes_rag_worker.pipe_arn
}

output "rag_worker_pipe_name" {
  description = "Name of the EventBridge Pipe for RAG worker"
  value       = module.eventbridge_pipes_rag_worker.pipe_name
}
