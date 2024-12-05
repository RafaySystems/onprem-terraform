variable "identifier" {}
variable "instance_class" {}
variable "engine" {}
variable "engine_version" {}
variable "backup_retention_period" {}
variable "username" {}
# variable "rds_password" {
#   sensitive   = true
# }
variable "vpc_id" {}
variable "vpc_cidr" {}
variable "subnet_id" {}
variable "db_name" {}
variable "subnet_name" {}
variable "storage_encrypted" {}
variable "publicly_accessible" {}
variable "skip_final_snapshot" {}
variable "cluster_name" {}
variable "default_tags" {}
variable "final_snapshot_identifier" {}
variable "instance_ips" {}
variable "rds_SecretName" {}
/* variable "cluster_security_group_id" {} */
variable "recovery_window_in_days" {}
variable "db_major_version_upgrade" {}
variable "db_minor_version_upgrade" {}
variable "ingress_cidr_blocks" {}
variable "egress_cidr_blocks" {}

variable "num_cluster_instances" {}
variable "copy_tags_to_snapshot" {}
variable "deletion_protection" {}
variable "performance_insights_enabled" {}

### Alarms variables
variable "controllername" {}
variable "apply_immediately" {}
variable "use_aws_secret_manager" {}
