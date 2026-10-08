variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = <<-EOT
    Oracle Database Free needs 2 GB RAM minimum. t3.small (2 GB) is the smallest
    type AWS lists as free-tier-eligible in us-east-1 that meets it; the install
    takes ~20 min there. m7i-flex.large (8 GB) is also listed and much faster.
    t3.micro (1 GB) is not enough for Oracle.
  EOT
  type        = string
  default     = "t3.small"
}

variable "root_volume_gb" {
  description = "Root disk size. Oracle software + database need ~15 GB; free tier covers 30 GB of EBS."
  type        = number
  default     = 30
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach SSH (22) and the Oracle listener (1521). Null = the public IP of whoever runs terraform."
  type        = string
  default     = null
}

variable "scott_password" {
  description = "Password for the SCOTT demo user. Must satisfy Oracle's default rules: 8+ chars with a letter and a digit."
  type        = string
  default     = "Tiger1234"
}

# Source: the INSTALL_FILE_1 argument in Oracle's own Containerfile.free
# (github.com/oracle/docker-images, OracleDatabase/SingleInstance/dockerfiles/23.26.0).
variable "oracle_rpm_url" {
  description = "Oracle Database Free RPM (el9 build)."
  type        = string
  default     = "https://download.oracle.com/otn-pub/otn_software/db-free/oracle-ai-database-free-26ai-23.26.2-1.el9.x86_64.rpm"
}

variable "oracle_preinstall_rpm_url" {
  description = "Oracle's preinstall RPM: creates the oracle user and groups, sets kernel parameters and limits."
  type        = string
  default     = "https://yum.oracle.com/repo/OracleLinux/OL9/appstream/x86_64/getPackage/oracle-ai-database-preinstall-26ai-1.0-3.el9.x86_64.rpm"
}
