variable "name" {
  description = "The name prefix for resources"
  type        = string
}

variable "cluster_arn" {
  description = "The ARN of the ECS cluster to run the task in"
  type        = string
}

variable "ecs_task_definition_arn" {
  description = "The ARN of the ECS task definition to run"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ECS task network configuration"
  type        = list(string)
}

variable "ecs_tasks_sg_id" {
  description = "The security group ID for the ECS tasks to use"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
