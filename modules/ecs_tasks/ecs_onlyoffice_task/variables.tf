variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "log_group_name" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "onlyoffice_tasks_sg_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}