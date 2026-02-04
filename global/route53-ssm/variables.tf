variable "project_name" {
  type        = string
  description = "Base project name"
  default     = "parpar"
}

variable "environment" {
  type        = string
  default     = "global"
}
variable "hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for parparsoftware.com"
  default = "parparsoftware.com"
}

variable "tags" {
  type = map(string)
  default = {
    Owner       = "parpar"
    Project     = "parpar-mvp"
    Environment = "global"
  }
}