terraform {
  backend "s3" {
    bucket         = "parpar-terraform-state"
    key            = "global/route53/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "parpar-terraform-locks"
    encrypt        = true
  }
}