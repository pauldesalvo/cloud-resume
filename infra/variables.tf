// TODO - Register domain name for resume website using Route 53.
variable "enter_domain_name_here" {
  type = string
  description = "Domain name of resume website."
}

//TODO - Use registered domain for bucket name
variable "enter_bucket_name_here" {
    type = string
    description = "The name of the bucket without the www. prefix - Use domain_name"
}

variable "common_tags" {
  description = "Common tags you want applied to all components"
}