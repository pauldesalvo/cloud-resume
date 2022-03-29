terraform {
  required_version = "1.1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}
provider "aws" {
  region                  = "us-west-1"
  shared_credentials_file = "~/.aws/crendtials"
}
