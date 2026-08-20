data "aws_caller_identity" "current" {}

data "terraform_remote_state" "prod" {
  backend = "s3"

  config = {
    bucket = "terraform-state"
    key    = "envs/prod/terraform.tfstate"
    region = "eu-north-1"
  }
}

module "atlas_vpc_peering" {
  source = "../../modules/atlas_vpc_peering"

  name             = local.name_prefix
  atlas_project_id = var.atlas_project_id
  atlas_region     = var.atlas_region
  atlas_cidr_block = var.atlas_cidr_block

  aws_region      = var.aws_region
  aws_account_id  = data.aws_caller_identity.current.account_id
  vpc_id          = data.terraform_remote_state.prod.outputs.vpc_id
  vpc_cidr_block  = data.terraform_remote_state.prod.outputs.vpc_cidr_block
  route_table_ids = [data.terraform_remote_state.prod.outputs.private_route_table_id]

  tags = var.tags
}
