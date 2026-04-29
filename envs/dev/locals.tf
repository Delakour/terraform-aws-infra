locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

locals {
  backend_image = "${module.ecr.repository_url}:${var.environment}"
}

locals {
  backend_secrets = [
    # environment ssm
    { name = "LINKEDIN_REDIRECT_URI", valueFrom = "/company/${var.environment}/LINKEDIN_REDIRECT_URI" },
    { name = "MONGODB_URL", valueFrom = "/company/${var.environment}/MONGODB_URL" },
    { name = "QDRANT_API_KEY", valueFrom = "/company/${var.environment}/QDRANT_API_KEY" },
    { name = "QDRANT_URL", valueFrom = "/company/${var.environment}/QDRANT_URL" },
    { name = "S3_BRANDBOOK_BUCKET_NAME", valueFrom = "/company/${var.environment}/S3_BRANDBOOK_BUCKET_NAME" },
    { name = "S3_LOCAL_FOLDER_BUCKET_NAME", valueFrom = "/company/${var.environment}/S3_LOCAL_FOLDER_BUCKET_NAME" },
    { name = "S3_STORYPORTAL_BUCKET_NAME", valueFrom = "/company/${var.environment}/S3_STORYPORTAL_BUCKET_NAME" },
    { name = "GOOGLE_JAVASCRIPT_ORIGINS", valueFrom = "/company/${var.environment}/GOOGLE_JAVASCRIPT_ORIGINS" },
    { name = "GOOGLE_REDIRECT_URIS", valueFrom = "/company/${var.environment}/GOOGLE_REDIRECT_URIS" },
    { name = "RAG_CREATE_QUEUE_URL", valueFrom = "/company/${var.environment}/RAG_CREATE_QUEUE_URL" },
    { name = "PROXY_ENABLED", valueFrom = "/company/${var.environment}/PROXY_ENABLED"},
    { name = "USE_SCRAPERAPI_DIRECT", valueFrom = "/company/${var.environment}/USE_SCRAPERAPI_DIRECT" },
    # global ssm
    { name = "AWS_ACCESS_KEY_ID", valueFrom = "/company/global/AWS_ACCESS_KEY_ID" },
    { name = "AWS_REGION", valueFrom = "/company/global/AWS_REGION" },
    { name = "AWS_SECRET_ACCESS_KEY", valueFrom = "/company/global/AWS_SECRET_ACCESS_KEY" },
    { name = "DATABASE_NAME", valueFrom = "/company/global/DATABASE_NAME" },
    { name = "FERNET_KEY", valueFrom = "/company/global/FERNET_KEY" },
    { name = "GEMINI_API_KEY", valueFrom = "/company/global/GEMINI_API_KEY" },
    { name = "GITHUB_TOKEN_RAG_SCRAPING", valueFrom = "/company/global/GITHUB_TOKEN_RAG_SCRAPING" },
    { name = "GOOGLE_CLIENT_ID", valueFrom = "/company/global/GOOGLE_CLIENT_ID" },
    { name = "GOOGLE_CLIENT_SECRET", valueFrom = "/company/global/GOOGLE_CLIENT_SECRET" },
    { name = "GOOGLE_PROJECT_ID", valueFrom = "/company/global/GOOGLE_PROJECT_ID" },
    { name = "GOOGLE_AUTH_URI", valueFrom = "/company/global/GOOGLE_AUTH_URI" },
    { name = "GOOGLE_TOKEN_URI", valueFrom = "/company/global/GOOGLE_TOKEN_URI" },
    { name = "GOOGLE_AUTH_PROVIDER_CERT_URL", valueFrom = "/company/global/GOOGLE_AUTH_PROVIDER_CERT_URL" },
    { name = "LINKEDIN_API_BASE_URL", valueFrom = "/company/global/LINKEDIN_API_BASE_URL" },
    { name = "LINKEDIN_API_VERSION", valueFrom = "/company/global/LINKEDIN_API_VERSION" },
    { name = "LINKEDIN_BASE_URL", valueFrom = "/company/global/LINKEDIN_BASE_URL" },
    { name = "LINKEDIN_CLIENT_ID", valueFrom = "/company/global/LINKEDIN_CLIENT_ID" },
    { name = "LINKEDIN_CLIENT_SECRET", valueFrom = "/company/global/LINKEDIN_CLIENT_SECRET" },
    { name = "LINKEDIN_RESTLI_PROTOCOL_VERSION", valueFrom = "/company/global/LINKEDIN_RESTLI_PROTOCOL_VERSION" },
    { name = "LINKEDIN_SCOPES", valueFrom = "/company/global/LINKEDIN_SCOPES" },
    { name = "MONGODB_NAME", valueFrom = "/company/global/MONGODB_NAME" },
    { name = "OPENAI_API_KEY", valueFrom = "/company/global/OPENAI_API_KEY" },
    { name = "RECRAFT_API_KEY", valueFrom = "/company/global/RECRAFT_API_KEY" },
    { name = "IDEOGRAM_API_KEY", valueFrom = "/company/global/IDEOGRAM_API_KEY" },
    { name = "PROXY_SERVER", valueFrom = "/company/global/PROXY_SERVER" },
    { name = "SCRAPERAPI_KEY", valueFrom = "/company/global/SCRAPERAPI_KEY" }
  ]
}
