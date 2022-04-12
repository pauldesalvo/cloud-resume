// TODO - Register domain name for resume website using Route 53.
variable "domain_name" {
  type        = string
  description = "Domain name of resume website."
  default     = "pauldesalvo.net"
}

//TODO - Use registered domain for bucket name
variable "bucket_name" {
  type        = string
  description = "The name of the bucket without the www. prefix - Use domain_name"
  default     = "resume-pauldesalvo-bucket"
}

