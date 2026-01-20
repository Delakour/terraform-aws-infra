variable "name" {
  type = string
}

variable "origin_domain_name" {
  type = string
}

variable "aliases" {
  type = list(string)
}

variable "acm_cert_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}
