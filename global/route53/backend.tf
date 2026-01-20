terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "global/route53/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}