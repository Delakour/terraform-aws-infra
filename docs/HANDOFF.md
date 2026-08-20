# Terraform Handoff

This file is meant for the next person who has to operate the company infrastructure without tribal knowledge.

## First Mental Model

There are four Terraform entrypoints:

- `global/route53-ssm`
- `envs/dev`
- `envs/prod`
- `envs/prod-atlas`

Everything else is a module used by one or more of those entrypoints.

If you only remember one rule, remember this:

- Do not apply a module directory directly.
- Always apply an entrypoint directory.

## Branch and Release Flow

The team's normal flow is:

1. Open a PR to `main`
2. Merge to `main`
3. Merge `main` into `prod`

Interpretation for this repo:

- `main` is the dev and integration line
- `prod` is the production release line
- `global/route53-ssm` is shared infrastructure for both environments
- Global changes are applied from `main`, then the code is later promoted to `prod`
- `envs/dev` deploys from `main`
- `envs/prod` deploys from `prod` through GitHub Actions and is the automated AWS production root
- `envs/prod-atlas` is not deployed by GitHub Actions; it is planned and applied manually from a local machine

## Where To Look First

For most questions, start here:

- Shared DNS and shared SSM params: `global/route53-ssm`
- Dev stack wiring: `envs/dev/main.tf`
- Prod stack wiring: `envs/prod/main.tf`
- Backend secret injection contract: `envs/dev/locals.tf` and `envs/prod/locals.tf`
- CI/CD behavior: `.github/workflows/`

## Local tfvars Convention

Treat `terraform.tfvars` like `.env`:

- local-only
- may contain secrets
- do not commit it

For manual Atlas local work:

1. Open `envs/prod-atlas/terraform.tfvars.example`
2. Copy it to `envs/prod-atlas/terraform.tfvars`
3. Fill in the real values locally

This is the local file used for values like the MongoDB Atlas API keys.

## Local Prerequisite For Prod Atlas

Before running `terraform plan` or `terraform apply` in `envs/prod-atlas` locally, approve/add the operator machine's current public IP in Atlas:

- Go to MongoDB Atlas -> Organization -> Settings -> Application -> API Keys
- Find the key described as `parpar-prod-terraform-atlas`
- Open the three-dots menu
- Click `Edit Permissions`
- Open `API access list`
- Add an access list entry
- Use `Current IP Address`
- Save

Without that IP access entry, `envs/prod-atlas` `plan` or `apply` may fail even if the code is correct.

This allowlist is for the Atlas Administration API credentials. It is different from MongoDB database client IP access lists.

## Why Prod Is Split

Production is intentionally split between:

- `envs/prod` for automated AWS production infrastructure, excluding production Atlas peering
- `envs/prod-atlas` for MongoDB Atlas peering plus the AWS-side peering accepter and routes

Why:

- GitHub-hosted runners use changing public IP addresses
- Atlas Administration API credentials may be restricted by source IP
- A GitHub-hosted runner cannot safely add its own IP because the first Atlas API call is rejected before the IP is allowlisted
- So `envs/prod-atlas` remains a manual trusted-machine operation instead of a GitHub-hosted workflow

Bootstrap nuance:

- On the very first production bring-up, apply `envs/prod` first so its VPC outputs exist, then apply `envs/prod-atlas`.

## Typical Tasks

Add a new backend secret:

1. Add the parameter definition in the target env `main.tf` under `module "ssm"`.
2. Add the injected secret mapping in the target env `locals.tf`.
3. Verify the ECS task module already consumes `ssm_params`.

Change backend compute or scaling:

1. Check `modules/ecs_tasks/ecs_backend_task`
2. Check the caller values in `envs/dev/main.tf` and `envs/prod/main.tf`

Change frontend hosting behavior:

1. Check `modules/s3`
2. Check `modules/cloudfront`
3. Check the environment Route53 records

Change RAG async processing:

1. Queue: `modules/sqs`
2. Worker task: `modules/ecs_tasks/ecs_rag_worker_task`
3. Pipes trigger: `modules/eventbridge_pipes`
4. Weekly schedule: `modules/ecs_tasks/ecs_rag_weekly_task` and `modules/eventbridge_scheduler`

Change domains, certificates, or DNS:

1. Check `global/route53-ssm`
2. Check env Route53 records
3. Check ACM ARNs passed through env variables

## CI/CD Rules

- `main` deploys `envs/dev`
- `main` also deploys `global/route53-ssm` when `global/**` changes
- `prod` deploys the AWS production root in `envs/prod` through GitHub Actions
- Pull requests into `main` or `prod` run the standalone Terraform CI workflow
- Pushes and merge commits do not run standalone Terraform CI
- CD workflows call Terraform CI internally as a reusable workflow before applying
- CD passes `target_path` to reusable CI so only the root being deployed is checked
- CI also validates `envs/prod-atlas` without running a live Atlas-backed plan
- Module changes trigger environment deployments because shared modules are consumed by both envs
- `envs/prod-atlas` plan/apply is manual from a local machine whose current IP has been added to the Atlas Administration API access list
- Per-root concurrency is enabled so runs for the same state path queue instead of colliding on the DynamoDB lock

Why global deploys from `main`:

- The global stack is shared by dev and prod
- The team promotes changes by merging `main` into `prod`
- Running the shared global apply once on `main` avoids duplicate applies from both branches

Before trusting automation, read:

- `.github/workflows/terraform-ci.yml`
- `.github/workflows/terraform-dev.yml`
- `.github/workflows/terraform-prod.yml`
- `.github/workflows/terraform-global.yml`

## State and Safety Notes

- Remote state bucket: `terraform-state`
- DynamoDB lock table: `terraform-locks`
- The global folder uses a legacy state key: `global/route53/terraform.tfstate`
- `envs/prod-atlas` uses `envs/prod-atlas/terraform.tfstate`

Do not rename that state key casually. Folder names and state keys do not have to match.

If a workflow fails with `Error acquiring the state lock`, another run or local operator probably holds the same S3/DynamoDB backend lock. Do not bypass the lock with `-lock=false`. Wait for the active run to finish, or investigate and clear the remote lock only after confirming there is no active Terraform process.

## State Migration Steps

This split required moving the whole Atlas peering module out of `envs/prod` and into `envs/prod-atlas`.
The repo change alone does not move remote state, so use this sequence only if the real backend still has Atlas resources in `envs/prod` state. Do not repeat it after the resources have already been moved.

Safe sequence:

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

What this moves:

- `module.atlas_vpc_peering.mongodbatlas_network_container.network_container`
- `module.atlas_vpc_peering.mongodbatlas_network_peering.network_peering`
- `module.atlas_vpc_peering.mongodbatlas_project_ip_access_list.aws_vpc_cidr`
- `module.atlas_vpc_peering.aws_vpc_peering_connection_accepter.vpc_connection_accepter`
- `module.atlas_vpc_peering.aws_route.atlas_routes[*]`

Rollback:

- Keep `.state-migration/prod.before.tfstate`
- After the move, `envs/prod` should plan without Atlas credentials and without refreshing `mongodbatlas_*` resources.
- If either plan looks wrong, stop and push the backup back into `envs/prod`
- Do not apply either root until both plans are clean

## Known Repo Quirks

- `locals.tf` is long because it doubles as the environment variable contract for ECS tasks.
- `dev` and `prod` are intentionally similar. Keep them structurally aligned when possible.
- If you change a shared module, verify both environments.
- There is an `ec2` module in the repo that is not part of the active environment flow.
- If you find unused folders under `modules/`, verify they are truly abandoned before deleting anything.
- Prod Terraform can appear broken locally when the real issue is that MongoDB Atlas does not yet allow the current machine or IP.
- `envs/prod` should not need Atlas credentials after the split.
- `envs/prod-atlas` is the only root that should configure the MongoDB Atlas provider.
- Remove legacy Atlas credentials from any local `envs/prod/terraform.tfvars`; Atlas credentials belong only in local `envs/prod-atlas/terraform.tfvars`.

## Minimum Safe Review Before Apply

1. `terraform fmt -recursive`
2. `terraform plan` in the target entrypoint
3. Read the resource diff, not just the exit code
4. For module changes, inspect both `envs/dev` and `envs/prod`
5. For Atlas peering changes, inspect both `envs/prod` and `envs/prod-atlas`
6. For DNS, IAM, network, and state changes, be extra conservative

## Good Future Improvements

- Add module-level README files for the highest-change modules
- Standardize provider and lint configuration in one visible place
- Add a lightweight architecture diagram
- Decide whether to keep or remove inactive module placeholders after verification
