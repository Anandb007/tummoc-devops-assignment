terraform {
  backend "s3" {
    bucket         = "tummoc-terraform-state"
    key            = "devops/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
