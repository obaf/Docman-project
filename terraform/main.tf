provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "Docman-project"
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

# Bucket names are global, so suffix with the account ID to keep it unique.
resource "aws_s3_bucket" "hello" {
  bucket = "docman-hello-world-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "hello" {
  bucket = aws_s3_bucket.hello.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# The hello-world text file itself.
resource "aws_s3_object" "hello" {
  bucket       = aws_s3_bucket.hello.id
  key          = "hello-world.txt"
  content      = "${var.hello_message}\n"
  content_type = "text/plain"
}
