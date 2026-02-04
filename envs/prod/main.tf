data "terraform_remote_state" "route53" {
  backend = "s3"

  config = {
    bucket = "terraform-state"
    key    = "global/route53-ssm/terraform.tfstate"
    region = "eu-north-1"
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "ssm" {
  source = "../../modules/ssm"

  name = local.name_prefix
  env = var.environment
  parameters = {
    "SSM_PARAMS_NAME" = {
      description = "short description"
      type        = "String | SecureString"
      placeholder = "the value will be set manually on the aws console or via GitHub secrets"
    }
  }
  tags = var.tags
}

module "vpc" {
  source = "../../modules/vpc"

  name            = local.name_prefix
  cidr_block      = var.vpc_cidr
  azs             = var.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  tags = var.tags
}

resource "aws_route" "private_to_atlas" {
  route_table_id = module.vpc.private_route_table_id

  # ⚠️ Note that these two variables - their values are hardocoded in envs/prod/variables.tf
  destination_cidr_block    = var.atlas_vpc_cidr
  vpc_peering_connection_id = var.atlas_peering_connection_id
}

module "security" {
  source = "../../modules/security"

  name             = local.name_prefix
  vpc_id           = module.vpc.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
  tags             = var.tags
}

module "ecr"  {
  source = "../../modules/ecr"

  name        = local.name_prefix
  tags        = var.tags
}

module "ecs_cluster" {
  source      = "../../modules/ecs-cluster"
  
  name        = local.name_prefix
  tags        = var.tags
}

module "cloudwatch_logs" {
  source = "../../modules/cloudwatch_logs"

  name = local.name_prefix
  log_groups = {
    "/ecs/${local.name_prefix}-backend-logs" = {
      retention_in_days = 14
    }
  }

  tags = var.tags
}

module "ecs_backend" {
  source = "../../modules/ecs_backend"

  name                = local.name_prefix
  region              = var.aws_region
  environment         = var.environment
  image_tag           = var.environment
  ecr_repo_url        = module.ecr.repository_url
  qdrant_url          = var.qdrant_url
  qdrant_api_key      = var.qdrant_api_key
  log_group_name      = "/ecs/${local.name_prefix}-backend-logs"
  cluster_id          = module.ecs_cluster.cluster_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  backend_tasks_sg_id = module.security.backend_sg_id
  target_group_arn    = module.alb.target_group_arn

  tags = var.tags
}

# module "ec2_app" {
#   source = "../../modules/ec2"

#   name              = local.name_prefix
#   instance_type     = var.instance_type
#   subnet_id         = element(module.vpc.private_subnet_ids, 0)
#   security_group_id = module.security.backend_sg_id
#   root_volume_size  = var.root_volume_size

#   environment = var.environment

#   s3_brandbook_arn    = module.brandbook_bucket.bucket_arn
#   s3_local_folder_arn = module.local_folder_bucket.bucket_arn
#   s3_story_portal_arn = module.story_portal_bucket.bucket_arn
#   s3_vectors_arn      = module.vectors_bucket.bucket_arn
#   tags                = var.tags

# }

module "alb" {
  source = "../../modules/alb"

  name              = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.security.alb_sg_id
  target_instance_ids = {
    # app = module.ec2_app.instance_id
  }
  health_check_path   = var.health_check_path
  alb_certificate_arn = var.alb_certificate_arn
  tags                = var.tags
}

module "local_folder_bucket" {
  source = "../../modules/s3"

  name = "${local.name_prefix}-local-folder"
  tags = var.tags
}

module "brandbook_bucket" {
  source = "../../modules/s3"

  name = "${local.name_prefix}-brandbook"
  tags = var.tags
}

module "story_portal_bucket" {
  source = "../../modules/s3"

  name = "${local.name_prefix}-story-portal"
  tags = var.tags
}

# module "vectors_bucket" {
#   source = "../../modules/s3"

#   name = "${local.name_prefix}-vectors"
#   tags = var.tags
# }

module "frontend_bucket" {
  source = "../../modules/s3"

  name                        = "${local.name_prefix}-frontend"
  cloudfront_distribution_arn = module.frontend_cdn.distribution_arn
  enable_cloudfront_access    = true
  tags                        = var.tags
}

module "frontend_cdn" {
  source = "../../modules/cloudfront"

  name               = local.name_prefix
  origin_domain_name = module.frontend_bucket.bucket_domain_name
  aliases            = [var.frontend_domain]
  acm_cert_arn       = var.acm_certificate_arn
  tags               = var.tags
}

resource "aws_route53_record" "frontend_prod" {
  zone_id = data.terraform_remote_state.route53.outputs.hosted_zone_id
  name    = var.frontend_domain
  type    = "A"

  alias {
    name                   = module.frontend_cdn.domain_name
    zone_id                = module.frontend_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "backend_prod" {
  zone_id = data.terraform_remote_state.route53.outputs.hosted_zone_id
  name    = var.backend_domain
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

