#AWS Infrastructure
resource "aws_s3_bucket" "resume-pauldesalvo-bucket" {
  bucket = var.bucket_name
  policy = templatefile("~/cloud-resume/infra/s3-policy.json", { bucket = "${var.bucket_name}" })
}

resource "aws_s3_bucket_acl" "resume-pauldesalvo-bucket-acl" {
  bucket = aws_s3_bucket.resume-pauldesalvo-bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "cors-config-resume-pauldesalvo-bucket" {
  bucket = aws_s3_bucket.resume-pauldesalvo-bucket.bucket

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://www.${var.domain_name}"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_website_configuration" "resume-website" {
  bucket = aws_s3_bucket.resume-pauldesalvo-bucket.bucket

  index_document {
    suffix = "index.html"
  }

  #error_document {
  # suffix = "error.html"
  #}
}
resource "aws_acm_certificate" "ssl_certificate" {
  domain_name               = "pauldesalvo.net"
  validation_method         = "EMAIL"
  subject_alternative_names = ["*.${var.domain_name}"]



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
    origin_id   = "${var.bucket_name}.s3-website-us-east-1.amazonaws.com"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["www.${var.domain_name}"]

  #Add custom_error_response

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.bucket_name}.s3-website-us-east-1.amazonaws.com"

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


}

resource "aws_route53_zone" "main" {
  name = var.domain_name
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
  name           = "PageVisits"
  billing_mode   = "PROVISIONED"
  hash_key       = "PageVisits"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "PageVisits"
    type = "N"
  }
}



