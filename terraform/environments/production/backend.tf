terraform {
  backend "s3" {
    bucket         = "acme-terraform-state"
    key            = "cis-hardening/production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
