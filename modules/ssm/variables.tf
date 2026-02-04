variable "name" {
  type = string
}

variable "env" {
  type = string
}

variable "parameters" {
  description = "List of SSM parameters to create"
  type = map(object({
    description = string
    type        = string # String | SecureString
    placeholder = optional(string)
  }))
}

variable "tags" {
  type = map(string)
}
