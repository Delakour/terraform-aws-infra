# Terraform

Terraform for the company's AWS infrastructure and the manually operated production MongoDB Atlas peering entrypoint.

This repo provisions and updates:

- Networking: VPC, subnets, security groups, load balancing
- Compute: ECS cluster, backend service, OnlyOffice task, RAG tasks
- Delivery: ECR, S3, CloudFront, Route53
- Messaging and scheduling: SQS, EventBridge Scheduler, EventBridge Pipes
- Configuration and observability: SSM Parameter Store, CloudWatch Logs
- Production-only networking: MongoDB Atlas VPC peering

## Repo Layout

```txt
terraform/
+-- envs/
|   +-- dev/                # Dev stack entrypoint
|   +-- prod/               # Automated prod AWS entrypoint, deployed by GitHub Actions
|   +-- prod-atlas/         # Manual local prod Atlas and peering entrypoint
+-- global/
|   +-- route53-ssm/        # Shared Route53 zone and global SSM parameters
+-- modules/
|   +-- alb/
|   +-- atlas_vpc_peering/      # Atlas peering, AWS acceptance, routes, and Atlas access list
|   +-- cloudfront/
|   +-- cloudwatch_logs/
|   +-- ecr/
|   +-- ecs_cluster/
|   +-- ecs_tasks/
|   |   +-- ecs_backend_task/
|   |   +-- ecs_onlyoffice_task/
|   |   +-- ecs_rag_weekly_task/
|   |   +-- ecs_rag_worker_task/
|   +-- eventbridge_pipes/
|   +-- eventbridge_scheduler/
|   +-- s3/
|   +-- security/
|   +-- sqs/
|   +-- ssm/
|   +-- vpc/
+-- docs/
    +-- HANDOFF.md
```

## What Lives Where

- `envs/dev`, `envs/prod`, and `envs/prod-atlas` are the environment entrypoints you should `plan` and `apply`.
- `global/route53-ssm` manages shared DNS and shared SSM parameters used by both environments.
- `modules/` contains reusable building blocks. If a change affects both dev and prod, it is usually here.
- `locals.tf` in each environment is effectively the app-to-infra contract for injected secrets and config.
- `envs/prod` owns production AWS infrastructure, excluding production Atlas peering. It is deployed automatically by GitHub Actions from the `prod` branch.
- `envs/prod-atlas` owns production MongoDB Atlas peering plus the AWS-side peering accepter and routes. It is intentionally manual and must be run locally from a machine whose current public IP is in the Atlas Administration API access list for the Terraform API key.

## Workflow

Apply order for a brand new setup:

1. Apply `global/route53-ssm`
2. Apply `envs/dev`
3. Apply `envs/prod`
4. Apply `envs/prod-atlas`
5. Re-run `terraform plan` in both `envs/prod` and `envs/prod-atlas` to confirm ownership is clean

Bootstrap note:

- If this is the very first production bring-up, apply `envs/prod` first so its VPC outputs exist, then apply `envs/prod-atlas`.

Normal day-to-day work:

1. Change code in `modules/` or a target env folder
2. Run `terraform fmt -recursive`
3. Run `terraform plan` in the target directory
4. Apply only after reviewing the plan

## Branch Flow

The team release flow is:

1. Open a PR to `main`
2. Merge to `main`
3. After that, merge `main` into `prod`

How that maps to Terraform:

- `main` is the dev integration branch
- `prod` is the production release branch
- `global/route53-ssm` is shared infrastructure for both dev and prod
- Because the global stack is shared, it is applied from `main` and then the code is later promoted to `prod`
- Production Atlas remains intentionally separate from automated GitHub-hosted deployment because Atlas Administration API access is controlled by an IP access list

## CI/CD

GitHub Actions workflows:

- `.github/workflows/terraform-ci.yml`
  - Runs as a standalone workflow for pull requests into `main` or `prod`
  - Does not run as a standalone workflow on push or merge commits
  - Is also a reusable workflow called by the CD workflows through `workflow_call`
  - When called by CD, receives `target_path` and checks only the Terraform root being deployed
  - When run for a pull request without `target_path`, checks all Terraform roots
  - Runs formatting, init, validate, tflint, and plan for:
    - `global/route53-ssm`
    - `envs/dev`
    - `envs/prod`
  - Runs validation-only CI for:
    - `envs/prod-atlas`
  - `envs/prod-atlas` uses `terraform init -backend=false`, `terraform validate`, and `tflint`
  - `envs/prod-atlas` intentionally skips live `terraform plan` on GitHub-hosted runners
  - Uses per-root concurrency so two checks for the same state path queue instead of fighting over the same DynamoDB lock
- `.github/workflows/terraform-dev.yml`
  - Push to `main`
  - Triggers on changes under `envs/dev`, `modules`, and workflow files
  - Calls Terraform CI with `target_path: envs/dev`
  - Applies the dev environment
- `.github/workflows/terraform-prod.yml`
  - Push to `prod`
  - Triggers on changes under `envs/prod`, `modules`, and workflow files
  - Calls Terraform CI with `target_path: envs/prod`
  - Applies only the automated AWS production root in `envs/prod`
  - Does not plan or apply `envs/prod-atlas`
- `.github/workflows/terraform-global.yml`
  - Push to `main`
  - Triggers on changes under `global` and workflow files
  - Calls Terraform CI with `target_path: global/route53-ssm`
  - Applies shared global resources used by both dev and prod

Expected merge behavior:

- A PR into `main` or `prod` runs the standalone Terraform CI workflow.
- A merge to `main` does not start a separate standalone Terraform CI workflow.
- A merge to `main` can start Terraform Dev CD, Terraform Global CD, or both, depending on changed paths.
- Each CD workflow calls the reusable CI job internally before its apply job.
- A merge to `prod` can start Terraform Prod CD, which calls reusable CI for `envs/prod` before applying.
- `envs/prod-atlas` is never applied by GitHub Actions.

## Prerequisites

- Terraform `>= 1.6.0`
- AWS CLI with access to the target AWS account
- GitHub Actions OIDC role configured in repo secrets

Optional but recommended for local parity with CI:

- `tflint`

CI runs `terraform fmt`, `terraform validate`, and `tflint` for every entrypoint. CI also runs `terraform plan` for `global/route53-ssm`, `envs/dev`, and `envs/prod`. `envs/prod-atlas` intentionally skips live plan on GitHub-hosted runners. If you want to catch the same lint issues before pushing, install `tflint` locally and run it from the relevant Terraform entrypoint.

## Local Secret Files

Treat Terraform `tfvars` files like `.env` files:

- local-only
- may contain secrets
- should not be committed

For manual Atlas work, create or update:

- `envs/prod-atlas/terraform.tfvars`

Use the tracked example as the template:

- `envs/prod-atlas/terraform.tfvars.example`

Typical flow:

1. Open `envs/prod-atlas/terraform.tfvars.example`
2. Copy it to `envs/prod-atlas/terraform.tfvars`
3. Fill in the real values locally

The main use here is providing local-only Terraform variables such as the MongoDB Atlas API credentials for the manual `prod-atlas` root.

Recommended local checks:

```powershell
terraform fmt -recursive
terraform -chdir=global/route53-ssm init
terraform -chdir=global/route53-ssm plan
terraform -chdir=envs/dev init
terraform -chdir=envs/dev plan
terraform -chdir=envs/prod init
terraform -chdir=envs/prod plan
terraform -chdir=envs/prod-atlas init
terraform -chdir=envs/prod-atlas plan
```

Production note:

- `envs/prod` is the automated AWS-only root. It is applied by GitHub Actions and no longer configures the MongoDB Atlas provider.
- `envs/prod-atlas` is a manual local root. Before `terraform plan` or `terraform apply`, the operator must approve/add their current public IP in the MongoDB Atlas Administration API access list for the Terraform API key.
- Before running `envs/prod-atlas` locally, update the MongoDB Atlas Administration API access list for the Terraform key:
  1. MongoDB Atlas -> Organization -> Settings -> Application -> API Keys
  2. Find the key described as `parpar-prod-terraform-atlas`
  3. Open the three-dots menu
  4. Choose `Edit Permissions`
  5. Go to `API access list`
  6. Add an access list entry
  7. Use `Current IP Address`
  8. Save
- This access list is for the Atlas Administration API credentials. It is different from MongoDB project or database client IP access lists.
- GitHub-hosted runners do not use a stable public IP and cannot bootstrap their own Atlas access. That is why `envs/prod-atlas` is kept manual and local-only.

Manual Atlas flow:

```powershell
terraform -chdir=envs/prod-atlas init
terraform -chdir=envs/prod-atlas fmt -check
terraform -chdir=envs/prod-atlas validate
terraform -chdir=envs/prod-atlas plan
terraform -chdir=envs/prod-atlas apply
```

## Remote State

Remote state is stored in S3 with DynamoDB locking.

- Bucket: `terraform-state`
- Lock table: `terraform-locks`

Current state keys:

- `global/route53/terraform.tfstate`
- `envs/dev/terraform.tfstate`
- `envs/prod/terraform.tfstate`
- `envs/prod-atlas/terraform.tfstate`

`global/route53-ssm` still uses the legacy `global/route53/terraform.tfstate` key. Keep it unless you intentionally perform a state migration.

If CI or CD fails with `Error acquiring the state lock`, check whether another workflow run or local operator is currently planning or applying the same state key. Do not add `-lock=false` in automation. Wait for the active run to finish, cancel only if it is clearly stuck, and remove a remote lock manually only after confirming no Terraform process is still using that state.

## Environment Differences

Main differences between `dev` and `prod`:

- Prod AWS infrastructure is in `envs/prod`
- Prod Atlas infrastructure is in `envs/prod-atlas`
- `envs/prod` is automated through GitHub Actions from the `prod` branch
- `envs/prod-atlas` is manually planned/applied locally after the operator's current IP is allowed in Atlas
- Prod Atlas peering, including the AWS-side peering accepter and routes, is in `envs/prod-atlas`
- Prod backend autoscaling ceiling is higher
- Both environments share the same module structure and SSM contract
- `envs/prod-atlas` local Terraform work depends on MongoDB Atlas Administration API access controls for your current machine

## High-Value Files

- `envs/dev/main.tf`
- `envs/prod/main.tf`
- `envs/prod-atlas/main.tf`
- `envs/dev/locals.tf`
- `envs/prod/locals.tf`
- `global/route53-ssm/main.tf`
- `.github/workflows/*.yml`

## Common Change Map

- Add or change app secret wiring: `envs/*/locals.tf` and `modules/ssm`
- Change backend task/service behavior: `modules/ecs_tasks/ecs_backend_task`
- Change production Atlas peering or Atlas Administration API-managed resources: `envs/prod-atlas`
- Change scheduled or queue-driven RAG execution:
  - `modules/ecs_tasks/ecs_rag_weekly_task`
  - `modules/ecs_tasks/ecs_rag_worker_task`
  - `modules/eventbridge_scheduler`
  - `modules/eventbridge_pipes`
- Change domains or DNS: `global/route53-ssm` and Route53 records in each env
- Change frontend hosting/CDN: `modules/s3`, `modules/cloudfront`, env Route53 records

## State Migration

This refactor introduced a separate production Atlas state. The repo change does not move existing remote state by itself, so the migration below is only for a backend where Atlas resources still live in `envs/prod` state. Do not run it blindly or repeat it after the resources have already been moved.

Recommended migration flow:

```powershell
terraform -chdir=envs/prod init
terraform -chdir=envs/prod-atlas init

New-Item -ItemType Directory -Force -Path .state-migration | Out-Null

terraform -chdir=envs/prod state pull > .state-migration/prod.before.tfstate
Copy-Item .state-migration/prod.before.tfstate .state-migration/prod.working.tfstate

terraform state mv `
  -state=.state-migration/prod.working.tfstate `
  -state-out=.state-migration/prod-atlas.working.tfstate `
  'module.atlas_vpc_peering.mongodbatlas_network_container.network_container' `
  'module.atlas_vpc_peering.mongodbatlas_network_container.network_container'

terraform state mv `
  -state=.state-migration/prod.working.tfstate `
  -state-out=.state-migration/prod-atlas.working.tfstate `
  'module.atlas_vpc_peering.mongodbatlas_network_peering.network_peering' `
  'module.atlas_vpc_peering.mongodbatlas_network_peering.network_peering'

terraform state mv `
  -state=.state-migration/prod.working.tfstate `
  -state-out=.state-migration/prod-atlas.working.tfstate `
  'module.atlas_vpc_peering.mongodbatlas_project_ip_access_list.aws_vpc_cidr' `
  'module.atlas_vpc_peering.mongodbatlas_project_ip_access_list.aws_vpc_cidr'

terraform state mv `
  -state=.state-migration/prod.working.tfstate `
  -state-out=.state-migration/prod-atlas.working.tfstate `
  'module.atlas_vpc_peering.aws_vpc_peering_connection_accepter.vpc_connection_accepter' `
  'module.atlas_vpc_peering.aws_vpc_peering_connection_accepter.vpc_connection_accepter'

terraform state mv `
  -state=.state-migration/prod.working.tfstate `
  -state-out=.state-migration/prod-atlas.working.tfstate `
  'module.atlas_vpc_peering.aws_route.atlas_routes["rtb-0b8b2a1bc221584b3"]' `
  'module.atlas_vpc_peering.aws_route.atlas_routes["rtb-0b8b2a1bc221584b3"]'

terraform -chdir=envs/prod state push .state-migration/prod.working.tfstate
terraform -chdir=envs/prod-atlas state push .state-migration/prod-atlas.working.tfstate

terraform -chdir=envs/prod plan
terraform -chdir=envs/prod-atlas plan
```

Rollback guidance:

- Keep `.state-migration/prod.before.tfstate` untouched.
- After moving the Atlas resources, `envs/prod` should plan without Atlas credentials or the `mongodbatlas` provider.
- `envs/prod-atlas` should show the Atlas resources, AWS peering accepter, and AWS routes as managed in place.
- If the migration produces an unexpected plan, stop and push the backup back to `envs/prod`.
- Do not apply either root until both plans look correct.

## Handoff

Start with [docs/HANDOFF.md](./docs/HANDOFF.md) if you are new to this repo or taking over infrastructure ownership.
