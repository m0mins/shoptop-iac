output "static_content_bucket_name" {
  value = aws_s3_bucket.static_content_s3_backend.id
}