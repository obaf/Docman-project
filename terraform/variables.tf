variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "hello_message" {
  description = "Text written into hello-world.txt."
  type        = string
  default     = "Hello, World! Created by Terraform, deployed by GitHub Actions."
}
