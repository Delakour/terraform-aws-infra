variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "target_instance_ids" {
  type = map(string)
}

variable "health_check_path" {
  type = string
}

variable "alb_certificate_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}
