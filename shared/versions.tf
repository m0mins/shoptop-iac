terraform {
  required_version = ">=1.1,<=2.0.0"
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.6"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}
provider "aws"{
  alias = "virginia"
  region = "us-east-1"
}