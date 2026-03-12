variable "name" {
  description = "The name prefix for resources"
  type        = string
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)"
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

variable "backend_image" {
  description = "Docker backend image from ECR repository"
  type = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
