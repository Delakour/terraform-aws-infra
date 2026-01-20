# Terraform AWS Infrastructure

Containerized AWS infrastructure using ECS Fargate for scalable application deployment.

## Architecture

- **VPC**: Custom VPC with public/private subnets across 2 AZs
- **ECS**: Fargate cluster running containerized backend services
- **ECR**: Container registry for Docker images
- **ALB**: Application Load Balancer with SSL termination
- **S3**: Storage buckets for frontend and application data
- **CloudFront**: CDN for frontend distribution
- **Route53**: DNS management and domain routing

## Project Structure

```txt
terraform-aws-infra/
├── envs/
│   ├── dev/                    # Development environment
│   └── prod/                   # Production environment (with MongoDB Atlas peering)
├── global/
│   └── route53/                # Global DNS zone
├── modules/
│   ├── vpc/                    # VPC and networking
│   ├── ecs_cluster/            # ECS Fargate cluster
│   ├── ecs_backend/            # ECS backend service
│   ├── ecr/                    # Container registry
│   ├── alb/                    # Application Load Balancer
│   ├── s3/                     # S3 buckets
│   ├── cloudfront/             # CloudFront distributions
│   ├── cloudwatch_logs/        # CloudWatch log groups
│   └── security/               # Security groups
└── README.md
```

## Prerequisites

```bash
# Install Terraform
terraform --version

# Configure AWS CLI
aws configure sso
aws sso login
```

## Setup

### 1. Initialize Remote State

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket terraform-state \
  --region eu-north-1 \
  --create-bucket-configuration LocationConstraint=eu-north-1

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 2. Deploy Global Resources

```bash
cd global/route53
terraform init
terraform apply
```

### 3. Deploy Environment

```bash
# Development
cd envs/dev
terraform init
terraform plan
terraform apply

# Production
cd envs/prod
terraform init
terraform plan
terraform apply
```

## Configuration

### Key Variables

- `project_name`: Base project name
- `environment`: Environment (dev/prod)
- `vpc_cidr`: VPC CIDR block
- `frontend_domain`: Frontend domain name
- `backend_domain`: Backend API domain name
- `qdrant_url`: Qdrant vector database URL
- `qdrant_api_key`: Qdrant API key

### Environment Secrets

Backend service uses AWS Systems Manager Parameter Store for secrets:

**Global Parameters:**

- `/global/MONGODB_NAME`
- `/global/DATABASE_NAME`
- `/global/OPENAI_API_KEY`
- `/global/FERNET_KEY`
- `/global/AWS_REGION`
- `/global/GEMINI_API_KEY`

**Environment-specific Parameters:**

- `/{env}/MONGODB_URL`
- `/{env}/S3_LOCAL_FOLDER_NAME`
- `/{env}/S3_BRANDBOOK_NAME`
- `/{env}/S3_STORYPORTAL_NAME`

## Infrastructure Components

### Container Platform

- **ECS Cluster**: Fargate cluster with Container Insights
- **ECR Repository**: Docker image registry with lifecycle policies
- **ECS Service**: Backend service with auto-scaling capabilities
- **CloudWatch Logs**: Centralized logging with 14-day retention

### Networking

- **VPC**: Multi-AZ setup with public/private subnets
- **ALB**: Load balancer targeting ECS tasks
- **Security Groups**: Restrictive network access rules
- **NAT Gateway**: Outbound internet access for private subnets

### Storage

- **S3 Buckets**:

  - `{project}-{env}-frontend`: Static website hosting
  - `{project}-{env}-local-folder`: Application file storage
  - `{project}-{env}-brandbook`: Brand assets
  - `{project}-{env}-story-portal`: Story portal files
- **CloudFront**: Global CDN for frontend distribution

### DNS & SSL

- **Route53**: Hosted zone and DNS records
- **ACM Certificates**: SSL/TLS for both CloudFront and ALB
- **Domain Aliases**: Frontend and backend domain routing

## Deployment Workflow

### Initial Deployment

1. Configure AWS SSO and login
2. Create remote state resources
3. Deploy global Route53 zone
4. Deploy environment infrastructure
5. Push Docker image to ECR
6. Deploy ECS service

### Application Updates

1. Build and tag Docker image
2. Push to ECR repository
3. Update ECS service (automatic deployment)

### Infrastructure Updates

```bash
cd envs/{env}
terraform plan
terraform apply
```

## Production Differences

Production environment includes:

- MongoDB Atlas VPC peering connection
- Hardcoded Atlas VPC CIDR and peering connection ID
- Production-grade instance sizing and configurations

## Container Configuration

Backend container runs on:

- **CPU**: 1024 (1 vCPU)
- **Memory**: 2048 MB (2 GB)
- **Port**: 8000
- **Health Check**: `/health` endpoint
- **Logging**: CloudWatch with structured logs

## Cleanup

```bash
# Destroy environment
cd envs/{env}
terraform destroy

# Destroy global resources
cd global/route53
terraform destroy
```
