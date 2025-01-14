variable "deploymentType" {}
variable "rds_hostname" {}
variable "rds_port" {}
variable "rds_username" {}
variable "domain_name" {}
variable "rds_password" {}
variable "cluster_id" {}
variable "region" {}
variable "path" {}
variable "logo_path" {}
variable "cluster_name" {}
variable "cluster_endpoint" {}
variable "cert_acm" {}
variable "aws_efs_fs_id" {}
variable "efs_iam_role_arn" {}
variable "super_user" {}
variable "super_user_SecretName" {}
variable "enable_hosted_dns_server" {}
variable "external_lb" {}
variable "use_instance_role" {}
variable "aws_account_id" {}
variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "kapenter_role_arn" {}
variable "amp_ingest_role_arn" {}
variable "amp_query_role_arn" {}
variable "amp_workspace_id" {}
variable "controllerName" {}
variable "console-certificate" {}
variable "console-key" {}
variable "partner_name" {}
variable "product_name" {}
variable "help-desk-email" {}
variable "notifications-email" {}
variable "external-database" {}
variable "amp-enabled" {}
variable "generate-self-signed-certs" {}
variable "karpenter-enabled" {}
variable "external-dns-enabled" {}
variable "external-dns-role_arn" {}
variable "externalDnsHostedZoneID" {}
variable "backup-restore-enabled" {}
variable "backup-restore-role_arn" {}
variable "backup-restoreSchedule" {}
variable "backup-restore-bucket_name" {}
variable "backup-restore" {}
variable "opensearchEnabled" {}
variable "opensearch-user-name" {}
variable "opensearch-user-password" {}
variable "kinesis-firehose-delivery-stream" {}
variable "kinesis-firehose-role-arn" {}
variable "opensearch-endpoint" {}
variable "controllerRepoUrl" {}
variable "controllerVersion" {}

variable "ec2_instance_type" {}
variable "vpc_id" {}
variable "ami" {}
variable "subnet_id" {}
variable "public-ip" {}
variable "key_name" {}
variable "delete_on_termination" {}
variable "volume_size" {}
variable "volume_type" {}
variable "default_tags" {}

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "minReplicaCount" {}
variable "loadBalancerType" {
  default = "internet-facing"
}

variable "irsa_instance_iam_role_arn" {}
variable "recovery_window_in_days" {}

variable "logsstream_name" {}
variable "kinesis_firehose_logsrole_arn" {}
variable "RetentionPeriod" {}
variable "BackupFolderName" {}
#variable "RadmVersion" {}
variable "istioVersion" {}
variable "super_user_password" {}
variable "run_only_infra" {}
variable "ecr_aws_access_key_id" {}
variable "ecr_aws_secret_access_key" {}
variable "aws-ecr-endpoint" {}
variable "jfrog_user_name" {}
variable "jfrog_password" {}
variable "ecr_aws_irsa_role" {}
variable "tar-extract-path" {}
variable "jfrog_endpoint" {}
variable "proxy_host" {}
variable "proxy_ip" {}
variable "proxy_port" {}
variable "no-proxy" {}
variable "irsa_role_enabled" {}
variable "lb_controller_clusterName" {}
variable "lb_controller_role_arn" {}
variable "tsdb_backup_role_arn" {}
variable "tsdb_backup_bucket" {}

variable "deploymentSize" {}
variable "external_logging_enabled" {}
variable "external_logging_endpoint" {}
variable "external_logging_user_name" {}
variable "external_logging_user_password" {}
variable "external_metrics_enabled" {}
variable "jfrog_insecure" {}
variable "blueprintVersion" {}
variable "rafay_registry_type" {}
variable "tsdb_backup_enabled" {}
variable "engine_api_blob_provider" {}
variable "engine_api_blob_bucket" {}
variable "engine_api_irsa_role_arn" {}
variable "registry_subpath" {}
variable "use_aws_secret_manager" {}
variable "resticEnable" {}
