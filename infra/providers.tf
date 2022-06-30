terraform {
  required_version = "1.1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}
provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/crendtials"
}
