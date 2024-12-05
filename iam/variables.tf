variable "kms_key_arn" {}
variable "cluster_name" {}
variable "BackupRestore_role_name" {}
variable "BackupRestore_policy_name" {}
variable "s3_backup_restore_bucketname" {}
variable "default_tags" {}
variable "irsa_AMP_policy_name" {}
variable "irsa_instance_iam_role_name" {}
variable "use-instance-role" {}
variable "ebs_iam_role_name" {}
variable "kms_ebspolicy_name" {}
variable "backup-restore" {}
variable "backup_enabled" {}
variable "s3_tsdb_backup_bucket" {}
variable "tsdb_backup_role_name" {}
variable "tsdb_backup_policy_name" {}
variable "amp-enabled" {}
variable "eaas_bucketname" {}
variable "eaas_role_name" {}
variable "eaas_policy_name" {}
variable "eaas_sse_algorithm" {}
variable "iam_max_session_duration" {}
variable "use_existing_s3_backup_restore_bucket" {
  default = false
}
variable "use_existing_s3_eaas_bucket" {
  default = false
}
variable "use_existing_s3_tsdb_bucket" {
  default = false
}
variable "tsdb_backup_enabled" {

}
