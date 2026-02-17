terraform {
  backend "s3" {
    bucket         = "my-terraform-state-demo-1771308527"  # your bucket name
    key            = "envs/dev/terraform.tfstate" # path inside bucket
    region         = "us-east-1"                 # your region
    dynamodb_table = "terraform-locks"            # your DynamoDB table
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"   
}

resource "aws_instance" "example" {
  ami           = "ami-0c1fe732b5494dc14"  
  instance_type = "t3.micro"

  tags = {
    Name = "Terraform-Test-Instance"
  }
}
