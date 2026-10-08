output "public_ip" {
  description = "Public IP of the Oracle server."
  value       = aws_instance.oracle.public_ip
}

output "ami" {
  description = "AMI the instance was built from."
  value       = "${data.aws_ami.almalinux9.id} (${data.aws_ami.almalinux9.name})"
}

output "allowed_from" {
  description = "The only CIDR that can reach ports 22 and 1521."
  value       = local.allowed_cidr
}

output "ssh_command" {
  description = "Step 1: log in to the server."
  value       = "ssh -i ~/.ssh/docman-oracle.pem ec2-user@${aws_instance.oracle.public_ip}"
}

output "setup_progress_command" {
  description = "Run on the server: watch the Oracle install (done when /var/log/oracle-setup.done exists)."
  value       = "sudo tail -f /var/log/oracle-setup.log"
}

output "sqlplus_command" {
  description = "Step 2: run on the server to connect as SCOTT."
  value       = "sqlplus scott/${var.scott_password}@localhost/FREEPDB1"
}

output "remote_connect_string" {
  description = "From your own machine (SQL Developer / sqlplus), if you have an Oracle client."
  value       = "scott/${var.scott_password}@//${aws_instance.oracle.public_ip}:1521/FREEPDB1"
}

output "sys_password" {
  description = "SYS / SYSTEM / PDBADMIN password (terraform output -raw sys_password)."
  value       = random_password.oracle.result
  sensitive   = true
}
