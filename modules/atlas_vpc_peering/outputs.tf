output "atlas_container_id" {
  value       = try(mongodbatlas_network_container.network_container.container_id, null)
  description = "Atlas network container ID"
}

output "atlas_peering_connection_id" {
  value       = try(mongodbatlas_network_peering.network_peering.connection_id, null)
  description = "Atlas peering connection ID"
}

output "atlas_peering_status" {
  value       = try(mongodbatlas_network_peering.network_peering.status_name, null)
  description = "Atlas peering status"
}

output "atlas_cidr_block" {
  value       = var.atlas_cidr_block
  description = "Atlas CIDR block routed from AWS"
}