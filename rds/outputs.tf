output "rds_hostname" {
  description = "RDS instance hostname"
  value       = var.replication_db == "" ? aws_db_instance.postgres_sql[0].address : aws_db_instance.postgres_sql_replica[0].address
  #sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = var.replication_db == "" ? aws_db_instance.postgres_sql[0].port : aws_db_instance.postgres_sql_replica[0].port
  # sensitive   = true
}

output "rds_username" {
  description = "RDS instance root username"
  value       = var.replication_db == "" ? aws_db_instance.postgres_sql[0].username : aws_db_instance.postgres_sql_replica[0].username
  #sensitive   = true
}

output "rds_id" {
  value = var.replication_db == "" ? aws_db_instance.postgres_sql[0].id : aws_db_instance.postgres_sql_replica[0].id
}
