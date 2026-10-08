terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote state so every GitHub Actions run shares the same view of what exists.
  # use_lockfile = native S3 state locking (Terraform >= 1.10), no DynamoDB needed.
  backend "s3" {
    bucket       = "docman-project-tfstate-768332541841"
    key          = "hello-world/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
