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

variable "tags" {
  type = map(string)
}
