data "terraform_remote_state" "route53" {
  backend = "s3"

  config = {
    bucket = "terraform-state"
    key    = "global/route53-ssm/terraform.tfstate"
    region = "eu-north-1"
  }
}

module "ssm" {
  source = "../../modules/ssm"

  name = local.name_prefix
  env  = var.environment
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
  tags            = var.tags
}

module "security" {
  source = "../../modules/security"

  name             = local.name_prefix
  vpc_id           = module.vpc.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
  tags             = var.tags
}

module "ecr" {
  source = "../../modules/ecr"

  name = local.name_prefix
  tags = var.tags
}

module "ecs_cluster" {
  source = "../../modules/ecs_cluster"

  name = local.name_prefix
  tags = var.tags
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
  source = "../../modules/ecs_tasks/ecs_backend_task"

  name                = local.name_prefix
  region              = var.aws_region
  environment         = var.environment
  image_tag           = var.environment
  ecr_repo_url        = module.ecr.repository_url
  ssm_params          = local.backend_secrets
  log_group_name      = "/ecs/${local.name_prefix}-backend-logs"
  cluster_arn         = module.ecs_cluster.cluster_arn
  cluster_name        = module.ecs_cluster.cluster_name
  min_instances       = 1
  max_instances       = 8
  private_subnet_ids  = module.vpc.private_subnet_ids
  backend_tasks_sg_id = module.security.backend_sg_id
  target_group_arn    = module.alb.target_group_arn

  tags = var.tags
}

module "ecs_onlyoffice" {
  source = "../../modules/ecs_tasks/ecs_onlyoffice_task"

  name                   = local.name_prefix
  region                 = var.aws_region
  environment            = var.environment
  log_group_name         = "/ecs/${local.name_prefix}-backend-logs"
  cluster_arn            = module.ecs_cluster.cluster_arn
  cluster_name           = module.ecs_cluster.cluster_name
  private_subnet_ids     = module.vpc.private_subnet_ids
  onlyoffice_tasks_sg_id = module.security.onlyoffice_sg_id
  target_group_arn       = module.alb.onlyoffice_target_group_arn

  tags = var.tags
}

module "ecs_rag_weekly_update" {
  source = "../../modules/ecs_tasks/ecs_rag_weekly_task"

  name           = local.name_prefix
  region         = var.aws_region
  environment    = var.environment
  ssm_params     = local.backend_secrets
  log_group_name = "/ecs/${local.name_prefix}-backend-logs"
  backend_image  = local.backend_image

  tags = var.tags
}

module "eventbridge_rag_weekly_update" {
  source = "../../modules/eventbridge_scheduler"

  name                    = local.name_prefix
  cluster_arn             = module.ecs_cluster.cluster_arn
  ecs_task_definition_arn = module.ecs_rag_weekly_update.task_definition_arn
  private_subnet_ids      = module.vpc.private_subnet_ids
  ecs_tasks_sg_id         = module.security.backend_sg_id

  tags = var.tags
}

module "sqs_rag_create" {
  source = "../../modules/sqs"

  name = local.name_prefix
  tags = var.tags
}

# RAG Worker Task Definition (dedicated for async RAG creation)
module "ecs_rag_worker" {
  source = "../../modules/ecs_tasks/ecs_rag_worker_task"

  name           = local.name_prefix
  region         = var.aws_region
  environment    = var.environment
  ssm_params     = local.backend_secrets
  log_group_name = "/ecs/${local.name_prefix}-backend-logs"
  backend_image  = local.backend_image

  tags = var.tags
}

# EventBridge Pipes for SQS → ECS RunTask (RAG Worker)
module "eventbridge_pipes_rag_worker" {
  source = "../../modules/eventbridge_pipes"

  name                        = local.name_prefix
  region                      = var.aws_region
  sqs_queue_arn               = module.sqs_rag_create.rag_create_queue_arn
  ecs_cluster_arn             = module.ecs_cluster.cluster_arn
  ecs_task_definition_arn     = module.ecs_rag_worker.task_definition_arn
  ecs_task_execution_role_arn = module.ecs_rag_worker.execution_role_arn
  ecs_task_role_arn           = module.ecs_rag_worker.task_role_arn
  private_subnet_ids          = module.vpc.private_subnet_ids
  security_group_id           = module.security.backend_sg_id

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
  health_check_path            = var.health_check_path
  onlyoffice_health_check_path = var.onlyoffice_health_check_path
  alb_certificate_arn          = var.alb_certificate_arn
  onlyoffice_domain            = var.onlyoffice_domain
  tags                         = var.tags
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

  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = var.s3_cors_allowed_origins
      expose_headers  = []
      max_age_seconds = 3000
    }
  ]

  tags = var.tags
}

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

resource "aws_route53_record" "onlyoffice_prod" {
  zone_id = data.terraform_remote_state.route53.outputs.hosted_zone_id
  name    = var.onlyoffice_domain
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}
