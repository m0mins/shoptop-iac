locals {
  bucket_name = "${var.project_namespace}-${var.stage}-frontend-${random_pet.bucket_name.id}"
  # domain_alias = terraform.workspace == "prod" ? ["${var.cluster_domain_frontend}"] : ["${var.stage}.${var.cluster_domain_frontend}"]
  domain_alias = terraform.workspace == "prod" ? ["strativ-support.se"] : ["demo.strativ-support.se"]

  s3_origin_id = random_uuid.origin_id.id
}

resource "aws_s3_bucket" "site_bucket" {
  bucket = local.bucket_name
  tags = {
    Name        = module.this.id
    Environment = module.this.stage
  }
}

resource "aws_s3_bucket_ownership_controls" "site_bucket_preferred_control" {
  bucket = aws_s3_bucket.site_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


resource "aws_s3_bucket_acl" "site_bucket_acl" {
  depends_on = [aws_s3_bucket.site_bucket]
  bucket     = aws_s3_bucket.site_bucket.id
  acl        = "private"
}


resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}


resource "random_pet" "bucket_name" {
  keepers = {
    site_bucket_seed = "${module.this.id}-bucket"
  }
  length = 1
}

resource "random_uuid" "origin_id" {
  keepers = {
    origin_seed = "${module.this.id}-origin"
  }
}

resource "aws_cloudfront_distribution" "site_s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.site_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  aliases = local.domain_alias

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      # locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = module.this.stage
  }

  viewer_certificate {
    # cloudfront_default_certificate = true
    #acm_certificate_arn      = module.acm_cert_frontend.acm_certificate_arn
    acm_certificate_arn = var.acm_cert_frontend_arn

    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/"
  }
}

resource "aws_cloudfront_origin_access_identity" "site_identity" {
  comment = "${module.this.id} frontend identity"
}

resource "aws_s3_bucket_policy" "allow_portal_frontend_cloudfront" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = data.aws_iam_policy_document.portal_frontend_origin.json
}

data "aws_iam_policy_document" "portal_frontend_origin" {
  statement {
    sid       = "S3GetobjectForCloudfront"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site_bucket.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.site_identity.iam_arn]
    }

  }
}