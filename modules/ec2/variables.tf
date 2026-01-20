variable "name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "root_volume_size" {
  type = number
}

variable "environment" {
  type = string
}

variable "s3_brandbook_arn" {
  type = string
}

variable "s3_local_folder_arn" {
  type = string
}

variable "s3_story_portal_arn" {
  type = string
}

# variable "s3_vectors_arn" {
#   type = string
# }

variable "tags" {
  type = map(string)
}
