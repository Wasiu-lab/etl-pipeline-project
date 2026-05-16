# ==============================================================
# outputs.tf — values printed after terraform apply
# These are the values you'll need to update your .env file
# and connect your pipeline to the newly provisioned RDS instance
# ==============================================================

output "rds_endpoint" {
  description = "RDS instance endpoint — paste this into your .env as DB_HOST"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "rds_db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "vpc_id" {
  description = "VPC ID — useful for Phase 7 Lambda configuration"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID — Lambda will use this in Phase 7"
  value       = aws_subnet.public.id
}

output "rds_security_group_id" {
  description = "Security group ID — Lambda will reference this in Phase 7"
  value       = aws_security_group.rds.id
}