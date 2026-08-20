terraform {
  required_version = ">= 1.6.0"
  backend "s3" {
    bucket         = "terraform-state"
    key            = "envs/prod-atlas/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
