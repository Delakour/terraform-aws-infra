locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Create local SQS queue using existing module
module "sqs_rag_create" {
  source = "../../modules/sqs"

  name = local.name_prefix
  tags = var.tags
}