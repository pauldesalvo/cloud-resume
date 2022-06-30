#AWS Infrastructure
resource "aws_s3_bucket" "resume-pauldesalvo-bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_policy" "read_resume_website" {
  bucket = aws_s3_bucket.resume-pauldesalvo-bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_s3_bucket_acl" "resume-pauldesalvo-bucket-acl" {
  bucket = aws_s3_bucket.resume-pauldesalvo-bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "cors-config-resume-pauldesalvo-bucket" {
  bucket = aws_s3_bucket.resume-pauldesalvo-bucket.bucket

  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["GET"]
    allowed_origins = ["pauldesalvo.net"]
    expose_headers  = ["Access-Control-Allow-Origin"]
    max_age_seconds = 3000
  }
}

/*resource "aws_s3_bucket_public_access_block" "resume-pauldesalvo-bucket" {
  bucket = var.bucket_name

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = false

}*/

resource "aws_s3_bucket_website_configuration" "resume-website" {
  bucket = aws_s3_bucket.resume-pauldesalvo-bucket.bucket

  index_document {
    suffix = "index.html"
  }

  #error_document {
  # suffix = "error.html"
  #}
}
resource "aws_acm_certificate" "main_website_ssl_certificate" {
  domain_name               = "pauldesalvo.net"
  validation_method         = "EMAIL"
  subject_alternative_names = ["*.${var.domain_name}"]



  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "api_ssl_cert" {
  domain_name       = "api.pauldesalvo.net"
  validation_method = "EMAIL"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "main_website_cert_validation" {
  certificate_arn = aws_acm_certificate.main_website_ssl_certificate.arn
}

resource "aws_acm_certificate_validation" "api_cert_validation" {
  certificate_arn = aws_acm_certificate.api_ssl_cert.arn
}

resource "aws_cloudfront_origin_access_identity" "s3-bucket-oai" {
  comment = "s3-bucket-oai"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = [
      aws_s3_bucket.resume-pauldesalvo-bucket.arn,
      "arn:aws:s3:::${var.bucket_name}/*"
    ]

    principals {
      type = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.s3-bucket-oai.iam_arn
      ]
    }
  }

  /*  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.resume-pauldesalvo-bucket.arn,
      "arn:aws:s3:::${var.bucket_name}/*"
    ]

    principals {
      type = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.s3-bucket-oai.iam_arn
      ]
    }
  }*/
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.resume-pauldesalvo-bucket.bucket_domain_name
    origin_id   = "${var.bucket_name}.s3-website-us-east-1.amazonaws.com"

    /*custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }*/
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3-bucket-oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["pauldesalvo.net"]

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
    acm_certificate_arn      = aws_acm_certificate_validation.main_website_cert_validation.certificate_arn
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
    type = "S"
  }
}

resource "aws_iam_role_policy" "policy_for_lambda" {
  name   = "Lambda-dynodb-role"
  role   = aws_iam_role.iam_for_lambda.id
  policy = file("~/cloud-resume/infra/iam-roles/policy.json")
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":  [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF  
}

data "archive_file" "lambda-zip" {
  type        = "zip"
  output_path = "/tmp/lambda_zip_file.zip"
  source {
    content  = file("~/cloud-resume/infra/lambda/lambda.py")
    filename = "lambda.py"
  }
}

resource "aws_lambda_function" "lambda" {
  function_name    = "lambda"
  filename         = data.archive_file.lambda-zip.output_path
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda.lambda_handler"
  source_code_hash = data.archive_file.lambda-zip.output_base64sha256
  runtime          = "python3.8"
}

resource "aws_lambda_permission" "rest-api-lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.myregion}:${local.account_id}:${aws_api_gateway_rest_api.rest-api.id}/*/${aws_api_gateway_method.rest_api_get_method.http_method}${aws_api_gateway_resource.rest_api_resource.path}"
}

resource "aws_api_gateway_rest_api" "rest-api" {
  name = "cloud-resume-rest-api"
}

resource "aws_api_gateway_resource" "rest_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest-api.id
  parent_id   = aws_api_gateway_rest_api.rest-api.root_resource_id
  path_part   = "visitors"
}

resource "aws_api_gateway_method" "rest_api_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest-api.id
  resource_id   = aws_api_gateway_resource.rest_api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.rest-api.id
  resource_id = aws_api_gateway_resource.rest_api_resource.id
  http_method = aws_api_gateway_method.rest_api_get_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.rest-api.id
  resource_id = aws_api_gateway_resource.rest_api_resource.id
  http_method = aws_api_gateway_method.rest_api_get_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "LambdaIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.rest-api.id
  resource_id = aws_api_gateway_resource.rest_api_resource.id
  http_method = aws_api_gateway_method.rest_api_get_method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
}

/*resource "aws_api_gateway_deployment" "rest_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest-api.id

  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_method.method",
    "aws_api_gateway_integration.integration"
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.rest_api_resource.id,
      aws_api_gateway_method.rest_api_get_method.id,
      aws_api_gateway_integration.lambda.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}*/

/*resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.rest_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.rest-api.id
  stage_name    = "prod"
}*/
#complete rest api gateway integration and deployment 

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.rest-api.id
  resource_id   = aws_api_gateway_rest_api.rest-api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}
resource "aws_apigatewayv2_api" "lambda-api" {
  name          = "v2-http-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["https://www.pauldesalvo.net"]
    allow_methods = ["GET"]
    allow_headers = ["content-type"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "lambda-stage" {
  api_id      = aws_apigatewayv2_api.lambda-api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda-integration" {
  api_id               = aws_apigatewayv2_api.lambda-api.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_domain_name" "api_custom_domain" {
  domain_name = "api.pauldesalvo.net"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api_ssl_cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

/*resource "aws_apigatewayv2_integration_response" "integration-response" {
  api_id = aws_apigatewayv2_api.lambda-api.id
  integration_id = aws_apigatewayv2_integration.lambda-integration.id
  integration_response_key = "/200/"
}*/

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda-api.id
  route_key = "GET /visitors"
  target    = "integrations/${aws_apigatewayv2_integration.lambda-integration.id}"
}

/*resource "aws_apigatewayv2_route_response" "route-response" {
  api_id = aws_apigatewayv2_api.lambda-api.id
  route_id = aws_apigatewayv2_route.lambda_route.id
  route_response_key = "$default"
}*/

resource "aws_lambda_permission" "api-gw" {
  statement_id  = "AllowedExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda-api.execution_arn}/*"
}


