terraform {
  required_version = ">=1.1,<=2.0.0"
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}