terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~> 3.27"
      }
  }

  required_version = ">= 1.1.0"
}

provider "aws" {
  profile = "default"
  region = "us-west-1"
}

resource "aws_s3_bucket" "b" {
    bucket = "my-s3-website-bucket"
    acl = "public-read"
    policy = file("")

    cors_rule {
      allowed_headers = ["*"]
      allowed_methods = ["GET"]
      allowed_origins = ["https://mydomain.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
    
    logging {
      target_bucket = aws_s3_bucket.log_bucket.id
      target_prefix = "log/"
    }
    website {
      index_document = "index.html"
      error_document = "error.html"

      routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "docs/"
    },
    "Redirect": {
        "ReplaceKeyPrefixWith": "documents/"
    }
}]
EOF
    }
    tags = {
        Name    = "Resume-Website"
        Environment = "Prod"
    }
}