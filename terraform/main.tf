# AWS Infrastructure

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

resource "aws_s3_bucket" "resume_www_bucket" {
  bucket = "www.${var.bucket_name}"
  acl    = "public-read"
  policy = templatefile("templates/s3-policy.json", { bucket = "www.${var.bucket_name}" })

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://www.${var.domain_name}"]
    max_age_seconds = 3000
  }

  website {
    index_document = "index.html"
    #error_document = "error.html"
  }

  tags = var.common_tags
}

resource "aws_acm_certificate" "ssl_certificate" {
  domain_name               = "pauldesalvo.net"
  validation_method         = "EMAIL"
  subject_alternative_names = ["*.${var.domain_name}"]

  tags = var.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn = aws_acm_certificate.ssl_certificate.arn
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "pauldesalvo.net"
    origin_id   = "S3-www.${var.bucket_name}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["www.${var.domain_name}"]

  #Add custom_error_response

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-www.${var.bucket_name}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 3153600
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  tags = var.common_tags

}

resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = var.common_tags
}

resource "aws_route53_record" "root-a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_dynamodb_table" "website-visits-dynamodb-table" {
  name         = "PageVisits"
  billing_mode = "PROVISIONED"
  hash_key     = "PageVisits"

  attribute {
    name = "PageVisits"
    type = "N"
  }

  tags = var.common_tags
}



