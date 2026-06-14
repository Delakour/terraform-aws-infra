variable "name" {
  type = string
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN allowed to read from this bucket"
  type        = string
  default     = null
}

variable "enable_cloudfront_access" {
  type    = bool
  default = false
}

variable "cors_rules" {
  description = "List of CORS rules"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = []
}

variable "tags" {
  type = map(string)
}
