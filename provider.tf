provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.10" # use_lockfile needs 1.10+

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    bucket       = "sctp-tfstate-ce13"
    key          = "yq/snyk-3.6"
    region       = "us-east-1"
    use_lockfile = true
  }
}
