
resource "aws_route53_zone" "root" {
  name = var.hosted_zone_id
}

module "ssm" {
  source = "../../modules/ssm"

  name = "${var.project_name}-${var.environment}"
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