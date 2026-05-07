terraform {
  backend "s3" {
    bucket = "shoptop-tf-backend-shrew"
    region = "ap-southeast-1"
    key    = "terraform.tfstate"
  }
}