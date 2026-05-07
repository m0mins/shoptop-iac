resource "random_pet" "bucket_name" {
  keepers = {
    bucket_name = var.project_name
  }
  length = 1
}

resource "aws_s3_bucket" "s3_backend" {
  bucket = "${var.project_name}-tf-backend-${random_pet.bucket_name.id}"
}

resource "aws_s3_bucket_versioning" "s3_backend_versioning" {
  bucket = aws_s3_bucket.s3_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}