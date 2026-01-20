variable "name" {
  type = string
}

variable "log_groups" {
  description = "Map of log group names to retention days"
  type = map(object({
    retention_in_days = number
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
