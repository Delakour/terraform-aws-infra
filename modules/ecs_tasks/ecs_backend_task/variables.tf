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

variable "ssm_params" {
  description = "List of SSM parameters to be used as secrets in the ECS task"
  type = list(object({
    name      = string
    valueFrom = string
  }))
}

variable "log_group_name" {
  description = "The name of the CloudWatch log group for ECS task logs"
  type        = string
}

variable "cluster_arn" {
  description = "The ECS cluster ID"
  type        = string
}

variable "cluster_name" {
  description = "The ECS cluster name"
  type = string
}

variable "min_instances" {
  description = "minimum instances of task running"
  type = number
}

variable "max_instances" {
  description = "maximum instances of task running"
  type = number
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