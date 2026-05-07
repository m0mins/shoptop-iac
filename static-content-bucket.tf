resource "random_pet" "static_content_bucket_name" {
  keepers = {
    bucket_name = var.project_namespace
  }
  length = 1
}

resource "aws_s3_bucket" "static_content_s3_backend" {
  bucket = "${var.project_namespace}-${var.stage}-static-content-s3-bucket-${random_pet.static_content_bucket_name.id}"
}

resource "aws_s3_bucket_public_access_block" "static_content_bucket_public_access_block" {
  bucket = aws_s3_bucket.static_content_s3_backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "static_content_bucket_cors_configuration" {
  bucket = aws_s3_bucket.static_content_s3_backend.bucket
  cors_rule {
    allowed_headers = [
      "*",
    ]
    allowed_methods = [
      "GET",
      "PUT",
    ]
    allowed_origins = [
      "*",
    ]
    expose_headers  = []
    max_age_seconds = 3000
  }

}