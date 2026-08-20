variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-north-1"
}

variable "project_name" {
  type        = string
  description = "Base project name"
  default     = "project-name"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/prod)"
  default     = "prod"
}

variable "atlas_project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
  default     = "69xxxxxxxxxxxxxxxxxxxxxx"
}

variable "atlas_cidr_block" {
  type        = string
  description = "CIDR block for the Atlas network container. Must not overlap AWS VPC CIDR"
  default     = ""
}

variable "atlas_public_key" {
  type      = string
  sensitive = true
}

variable "atlas_private_key" {
  type      = string
  sensitive = true
}

variable "atlas_region" {
  type    = string
  default = "EU_WEST_1"
}

variable "tags" {
  type = map(string)
  default = {
    Owner       = "owner-name"
    Project     = "project-name"
    Environment = "prod"
  }
}
