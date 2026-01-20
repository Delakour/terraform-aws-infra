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
  default     = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-north-1a", "eu-north-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/20", "10.0.16.0/20"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.128.0/20", "10.0.144.0/20"]
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "Your office IP/CIDR for SSH (e.g. 1.2.3.4/32)"
  default     = "37.186.124.179/32"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "root_volume_size" {
  type        = number
  description = "Root EBS size in GB"
  default     = 30
}

variable "health_check_path" {
  type    = string
  description = "The health check parameters for an ALB target group"
  default = "/health"
}

variable "qdrant_url" {
  type        = string
  description = "The URL of the Qdrant service"
  default     = ""
}

variable "qdrant_api_key" {
  type        = string
  description = "The API key for the Qdrant service"
  default     = ""
}

variable "frontend_domain" {
  type        = string
  description = "Frontend domain"
  default     = "dev.domain.com"
}

variable "backend_domain" {
  type        = string
  description = "Backend domain behind ALB"
  default     = "api.dev.domain.com"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for *.domain.com (must be in us-east-1 for CloudFront)"
  default = "arn:aws:acm:us-east-1:<account-id>:certificate/<certificate-id>"
}

variable "alb_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for backend ALB (in app region, eu-north-1)"
  default = "arn:aws:acm:<aws-region>:<account-id>:certificate/<certificate-id>"
}

variable "tags" {
  type = map(string)
  default = {
    Owner       = "owner-name"
    Project     = "project-name"
    Environment = "dev"
  }
}
