variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "project_name" {
  type    = string
  default = "project-name"
}

variable "environment" {
  type    = string
  default = "local"
}

variable "tags" {
  type = map(string)
  default = {
    Owner       = "owner-name"
    Project     = "project-name"
    Environment = "local"
  }
}