variable "s3_bucket_name" {}

variable "cloudfront_origin_domain" {
  description = "CNAME alias"
}

variable "aws_secret_key" {}
variable "aws_access_key" {}

variable "basic_auth_lambda_arn" {
  description = "arn value for the lamda edge function created for basic auth"
}