locals {
  s3_bucket_region = "ap-southeast-1"
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = local.s3_bucket_region
  alias = "singapore"
}

provider "aws" {
  alias = "nvirginia"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = "us-east-1"
}

resource "aws_s3_bucket" "static-web" {
  provider = aws.singapore
  bucket = var.s3_bucket_name
  acl = "public-read"
  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForGetBucketObjects",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.s3_bucket_name}/*"
        }
    ]
}
  EOF
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

locals {
  cloudfront_origin_id = "S3-Website-${aws_s3_bucket.static-web.bucket_regional_domain_name}"
}

resource "aws_acm_certificate" "static-web" {
  provider = aws.nvirginia

  domain_name = var.cloudfront_origin_domain
  validation_method = "EMAIL"

  tags = {
    Environment = "dev"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_distribution" "static-web" {
  count = 1
  provider = aws.nvirginia
  depends_on = [
    aws_s3_bucket.static-web,
    aws_acm_certificate.static-web
  ]

  aliases = [var.cloudfront_origin_domain]
  price_class = "PriceClass_All"
  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  viewer_certificate {
    ssl_support_method = "sni-only"
    acm_certificate_arn = aws_acm_certificate.static-web.arn
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  origin {
    origin_id = local.cloudfront_origin_id
    domain_name = aws_s3_bucket.static-web.bucket_regional_domain_name

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.cloudfront_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress = true
    min_ttl = 60
    default_ttl = 600
    max_ttl = 600

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  lambda_function_association {
    event_type   = "viewer-request"
    lambda_arn   = var.basic_auth_lambda_arn
    include_body = false
  }
}