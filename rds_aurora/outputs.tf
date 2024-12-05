output "rds_aurora_endpoint" {
  description = "RDS aurora instance endpoint"
  value       = aws_rds_cluster.cluster.endpoint
  #sensitive   = true
}

output "rds_aurora_port" {
  description = "RDS aurora instance port"
  value       = aws_rds_cluster.cluster.port
  # sensitive   = true
}

output "rds_aurora_username" {
  description = "RDS aurora instance root username"
  value       = aws_rds_cluster.cluster.master_username
  #sensitive   = true
}

output "rds_aurora_id" {
  description = "RDS aurora instance id"
  value       = aws_rds_cluster.cluster.id
}

output "rds_aurora_password" {
  value = local.db_creds != null ? local.db_creds.password : random_password.password.result
  /* sensitive = true */
}