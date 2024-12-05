output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.postgres_sql.address
  #sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgres_sql.port
  # sensitive   = true
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.postgres_sql.username
  #sensitive   = true
}

output "rds_id" {
  value = aws_db_instance.postgres_sql.id
}

output "rds_password" {
  value = local.db_creds != null ? local.db_creds.password : random_password.password.result
  /* sensitive = true */
}