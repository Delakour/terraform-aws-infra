variable "name" {
  type = string
}

variable "atlas_project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "atlas_region" {
  type        = string
  description = "Atlas region name for AWS, for example EU_NORTH_1"
}

variable "atlas_cidr_block" {
  type        = string
  description = "CIDR block for the Atlas network container. Must not overlap AWS VPC CIDR"
}

variable "aws_region" {
  type        = string
  description = "AWS region, for example eu-north-1"
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID that owns the VPC"
}

variable "vpc_id" {
  type        = string
  description = "AWS VPC ID to peer with Atlas"
}

variable "vpc_cidr_block" {
  type        = string
  description = "AWS VPC CIDR block"
}

variable "route_table_ids" {
  type        = list(string)
  description = "Route tables that need a route to Atlas CIDR, usually private route tables"
}

variable "atlas_ip_access_list_comment" {
  type        = string
  description = "Comment for Atlas IP access list entry"
  default     = "Allow AWS VPC over peering"
}

variable "tags" {
  type = map(string)
}
