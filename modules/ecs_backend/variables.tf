variable "name" {
  description = "The name prefix for resources"
  type        = string
}

variable "region" {
  type = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)"
  type        = string
}

variable "image_tag" {
  type = string
}

variable "ecr_repo_url" {
  description = "The ECR repository URL for the backend image"
  type        = string
}

variable "qdrant_url" {
  description = "The URL of the Qdrant service"
  type        = string
}

variable "qdrant_api_key" {
  description = "The API key for Qdrant"
  type        = string
}

variable "log_group_name" {
  description = "The name of the CloudWatch log group for ECS task logs"
  type        = string
}

variable "cluster_id" {
  description = "The ID of the ECS cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ECS service"
  type        = list(string)
}

variable "backend_tasks_sg_id" {
  type = string
}

variable "target_group_arn" {
  description = "The ARN of the ALB target group for the ECS service"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
