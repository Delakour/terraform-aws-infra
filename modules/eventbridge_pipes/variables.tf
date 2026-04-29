variable "name" {
  description = "Base name for resources"
  type        = string
}

variable "region" {
  type = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue to use as source"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition to run"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}