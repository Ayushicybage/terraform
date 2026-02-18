terraform {
  backend "s3" {
    bucket         = "my-terraform-state-demo-1771308527"
    key            = "envs/prod/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}