
resource "aws_route53_zone" "root" {
  name = var.hosted_zone_id
}

module "ssm" {
  source = "../../modules/ssm"

  name = "${var.project_name}-${var.environment}"
  env = var.environment
  parameters = {
    "AWS_ACCESS_KEY_ID" = {
      description = "AWS access key for authentication"
      type        = "SecureString"
      placeholder       = ""
    },
    "AWS_REGION" = {
      description = "AWS region for resource deployment"
      type        = "String"
      placeholder       = ""
    }
    "AWS_SECRET_ACCESS_KEY" = {
      description = "AWS secret access key for authentication"
      type        = "SecureString"
      placeholder       = ""
    }
    "DATABASE_NAME" = {
      description = "Primary database name"
      type        = "String"
      placeholder       = ""
    }
    "FERNET_KEY" = {
      description = "Encryption key for data security"
      type        = "SecureString"
      placeholder       = ""
    }
    "GEMINI_API_KEY" = {
      description = "Google Gemini AI API key"
      type        = "SecureString"
      placeholder       = ""
    }
    "GITHUB_TOKEN_RAG_SCRAPING" = {
      description = "GitHub token for RAG data scraping"
      type        = "SecureString"
      placeholder       = ""
    }
    "LINKEDIN_API_BASE_URL" = {
      description = "LinkedIn API base URL endpoint"
      type        = "String"
      placeholder       = ""
    }
    "LINKEDIN_API_VERSION" = {
      description = "LinkedIn API version number"
      type        = "String"
      placeholder       = ""
    }
    "LINKEDIN_BASE_URL" = {
      description = "LinkedIn platform base URL"
      type        = "String"
      placeholder       = ""
    }
    "LINKEDIN_CLIENT_ID" = {
      description = "LinkedIn OAuth client ID"
      type        = "SecureString"
      placeholder       = ""
    }
    "LINKEDIN_CLIENT_SECRET" = {
      description = "LinkedIn OAuth client secret"
      type        = "SecureString"
      placeholder       = ""
    }
    "LINKEDIN_RESTLI_PROTOCOL_VERSION" = {
      description = "LinkedIn RestLi protocol version"
      type        = "String"
      placeholder       = ""
    }
    "LINKEDIN_SCOPES" = {
      description = "LinkedIn API access scopes"
      type        = "String"
      placeholder       = ""
    }
    "MONGODB_NAME" = {
      description = "MongoDB database name"
      type        = "String"
      placeholder       = ""
    }
    "OPENAI_API_KEY" = {
      description = "OpenAI API key for AI services"
      type        = "SecureString"
      placeholder       = ""
    }
    "VECTOR_DB_DIR" = {
      description = "Vector database storage directory path"
      type        = "String"
      placeholder       = ""
    }
  }

  tags = var.tags
}