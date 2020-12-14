module "basic_auth" {
  source = "github.com/builtinnya/aws-lambda-edge-basic-auth-terraform/module"

  basic_auth_credentials = {
    user = var.static_web_basic_auth_username
    password = var.static_web_basic_auth_password
  }
}

locals {
  aws_s3_bucket_name = "aashishpundalik.com"
}

module "dev-env" {
  source = "./modules/s3-cloudfront"
  s3_bucket_name = local.aws_s3_bucket_name
  cloudfront_origin_domain = local.aws_s3_bucket_name
  aws_access_key = var.static_web_aws_access_key
  aws_secret_key = var.static_web_aws_secret_key
  basic_auth_lambda_arn = module.basic_auth.lambda_arn
}