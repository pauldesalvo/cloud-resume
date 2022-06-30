variable "domain_name" {
  type        = string
  description = "Domain name of resume website."
  default     = "pauldesalvo.net"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket without the www. prefix - Use domain_name"
  default     = "resume-pauldesalvo-bucket"
}

variable "myregion" {
  type        = string
  description = "region for aws account"
  default     = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}
