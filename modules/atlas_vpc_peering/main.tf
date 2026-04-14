resource "mongodbatlas_network_container" "network_container" {

  project_id       = var.atlas_project_id
  atlas_cidr_block = var.atlas_cidr_block
  provider_name    = "AWS"
  region_name      = var.atlas_region
}

resource "mongodbatlas_network_peering" "network_peering" {

  project_id             = var.atlas_project_id
  container_id           = mongodbatlas_network_container.network_container.container_id
  provider_name          = "AWS"
  accepter_region_name   = var.aws_region
  aws_account_id         = var.aws_account_id
  route_table_cidr_block = var.vpc_cidr_block
  vpc_id                 = var.vpc_id
}

resource "aws_vpc_peering_connection_accepter" "vpc_connection_accepter" {

  vpc_peering_connection_id = mongodbatlas_network_peering.network_peering.connection_id
  auto_accept               = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  tags = merge(var.tags, {
    Name = "${var.name}-atlas-peering"
  })
}

resource "aws_route" "atlas_routes" {
  for_each = toset(var.route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.atlas_cidr_block
  vpc_peering_connection_id = mongodbatlas_network_peering.network_peering.connection_id
}

resource "mongodbatlas_project_ip_access_list" "aws_vpc_cidr" {

  project_id = var.atlas_project_id
  cidr_block = var.vpc_cidr_block
  comment    = var.atlas_ip_access_list_comment
}
