provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "Docman-project"
      Component = "oracle-ec2"
      ManagedBy = "terraform"
    }
  }
}

###############################################################################
# Lookups
###############################################################################

# Public IP of whoever is running terraform; used to lock down the security group.
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  allowed_cidr = coalesce(var.allowed_cidr, "${chomp(data.http.my_ip.response_body)}/32")
}

# AlmaLinux 9: RHEL 9-compatible (Oracle supports RHEL 9) and a free community AMI.
# Oracle does not publish Oracle Linux community AMIs in this region.
data "aws_ami" "almalinux9" {
  most_recent = true
  owners      = ["764336703387"] # AlmaLinux OS Foundation

  filter {
    name   = "name"
    values = ["AlmaLinux OS 9*x86_64*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

# Not every AZ offers every instance type (us-east-1e has no t3), so only
# consider default subnets in AZs where the chosen type can actually launch.
data "aws_ec2_instance_type_offerings" "chosen" {
  location_type = "availability-zone"

  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
}

data "aws_subnets" "candidates" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
  filter {
    name   = "availability-zone"
    values = data.aws_ec2_instance_type_offerings.chosen.locations
  }
}

###############################################################################
# SSH key pair (private half written to ~/.ssh, never into the repo)
###############################################################################

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "oracle" {
  key_name   = "docman-oracle"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.ssh.private_key_openssh
  filename        = pathexpand("~/.ssh/docman-oracle.pem")
  file_permission = "0600"
}

###############################################################################
# Network
###############################################################################

resource "aws_security_group" "oracle" {
  name        = "docman-oracle-ec2"
  description = "SSH and Oracle listener, from one address only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.allowed_cidr]
  }

  ingress {
    description = "Oracle listener"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.allowed_cidr]
  }

  egress {
    description = "All outbound (package and RPM downloads)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "docman-oracle-ec2" }
}

###############################################################################
# Instance
###############################################################################

# SYS / SYSTEM / PDBADMIN password. Oracle's configure step wants 8+ chars with
# upper, lower and a digit; no specials keeps it copy-paste safe.
resource "random_password" "oracle" {
  length      = 16
  special     = false
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
}

resource "aws_instance" "oracle" {
  ami                         = data.aws_ami.almalinux9.id
  instance_type               = var.instance_type
  subnet_id                   = sort(data.aws_subnets.candidates.ids)[0]
  vpc_security_group_ids      = [aws_security_group.oracle.id]
  key_name                    = aws_key_pair.oracle.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_gb
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  # Runs once at first boot: installs Oracle, creates the database and the
  # SCOTT schema. Editing the script replaces the instance.
  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/install-oracle.sh.tftpl", {
    oracle_password           = random_password.oracle.result
    scott_password            = var.scott_password
    oracle_rpm_url            = var.oracle_rpm_url
    oracle_preinstall_rpm_url = var.oracle_preinstall_rpm_url
  })

  tags = { Name = "docman-oracle-free" }
}
