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
    { name = "FACEBOOK_REDIRECT_URI", valueFrom = "/company/${var.environment}/FACEBOOK_REDIRECT_URI" },
    { name = "MONGODB_URL", valueFrom = "/company/${var.environment}/MONGODB_URL" },
    { name = "QDRANT_API_KEY", valueFrom = "/company/${var.environment}/QDRANT_API_KEY" },
    { name = "QDRANT_URL", valueFrom = "/company/${var.environment}/QDRANT_URL" },
    { name = "S3_BRANDBOOK_BUCKET_NAME", valueFrom = "/company/${var.environment}/S3_BRANDBOOK_BUCKET_NAME" },
    { name = "S3_LOCAL_FOLDER_BUCKET_NAME", valueFrom = "/company/${var.environment}/S3_LOCAL_FOLDER_BUCKET_NAME" },
    { name = "S3_STORYPORTAL_BUCKET_NAME", valueFrom = "/company/${var.environment}/S3_STORYPORTAL_BUCKET_NAME" },
    { name = "GOOGLE_JAVASCRIPT_ORIGINS", valueFrom = "/company/${var.environment}/GOOGLE_JAVASCRIPT_ORIGINS" },
    { name = "GOOGLE_REDIRECT_URIS", valueFrom = "/company/${var.environment}/GOOGLE_REDIRECT_URIS" },
    { name = "RAG_CREATE_QUEUE_URL", valueFrom = "/company/${var.environment}/RAG_CREATE_QUEUE_URL" },
    { name = "PROXY_ENABLED", valueFrom = "/company/${var.environment}/PROXY_ENABLED" },
    { name = "USE_SCRAPERAPI_DIRECT", valueFrom = "/company/${var.environment}/USE_SCRAPERAPI_DIRECT" },
    { name = "ONLYOFFICE_SERVER_URL", valueFrom = "/company/${var.environment}/ONLYOFFICE_SERVER_URL" },
    { name = "ONLYOFFICE_CALLBACK_BASE_URL", valueFrom = "/company/${var.environment}/ONLYOFFICE_CALLBACK_BASE_URL" },
    # global ssm
    { name = "AWS_ACCESS_KEY_ID", valueFrom = "/company/global/AWS_ACCESS_KEY_ID" },
    { name = "AWS_REGION", valueFrom = "/company/global/AWS_REGION" },
    { name = "AWS_SECRET_ACCESS_KEY", valueFrom = "/company/global/AWS_SECRET_ACCESS_KEY" },
    { name = "COHERE_API_KEY", valueFrom = "/company/global/COHERE_API_KEY" },
    { name = "DATABASE_NAME", valueFrom = "/company/global/DATABASE_NAME" },
    { name = "FERNET_KEY", valueFrom = "/company/global/FERNET_KEY" },
    { name = "AUTH_COOKIE_SECURE", valueFrom = "/company/global/AUTH_COOKIE_SECURE" },
    { name = "JWT_ACCESS_TOKEN_EXPIRE_MINUTES", valueFrom = "/company/global/JWT_ACCESS_TOKEN_EXPIRE_MINUTES" },
    { name = "JWT_ALGORITHM", valueFrom = "/company/global/JWT_ALGORITHM" },
    { name = "JWT_REFRESH_TOKEN_EXPIRE_DAYS", valueFrom = "/company/global/JWT_REFRESH_TOKEN_EXPIRE_DAYS" },
    { name = "JWT_SECRET_KEY", valueFrom = "/company/global/JWT_SECRET_KEY" },
    { name = "OAUTH_STATE_EXPIRE_MINUTES", valueFrom = "/company/global/OAUTH_STATE_EXPIRE_MINUTES" },
    { name = "ONLYOFFICE_JWT_SECRET", valueFrom = "/company/global/ONLYOFFICE_JWT_SECRET" },
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
    { name = "META_APP_ID", valueFrom = "/company/global/META_APP_ID" },
    { name = "META_APP_SECRET", valueFrom = "/company/global/META_APP_SECRET" },
    { name = "FACEBOOK_SCOPES", valueFrom = "/company/global/FACEBOOK_SCOPES" },
    { name = "MONGODB_NAME", valueFrom = "/company/global/MONGODB_NAME" },
    { name = "OPENAI_API_KEY", valueFrom = "/company/global/OPENAI_API_KEY" },
    { name = "IDEOGRAM_API_KEY", valueFrom = "/company/global/IDEOGRAM_API_KEY" },
    { name = "PROXY_SERVER", valueFrom = "/company/global/PROXY_SERVER" },
    { name = "SCRAPERAPI_KEY", valueFrom = "/company/global/SCRAPERAPI_KEY" },
    { name = "WEBSHARE_USERNAME", valueFrom = "/company/global/WEBSHARE_USERNAME" },
    { name = "WEBSHARE_PASSWORD", valueFrom = "/company/global/WEBSHARE_PASSWORD" },
    { name = "WEBSHARE_SERVER", valueFrom = "/company/global/WEBSHARE_SERVER" },
    { name = "GAMMA_URL", valueFrom = "/company/global/GAMMA_URL" },
    { name = "GAMMA_API_KEY", valueFrom = "/company/global/GAMMA_API_KEY" },
    { name = "MAILCHIMP_API_KEY", valueFrom = "/company/global/MAILCHIMP_API_KEY" },
    { name = "MAILCHIMP_SERVER_PREFIX", valueFrom = "/company/global/MAILCHIMP_SERVER_PREFIX" },
    { name = "MAILCHIMP_LIST_ID", valueFrom = "/company/global/MAILCHIMP_LIST_ID" },
    { name = "WHATSAPP_EMBEDDED_SIGNUP_CONFIG_ID", valueFrom = "/company/global/WHATSAPP_EMBEDDED_SIGNUP_CONFIG_ID" },
    { name = "WHATSAPP_TEST_WABA_ID", valueFrom = "/company/global/WHATSAPP_TEST_WABA_ID" },
    { name = "WHATSAPP_TEST_PHONE_NUMBER_ID", valueFrom = "/company/global/WHATSAPP_TEST_PHONE_NUMBER_ID" },
    { name = "META_GRAPH_API_VERSION", valueFrom = "/company/global/META_GRAPH_API_VERSION" }
  ]
}
