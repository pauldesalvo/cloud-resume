terraform {
    required_version = "1.1.3"

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.27"
        }
    }

    backend "s3" {
      bucket = "enter_domain_name here"
      key = "prod/terraform.tfstate"
      region = "us-west-1"
    }
}

provider "aws" {
    region = "us-west-1"
}

provider "aws" {
    alias = "acm_provider"
    region = "us-east-1"
}