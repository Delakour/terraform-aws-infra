variable "project_name" {
  type        = string
  description = "Base project name"
  default     = "project-name"
}

variable "environment" {
  type        = string
  default     = "global"
}
variable "hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for domain.com"
  default = "domain.com"
}

variable "tags" {
  type = map(string)
  default = {
    Owner       = "owner-name"
    Project     = "project-name"
    Environment = "global"
  }
}