# variable "identifier" {}
variable "instance_class" {}
variable "allocated_storage" {}
variable "engine" {}
variable "engine_version" {}
variable "backup_retention_period" {}
variable "username" {}
# variable "rds_password" {
#   sensitive   = true
# }
variable "db_name" {}
variable "multi_az" {}
variable "storage_encrypted" {}
variable "publicly_accessible" {}
variable "skip_final_snapshot" {}
variable "default_tags" {}
variable "subnet_id" {}
# variable "subnet_name" {}
variable "instance_ips" {}
variable "db_snapshot_identifier" {}
variable "db_instance_identifier_id" {}
variable "final_snapshot_identifier" {}
variable "cluster_name" {}
variable "vpc_id" {}
variable "secretsName" {}
variable "recovery_window_in_days" {}
variable "ingress_cidr_blocks" {}
variable "egress_cidr_blocks" {}