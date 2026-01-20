variable "name" {
  type        = string
  description = "Base name for the ECS cluster"
}

variable "tags" {
  type = map(string)
}