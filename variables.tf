###---GLOBAL VARIABLES---#
variable "region" {
  #default = "us-west-2"
}

###-----EKS CLUSTER VARIABLES----##
variable "controller_name" {
  #default = ""
}
variable "eks_cluster_version" {
  default = "1.26"
}
variable "eks_cluster_log_types" {
  default = ["api", "audit"]
}
variable "retention_days" {
  default = 3
}
# variable "eks_iam_role_name" {
#   default = "rafay-eks-cluster-iam-role"
# }
variable "eks_endpoint_private_access" {
  default = true
}
variable "eks_endpoint_public_access" {
  default = false
}
variable "eks_endpoint_public_access_cidr" {
  default = ["0.0.0.0/0"]
}
# variable "eks_cluster_node_group_name" {
#   default = "rafay-eks-node-group"
# }
# variable "eks_workernode_iam_role_name" {
#   default = "rafay-eks-worker-iam-role"
# }
variable "prod_instance_type" {
  default = ["c5a.4xlarge", "c5.4xlarge", "c6a.4xlarge"]
}
variable "dev_instance_type" {
  default = ["c5a.4xlarge", "c5.4xlarge", "c6a.4xlarge"]
}

variable "ami_id" {
  #default = "ami-085e8e02353a59de5"
}
variable "desired_capacity" {
  default = 4
}
variable "max_size" {
  default = 9
}
variable "min_size" {
  default = 4
}
variable "device_name" {
  default = "/dev/xvdb"
}
variable "volume_size" {
  default = 200
}
variable "volume_type" {
  default = "gp2"
}
variable "ec2_ssh_key" {
  #default = ""
}
variable "creates_cloudwatch_log_group" {
  default = false
}
# variable "launchtemp_name" {
#   default = "launch-template-for-eks"
# }
variable "launchtemp_update_version" {
  default = true
}
variable "resource_type" {
  default = "instance"
}
variable "additional_tags" {
  #default = ""
}
variable "user_custom_commands" {
  type    = string
  default = <<-EOT
  EOT
}
variable "capacity_type" {
  #default = true
}
variable "ebs_addon_name" {
  default = "aws-ebs-csi-driver"
}
variable "ebs_addon_version" {
  default = "v1.26.0-eksbuild.1"
}
variable "ebs_resolve_conflicts" {
  default = "OVERWRITE"
}
variable "bottleRocket_os" {}

variable "eks_cluster_encryption" {}

variable "encryption_resources" {
  default = ["secrets"]
}

###-----VPC VARIABLES-----####
variable "create_vpc" {
  #default = true
}
variable "vpc_id" {
  #default = ""
}
# variable "vpc_name" {
#   default = "rafay-vpc-controller"
# }
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "azs" {
  #default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}
variable "ingress_cidr_blocks" {
  default = ["10.0.0.0/16", "0.0.0.0/0"]
}

variable "egress_cidr_blocks" {
  default = ["0.0.0.0/0"]
}

variable "public_subnets_cidr" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
variable "public_subnets_ids" {
  #default = ""
}
variable "private_subnets_cidr" {
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}
variable "private_subnets_ids" {
  #default = ""
}
variable "destination_cidr_block" {
  default = "0.0.0.0/0"
}
variable "enable_dns_support" {
  default = true
}
variable "enable_dns_hostnames" {
  default = true
}
variable "enable_nat_vpc" {
  default = true
}
variable "map_public_ip_on_launch" {
  default = true
}
variable "public_ip_privatesubnet" {
  default = false
}
# variable "vpc_sg_name" {
#   default = "rafay-vpc-sg"
# }

variable "additional_cidr_block" {
  default = []
}
variable "worker_nodes_private_subnets_cidr" {
  default = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
}
variable "worker_nodes_private_subnets_ids" {
  default = []
}


###----EFS VARIABLES--------###
# variable "efs_role_name" {
#   default = "rafay-eksctl-eks-onprem-controller-addon-iamservic-Role"
# }
# variable "efs_policy_name" {
#   default = "rafay-eksctl-eks-onprem-controller-addon-iamservic-policy"
# }
# variable "efs_creation_token" {
#   default = "rafay-efs_controller_file_system"
# }
# variable "efs_tag_name" {
#   default = "rafay-efs_filesystem"
# }
# variable "efs_name_prefix" {
#   default = "rafay-efs_sg_controller"
# }

####------IAM VARIABLES------##
variable "s3_backup_restore_bucketname" {
  default = "rafay-BackupRestore-eks-bucket"
}

# variable "external_dns_role_name" {
#   default = "rafay-eks-external_dns_role_name"
# }
# variable "external_dns_policy_name" {
#    default = "rafay-eks-external_dns_policy_name"
# }
# variable "controller_role_name" { 
#   default = "rafay-eks-controller-iam-role"
# }
# variable "controller_policy_name" { 
#   default = "rafay-STS"
# }
# variable "controller_eks_policy_name" {
#    default = "rafay-km-eks-full"
# }

###--------IAM USER VARIABLES----###
/* variable "sts_policy_name" {
  #default = "Rafay-User"
}
variable "iam_user_name" {
  #default = "rafay-sts-policy-for-user"
} */

##---RDS Variables --###
# variable "rds_identifier" { 
#   default = "rafay-rds-controller"
# }
variable "prod_instance_class" {
  default = "db.m6g.4xlarge"
}

variable "dev_instance_class" {
  default = "db.t4g.large"
}
variable "prod_rds_allocated_storage" {
  default = 300
}
variable "dev_rds_allocated_storage" {
  default = 100
}
variable "rds_engine" {
  default = "postgres"
}
variable "rds_engine_version" {
  default = "13.8"
}
variable "rds_backup_retention_period" {
  default = 3
}
variable "rds_username" {
  default = "postgres"
}
variable "rds_password" {
  default = ""
}

variable "rds_db_name" {
  default = "postgres"
}
# variable "rds_subnet_name" { 
#   default = "postgres-db-subnet"
# }
variable "rds_multi_az" {
  default = true
}
variable "rds_storage_encrypted" {
  default = true
}
variable "rds_iam_database_authentication_enabled" {
  default = true
}
variable "rds_publicly_accessible" {
  #default = true 
}
variable "rds_skip_final_snapshot" {
  default = true
}
variable "rds_parameter_name" {
  default = "rafay-restored-postgresql"
}

variable "final_snapshot_identifier" {
  #default = "restored-postgresql" 
}
variable "existing_rds_host_address" {
  #default = "" 
}
variable "db_major_version_upgrade" {
  default = false
}
variable "db_minor_version_upgrade" {
  default = false
}
variable "dbsecret_arn" {}

variable "apply_immediately" {
  default = true
}
variable "num_cluster_instances" {
  default = 1
}
variable "copy_tags_to_snapshot" {
  default = true
}
variable "deletion_protection" {
  default = false
}
variable "performance_insights_enabled" {
  default = false
}
variable "replication_source_db_arn" {}
###--------- AMP Variables ----###
# variable "prometheus_workspace_alias" { 
#   default = "rafay-Prometheus-Metrics"
# }
# variable "ingest_iam_role_name" { 
#   default = "rafay-amp-iamproxy-ingest-role"
# }
# variable "ingest_iam_policy_name" { 
#   default = "rafay-AMPIngestPolicy"
# }
# variable "query_iam_role_name" { 
#   default = "rafay-amp-iamproxy-query-role"
# }
# variable "query_iam_policy_name" {
#    default = "rafay-AMPQueryPolicy" 
# }

###--------- AMP Variables ----###
variable "grafana_workspace_data_sources" {
  default = ["AMAZON_OPENSEARCH_SERVICE", "PROMETHEUS"]
}
variable "grafana_workspace_permission_type" {
  default = "SERVICE_MANAGED"
}
variable "grafana_workspace_authentication_providers" {
  default = ["AWS_SSO"]
}
variable "grafana_workspace_account_access_type" {
  default = "CURRENT_ACCOUNT"
}


###-------SNS variables--------###
# variable "sns_topic_name" { 
#   default = "rafay-sns-topic"
# }
variable "protocol" {
  default = "email"
}
/* variable "email_lists" {
  #default = "example@gmail.com" 
} */
####----- KARPENTER VARIABLES ----###
# variable "karpenter_role" { 
#   default = "rafay-karpenter_eks_controller"
# }

##-----OPENSEARCH----###
variable "os_domain" {
  #   default = "rafay-opensearch"
}

variable "prod_os_instance_type" {
  default = "r6g.large.search"
}
variable "dev_os_instance_type" {
  default = "t3.small.search"
}
variable "prod_os_instance_count" {
  default = 3
}
variable "dev_os_instance_count" {
  default = 1
}
variable "os_ebs_enabled" {
  default = true
}
variable "os_volume_type" {
  default = "gp2"
}
variable "prod_os_ebs_volume_size" {
  default = 100
}
variable "dev_os_ebs_volume_size" {
  default = 30
}
variable "opensearch_version" {
  default = "OpenSearch_1.1"
}
variable "prod_os_zone_awareness_enabled" {
  default = true
}
variable "dev_os_zone_awareness_enabled" {
  default = false
}
variable "os_encrypt_at_rest" {
  default = true
}
variable "os_node_to_node_encryption" {
  default = true
}
variable "os_advanced_sg_enabled" {
  default = true
}
variable "os_internal_user_database_enabled" {
  default = true
}
variable "os_master_user_name" {
  default = "Rafay"
}
# variable "os_master_user_password" { 
#   default = ""
# }
variable "os_enforce_https" {
  default = true
}
variable "os_tls_security_policy" {
  default = "Policy-Min-TLS-1-2-2019-07"
}
variable "os_auto_tune_desired_state" {
  default = "DISABLED"
}
variable "os_auto_tune_rollback_on_disable" {
  default = "NO_ROLLBACK"
}

###----KINESIS VARIABLES-----####
# variable "s3_bucket" { 
#   default = "rafay-opensearch-logging"
# }
# variable "kinesis_iam_role" { 
#   default = "rafay-kinesisFirehose-controller-role" 
# }
# variable "kinesis_iam_policy" { 
#   default = "rafay-kinesisFirehose-controller-policy"
# }
# variable "kinesis_es_policy" { 
#   default = "rafay-kinesis_es_controller_policy"
# }
variable "destination" {
  default = "elasticsearch"
}
variable "s3_buffer_size" {
  default = 10
}
variable "s3_buffer_interval" {
  default = 60
}
variable "s3_compression_format" {
  default = "GZIP"
}
variable "s3_log_stream_name" {
  default = "BackupDelivery"
}
variable "es_index_name" {
  default = "relay-audits"
}
variable "es_logsindex_name" {
  default = "rafay-controller-logs"
}
variable "es_buffering_size" {
  default = 10
}
variable "es_buffering_interval" {
  default = 60
}
variable "s3_backup_mode" {
  default = "AllDocuments"
}
variable "os_log_stream_name" {
  default = "DestinationDelivery"
}
variable "kms_key_period" {
  default = 30
}

variable "logsstream_name" {
  #default = ""
}

##-------config Variables ----##
variable "deploymentType" {
  default = "EKS"
}
variable "domain_name" {
  #default = "" 
}
variable "path" {
  #default = "" 
}
variable "logo_path" {
  default = ""
}
variable "cert_acm" {
  #default = "" 
}
variable "super_user" {
  #default = "" 
}
variable "superuser_secret_arn" {
  default = ""
}
variable "super_user_password" {
  default = ""
}
variable "super_user_SecretName" {
}
variable "enable_hosted_dns_server" {
  default = false
}
variable "external_lb" {
  default = true
}
variable "use_instance_role" {
  default = false
}
variable "aws_access_key" {
  #default = "" 
}
variable "aws_secret_key" {
  #default = ""
}
variable "controllerName" {
  default = "RafayAirGapController"
}
variable "console-certificate" {
  default = "" ##-- Values should be base64encoded
}
variable "console-key" {
  default = "" ##-- Values should be base64encoded
}
variable "partner_name" {
  #default = "Rafay Cloud" 
}
variable "product_name" {
  #default = "Rafay Systems"
}
variable "help-desk-email" {
  #default = "helpdesk@rafay.co"
}
variable "notifications-email" {
  #default = "notify@rafay.co"
}
variable "external-database" {
  default = true
}
variable "amp-enabled" {
  default = true
}
variable "generate-self-signed-certs" {
  #default = true
}
variable "karpenter-enabled" {
  default = true
}
variable "external-dns-enabled" {
  default = true
}
variable "publicLoadBalancer" {
  default = "true"
}

variable "backup-restore" {
  default = false
}
variable "backup-restoreSchedule" {
  #default = ""
}
variable "backup_enabled" {
  default = true
}
variable "backup_resticEnable" {
  default = false
}

variable "opensearchEnabled" {
  default = true
}

variable "public-ip" {
  default = false
}
variable "ec2_instance_type" {
  default = "t2.large"
}

variable "controllerVersion" {
  #default = ""
}
variable "prod_controllerRepoUrl" {
  #default = "" 
}
variable "dev_controllerRepoUrl" {
  #default = "" 
}

###------ROUTE 53-------###
variable "creates_route53_zone" {
  default = false
}
variable "allow_overwrite" {
  type    = bool
  default = true
}
variable "record_name_ui" {
  default = ["api", "console", "fluentd-aggr", "grafana", "ops-console", "prometheus", "repo"]
}
variable "record_ttl" {
  default = 300
}
variable "record_type" {
  default = "CNAME"
}
variable "zone_id" {
  # default = ""
}
variable "record_name_backend" {
  default = ["*.cdrelay", "*.core-connector", "*.core", "*.kubeapi-proxy", "rcr", "regauth", "*.user", "peering", "*.connector.infrarelay", "*.user.infrarelay"]
}
variable "delete_on_termination" {
  default = true
}

###-------RESTORES RDS--------###
variable "restore_rds" {
  type        = bool
  description = "Should restore rds cluster be created"
  #default = false
}

/* variable "restore_DB_secretsName" {} */

variable "final_snapshot_identifier_restore" {
  default = ""
}
variable "instance_ips" {
  default = ""
}

variable "rds_SecretName" {
  default = ""
}


variable "restore_DB_secretsName" {
  default = ""
}
variable "OS_SecretName" {
  default = ""
}

variable "stream_name" {
  default = ""
}


variable "userCredSecretName" {
  default = ""
}

variable "creates_route53_records" {
  type    = bool
  default = true
}
variable "opensearch_public" {
  type    = bool
  default = true
}

variable "opensearchSubnetID" {
  default = []
}
variable "create_iam_service_linked_role_for_opensearch" {
  type        = bool
  default     = false
  description = "Whether to create `AWSServiceRoleForAmazonElasticsearchService` service-linked role. Set it to `false` if you already have an ElasticSearch cluster created in the AWS account and AWSServiceRoleForAmazonElasticsearchService already exists. See https://github.com/terraform-providers/terraform-provider-aws/issues/5218 for more info"
}
variable "loadBalancerType" {
  default = "internet-facing"
}


variable "recovery_window_in_days" {
  type    = number
  default = 0
}

variable "kms_key_arn" {
  #default = ""
}

variable "RetentionPeriod" {
  #default = 7 
}

variable "backup-name" {}

#variable "RadmVersion" {}

## Openseach ISM policy Variables #####
variable "policyid" {}
variable "HotState_MinSize" {}
variable "HotState_IndexAge" {}
variable "WarmState_IndexAge" {}
variable "index-patterns" {
  type = list(string)
}
variable "priority" {}
variable "update_policy" {}

variable "production" {}

##Cloudwatch alarm variables ####
variable "comparison_operator" {
  default = "GreaterThanThreshold"
}
variable "evaluation_periods" {
  default = "1"
}
variable "period" {
  default = "6000"
}
variable "statistic" {
  default = "Average"
}
variable "threshold" {
  default = ""
}
variable "istioVersion" {}
variable "minReplicaCount" {
  default = 2
}
variable "run_only_infra" {}
variable "ecr_aws_access_key_id" {}
variable "ecr_aws_secret_access_key" {}
variable "aws-ecr-endpoint" {}
variable "jfrog_user_name" {}
variable "jfrog_password" {}
variable "ecr_aws_irsa_role" {}
variable "tar-extract-path" {}
variable "registry_type" {}
variable "jfrog_endpoint" {}
variable "proxy_host" {}
variable "proxy_ip" {}
variable "proxy_port" {}
variable "no-proxy" {}
variable "irsa_role_enabled" {}
variable "kinesis-firehose" {}

variable "deploymentSize" {
  default = ""
}
variable "jfrog_insecure" {
  default = false
}
variable "external_logging_enabled" {
  default = false
}
variable "external_logging_endpoint" {
  default = ""
}
variable "external_logging_user_name" {
  default = ""
}
variable "external_logging_user_password" {
  default = ""
}
variable "external_metrics_enabled" {
  default = false
}

variable "blueprintVersion" {
  default = "v2"
}
variable "tsdb_backup_enabled" {
  default = false
}
variable "engine_api_blob_provider" {
  default = "s3"
}

variable "eaas_s3_sse_algorithm" {
  default = "AES256"
}
variable "registry_subpath" {
  default = "rafay"
}

variable "use_aws_secret_manager" {
  default = true
}

variable "iam_max_session_duration" {
  default = 43200
}

variable "tsdb_existing_s3_bucket_name" {
  default = ""
}

variable "existing_s3_backup_restore_bucketname" {
  default = ""
}

variable "existing_eaas_bucketname" {
  default = ""
}
