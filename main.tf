
# ------------------------------------------------------------##
# EKS
# ------------------------------------------------------------##
module "eks-cluster" {
  source                          = "./eks-cluster"
  cluster_name                    = var.controller_name
  eks_cluster_version             = var.eks_cluster_version
  eks_cluster_log_types           = var.eks_cluster_log_types
  retention_days                  = var.retention_days
  eks_endpoint_private_access     = var.eks_endpoint_private_access
  eks_endpoint_public_access      = var.eks_endpoint_public_access
  eks_endpoint_public_access_cidr = var.eks_endpoint_public_access_cidr
  ami_id                          = var.ami_id
  instance_type                   = var.production ? var.prod_instance_type : var.dev_instance_type
  volume_size                     = var.volume_size
  volume_type                     = var.volume_type
  desired_capacity                = var.desired_capacity
  max_size                        = var.max_size
  min_size                        = var.min_size
  device_name                     = var.device_name
  ec2_ssh_key                     = var.ec2_ssh_key
  launchtemp_update_version       = var.launchtemp_update_version
  resource_type                   = var.resource_type
  create_vpc                      = var.create_vpc
  vpc_id                          = var.vpc_id
  vpc_cidr                        = var.vpc_cidr
  additional_cidr_block           = var.additional_cidr_block
  azs                             = var.azs
  public_subnets_cidr             = var.public_subnets_cidr
  public_subnets_ids              = var.public_subnets_ids
  private_subnets_cidr            = var.private_subnets_cidr
  private_subnets_ids             = var.private_subnets_ids
  nodes_private_subnets_cidr      = var.worker_nodes_private_subnets_cidr
  nodes_private_subnets_ids       = var.worker_nodes_private_subnets_ids
  destination_cidr_block          = var.destination_cidr_block
  enable_dns_hostnames            = var.enable_dns_hostnames
  enable_dns_support              = var.enable_dns_support
  enable_nat_vpc                  = var.enable_nat_vpc
  region                          = var.region
  map_public_ip_on_launch         = var.map_public_ip_on_launch
  public_ip_privatesubnet         = var.public_ip_privatesubnet
  creates_cloudwatch_log_group    = var.creates_cloudwatch_log_group
  path                            = pathexpand("${var.path}")
  default_tags                    = var.additional_tags
  user_custom_commands            = var.user_custom_commands
  eks_iam_role_name               = "${var.controller_name}-Controlplane-role"
  eks_workernode_iam_role_name    = "${var.controller_name}-workernode-role"
  eks_cluster_node_group_name     = "${var.controller_name}-workernode"
  launchtemp_name                 = "${var.controller_name}-launchtemplates"
  vpc_name                        = "${var.controller_name}-VPC"
  # vpc_sg_name                     = var.vpc_sg_name
  eks-workernode-kms_customermanagedkey_policy = "${var.controller_name}-kms_policy"
  kms_key_arn                                  = var.kms_key_arn != "" ? var.kms_key_arn : module.kms[0].kms_key_arn
  capacity_type                                = var.capacity_type
  ebs_addon_name                               = var.ebs_addon_name
  ebs_addon_version                            = var.ebs_addon_version
  ebs_resolve_conflicts                        = var.ebs_resolve_conflicts
  ebs_arn                                      = module.iam.ebs_csi_driver_arn
  bottleRocket_os                              = var.bottleRocket_os
  ingress_cidr_blocks                          = var.ingress_cidr_blocks
  egress_cidr_blocks                           = var.egress_cidr_blocks
  eks_cluster_encryption                       = var.eks_cluster_encryption
  encryption_resources                         = var.encryption_resources
}

# ------------------------------------------------------------##
# EFS
# ------------------------------------------------------------##
module "efs" {
  source              = "./efs"
  cluster_name        = module.eks-cluster.cluster_id
  subnet_id           = var.create_vpc == true ? module.eks-cluster.private_subnets : var.private_subnets_ids
  vpc_id              = var.vpc_id != "" ? var.vpc_id : module.eks-cluster.vpc_id[0]
  default_tags        = var.additional_tags
  efs_role_name       = "${var.controller_name}-efs-ROLE"
  efs_policy_name     = "${var.controller_name}-efs-policy"
  creation_token      = "${var.controller_name}-EFS"
  kms_key_arn         = var.kms_key_arn != "" ? var.kms_key_arn : module.kms[0].kms_key_arn
  ingress_cidr_blocks = var.ingress_cidr_blocks
  egress_cidr_blocks  = var.egress_cidr_blocks
}

# ------------------------------------------------------------##
# IAM
# ------------------------------------------------------------##
module "iam" {
  source                                = "./iam"
  cluster_name                          = module.eks-cluster.cluster_id
  kms_key_arn                           = var.kms_key_arn != "" ? var.kms_key_arn : module.kms[0].kms_key_arn
  s3_backup_restore_bucketname          = var.existing_s3_backup_restore_bucketname != "" ? var.existing_s3_backup_restore_bucketname : "${var.controller_name}-s3-backup-restore-bucket"
  BackupRestore_role_name               = "${var.controller_name}-BackupRestore-role"
  BackupRestore_policy_name             = "${var.controller_name}-BackupRestore-policy"
  tsdb_backup_role_name                 = "${var.controller_name}-tsdb-backup-role"
  tsdb_backup_policy_name               = "${var.controller_name}-tsdb-backup-policy"
  s3_tsdb_backup_bucket                 = var.tsdb_existing_s3_bucket_name != "" ? var.tsdb_existing_s3_bucket_name : "${var.controller_name}-tsdb-backup-bucket"
  default_tags                          = var.additional_tags
  irsa_instance_iam_role_name           = "${var.controller_name}-cluster-irsa-role"
  irsa_AMP_policy_name                  = "${var.controller_name}-cluster-irsa-amp-polciy"
  use-instance-role                     = var.use_instance_role
  ebs_iam_role_name                     = "${var.controller_name}-ebs"
  kms_ebspolicy_name                    = "${var.controller_name}-kms"
  backup-restore                        = var.backup-restore
  backup_enabled                        = var.backup_enabled
  amp-enabled                           = var.amp-enabled
  eaas_bucketname                       = var.existing_eaas_bucketname != "" ? var.existing_eaas_bucketname : "${var.controller_name}-eaas-bucket"
  eaas_role_name                        = "${var.controller_name}-eaas-role"
  eaas_policy_name                      = "${var.controller_name}-eaas-policy"
  eaas_sse_algorithm                    = var.eaas_s3_sse_algorithm
  iam_max_session_duration              = var.iam_max_session_duration
  use_existing_s3_backup_restore_bucket = var.existing_s3_backup_restore_bucketname != "" ? true : false
  use_existing_s3_eaas_bucket           = var.existing_eaas_bucketname != "" ? true : false
  use_existing_s3_tsdb_bucket           = var.tsdb_existing_s3_bucket_name != "" ? true : false
}

# ------------------------------------------------------------##
# External DNS
# ------------------------------------------------------------##
module "external-dns" {
  source                   = "./external-dns"
  count                    = var.external-dns-enabled ? 1 : 0
  cluster_name             = module.eks-cluster.cluster_id
  external_dns_role_name   = "${var.controller_name}-DNS-role"
  external_dns_policy_name = "${var.controller_name}-DNS-policy"
  default_tags             = var.additional_tags
}

# ------------------------------------------------------------##
# CREATES IAM USER
# ------------------------------------------------------------##
module "iam_user" {
  source                  = "./iam_user"
  count                   = 0 #var.aws_access_key != "" ? 0 : 1
  sts_policy_name         = "${var.controller_name}-policy"
  iam_user_name           = "${var.controller_name}-user"
  User_credentials        = var.userCredSecretName
  path                    = pathexpand("${var.path}")
  cluster_name            = var.controller_name
  default_tags            = var.additional_tags
  recovery_window_in_days = var.recovery_window_in_days
}

# ------------------------------------------------------------##
# Create a new RDS
# ------------------------------------------------------------##
module "rds" {
  source                              = "./rds"
  count                               = var.existing_rds_host_address == "" && var.rds_engine == "postgres" ? 1 : 0
  cluster_name                        = var.controller_name
  vpc_id                              = var.vpc_id != "" ? var.vpc_id : module.eks-cluster.vpc_id[0]
  identifier                          = "${var.controller_name}-postgres"
  instance_class                      = var.production ? var.prod_instance_class : var.dev_instance_class
  allocated_storage                   = var.production ? var.prod_rds_allocated_storage : var.dev_rds_allocated_storage
  engine                              = var.rds_engine
  engine_version                      = var.rds_engine_version
  backup_retention_period             = var.rds_backup_retention_period
  username                            = var.rds_username
  subnet_id                           = var.rds_publicly_accessible ? (length(var.public_subnets_ids) != 0 ? var.public_subnets_ids : module.eks-cluster.public_subnets) : (length(var.private_subnets_ids) != 0 ? var.private_subnets_ids : module.eks-cluster.private_subnets)
  vpc_cidr                            = var.vpc_cidr
  db_name                             = var.rds_db_name
  subnet_name                         = "${var.controller_name}-dbsubnet"
  multi_az                            = var.rds_multi_az
  storage_encrypted                   = var.rds_storage_encrypted
  iam_database_authentication_enabled = var.rds_iam_database_authentication_enabled
  publicly_accessible                 = var.rds_publicly_accessible
  skip_final_snapshot                 = var.rds_skip_final_snapshot
  final_snapshot_identifier           = var.final_snapshot_identifier
  parameter_name                      = var.rds_parameter_name
  default_tags                        = var.additional_tags
  instance_ips                        = var.instance_ips
  rds_SecretName                      = var.rds_SecretName
  recovery_window_in_days             = var.recovery_window_in_days
  db_major_version_upgrade            = var.db_major_version_upgrade
  db_minor_version_upgrade            = var.db_minor_version_upgrade
  controllername                      = var.controller_name
  comparison_operator                 = var.comparison_operator
  evaluation_periods                  = var.evaluation_periods
  period                              = var.period
  statistic                           = var.statistic
  threshold                           = var.threshold
  sns_arn                             = module.sns.sns_topic_arn
  apply_immediately                   = var.apply_immediately
  ingress_cidr_blocks                 = var.ingress_cidr_blocks
  egress_cidr_blocks                  = var.egress_cidr_blocks
  use_aws_secret_manager              = var.use_aws_secret_manager
  kms_key_id                          = var.kms_key_arn != "" ? var.kms_key_arn : module.kms[0].kms_key_arn
  region                              = var.region
  replication_db                      = var.replication_source_db
}

# ------------------------------------------------------------##
# Create a new RDS postgres aurora
# ------------------------------------------------------------##
module "rds_aurora" {
  source                       = "./rds_aurora"
  count                        = var.existing_rds_host_address == "" && var.rds_engine == "aurora-postgresql" ? 1 : 0
  cluster_name                 = var.controller_name
  vpc_id                       = var.vpc_id != "" ? var.vpc_id : module.eks-cluster.vpc_id[0]
  identifier                   = "${var.controller_name}-postgres"
  instance_class               = var.production ? var.prod_instance_class : var.dev_instance_class
  engine                       = var.rds_engine
  engine_version               = var.rds_engine_version
  backup_retention_period      = var.rds_backup_retention_period
  username                     = var.rds_username
  subnet_id                    = var.rds_publicly_accessible ? (length(var.public_subnets_ids) != 0 ? var.public_subnets_ids : module.eks-cluster.public_subnets) : (length(var.private_subnets_ids) != 0 ? var.private_subnets_ids : module.eks-cluster.private_subnets)
  vpc_cidr                     = var.vpc_cidr
  db_name                      = var.rds_db_name
  subnet_name                  = "${var.controller_name}-dbsubnet"
  storage_encrypted            = var.rds_storage_encrypted
  publicly_accessible          = var.rds_publicly_accessible
  skip_final_snapshot          = var.rds_skip_final_snapshot
  final_snapshot_identifier    = var.final_snapshot_identifier
  default_tags                 = var.additional_tags
  instance_ips                 = var.instance_ips
  rds_SecretName               = var.rds_SecretName
  recovery_window_in_days      = var.recovery_window_in_days
  db_major_version_upgrade     = var.db_major_version_upgrade
  db_minor_version_upgrade     = var.db_minor_version_upgrade
  controllername               = var.controller_name
  apply_immediately            = var.apply_immediately
  ingress_cidr_blocks          = var.ingress_cidr_blocks
  egress_cidr_blocks           = var.egress_cidr_blocks
  num_cluster_instances        = var.num_cluster_instances
  copy_tags_to_snapshot        = var.copy_tags_to_snapshot
  deletion_protection          = var.deletion_protection
  performance_insights_enabled = var.performance_insights_enabled
  use_aws_secret_manager       = var.use_aws_secret_manager
}

# ------------------------------------------------------------
# RESTROE RDS
# ------------------------------------------------------------
module "restore_rds" {
  source                    = "./restore_rds"
  count                     = var.restore_rds ? 1 : 0
  cluster_name              = var.controller_name
  vpc_id                    = var.vpc_id != "" ? var.vpc_id : module.eks-cluster.vpc_id[0]
  db_instance_identifier_id = var.existing_rds_host_address
  db_snapshot_identifier    = var.final_snapshot_identifier
  #identifier                          = var.rds_identifier
  instance_class          = var.production ? var.prod_instance_class : var.dev_instance_class
  allocated_storage       = var.production ? var.prod_rds_allocated_storage : var.dev_rds_allocated_storage
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  backup_retention_period = var.rds_backup_retention_period
  username                = var.rds_username
  # rds_password                        = var.rds_password
  db_name = var.rds_db_name
  #subnet_name                         = var.rds_subnet_name

  subnet_id                 = var.rds_publicly_accessible ? (length(var.public_subnets_ids) != 0 ? var.public_subnets_ids : module.eks-cluster.public_subnets) : (length(var.private_subnets_ids) != 0 ? var.private_subnets_ids : module.eks-cluster.private_subnets)
  multi_az                  = var.rds_multi_az
  storage_encrypted         = var.rds_storage_encrypted
  publicly_accessible       = true
  skip_final_snapshot       = var.rds_skip_final_snapshot
  default_tags              = var.additional_tags
  instance_ips              = var.instance_ips
  final_snapshot_identifier = var.final_snapshot_identifier_restore
  secretsName               = var.restore_DB_secretsName
  recovery_window_in_days   = var.recovery_window_in_days
  ingress_cidr_blocks       = var.ingress_cidr_blocks
  egress_cidr_blocks        = var.egress_cidr_blocks
}

# ------------------------------------------------------------##
# AMAZON MANAGED PROMETHEUS
# ------------------------------------------------------------##
module "AMP" {
  source                     = "./AMP"
  count                      = var.amp-enabled ? 1 : 0
  eks_cluster_name           = module.eks-cluster.cluster_id
  region                     = var.region
  default_tags               = var.additional_tags
  ingest_iam_role_name       = "${var.controller_name}-PrometheusIngest-role"
  ingest_iam_policy_name     = "${var.controller_name}-PrometheusIngest-polciy"
  query_iam_role_name        = "${var.controller_name}-PrometheusIQuery-role"
  query_iam_policy_name      = "${var.controller_name}-PrometheusQuery-policy"
  prometheus_workspace_alias = "${var.controller_name}-PrometheusMetrics"
  controllername             = var.controller_name
  comparison_operator        = var.comparison_operator
  evaluation_periods         = var.evaluation_periods
  period                     = var.period
  statistic                  = var.statistic
  threshold                  = var.threshold
  sns_arn                    = module.sns.sns_topic_arn
  IRSA_AMP_Policy            = module.iam.IRSA_AMP_Policy
}

# ------------------------------------------------------------##
# AMAZON MANAGED GRAFANA
# ------------------------------------------------------------##
module "AMG" {
  source                                     = "./AMG"
  count                                      = var.amp-enabled ? 1 : 0
  grafana_workspace_name                     = "${var.controller_name}-grafana"
  grafana_workspace_data_sources             = var.grafana_workspace_data_sources
  grafana_workspace_permission_type          = var.grafana_workspace_permission_type
  grafana_workspace_authentication_providers = var.grafana_workspace_authentication_providers
  grafana_workspace_account_access_type      = var.grafana_workspace_account_access_type
  default_tags                               = var.additional_tags

}

# ------------------------------------------------------------##
# Simple Notification Service
# ------------------------------------------------------------##
module "sns" {
  source       = "./sns"
  cluster_name = var.controller_name
  protocol     = var.protocol
  email_lists  = var.notifications-email
  default_tags = var.additional_tags
}

# ------------------------------------------------------------##
# KARPENTER
# ------------------------------------------------------------##
module "karpenter" {
  source           = "./karpenter"
  count            = var.karpenter-enabled ? 1 : 0
  cluster_name     = module.eks-cluster.cluster_id
  iam_role_name    = module.eks-cluster.worker_iam_role_name
  provider_url     = module.eks-cluster.oidc_provider
  cluster_endpoint = module.eks-cluster.cluster_endpoint
  karpenter_role   = "${var.controller_name}-KarepnterRole"
  default_tags     = var.additional_tags
}

# ------------------------------------------------------------
# OPENSEARCH DOMAIN
# ------------------------------------------------------------
module "opensearch_domain" {
  source                                        = "./opensearch"
  count                                         = var.opensearchEnabled ? 1 : 0
  opensearch_version                            = var.opensearch_version
  domain                                        = var.os_domain
  instance_type                                 = var.production ? var.prod_os_instance_type : var.dev_os_instance_type
  instance_count                                = var.production ? var.prod_os_instance_count : var.dev_os_instance_count
  zone_awareness_enabled                        = var.production ? var.prod_os_zone_awareness_enabled : var.dev_os_zone_awareness_enabled
  ebs_enabled                                   = var.os_ebs_enabled
  volume_type                                   = var.os_volume_type
  ebs_volume_size                               = var.production ? var.prod_os_ebs_volume_size : var.dev_os_ebs_volume_size
  encrypt_at_rest                               = var.os_encrypt_at_rest
  node_to_node_encryption                       = var.os_node_to_node_encryption
  tls_security_policy                           = var.os_tls_security_policy
  os_enforce_https                              = var.os_enforce_https
  advanced_sg_enabled                           = var.os_advanced_sg_enabled
  internal_user_database_enabled                = var.os_internal_user_database_enabled
  os_master_user_name                           = var.os_master_user_name
  availability_zone_count                       = length(var.azs)
  default_tags                                  = var.additional_tags
  create_iam_service_linked_role_for_opensearch = var.create_iam_service_linked_role_for_opensearch
  subnet_ids                                    = var.opensearch_public ? (length(var.public_subnets_ids) != 0 ? var.public_subnets_ids : module.eks-cluster.public_subnets) : (length(var.private_subnets_ids) != 0 ? var.private_subnets_ids : module.eks-cluster.private_subnets)
  /* subnet_ids = var.opensearch_public ? ((var.create_vpc ? [for subnetID in module.eks-cluster.public_subnets : subnetID if subnetID != ""] : [for subnetID in var.public_subnets_ids : subnetID if subnetID != ""] )) : ((var.create_vpc ? [for subnetID in module.eks-cluster.private_subnets : subnetID if subnetID != ""] : [for subnetID in var.private_subnets_ids : subnetID if subnetID != ""] )) */
  vpc_id                        = var.vpc_id != "" ? var.vpc_id : module.eks-cluster.vpc_id[0]
  opensearch_public             = var.opensearch_public
  kinesis_arn                   = var.kinesis-firehose ? module.kinesis-firehose[0].arn : ""
  ingress_cidr_blocks           = var.ingress_cidr_blocks
  egress_cidr_blocks            = var.egress_cidr_blocks
  controllername                = var.controller_name
  comparison_operator           = var.comparison_operator
  evaluation_periods            = var.evaluation_periods
  period                        = var.period
  statistic                     = var.statistic
  threshold                     = var.threshold
  sns_arn                       = module.sns.sns_topic_arn
  update_policy                 = var.update_policy
  seq_no                        = data.local_file.seq_no[0].content
  primary_term                  = data.local_file.primary_term[0].content
  HotState_MinSize              = var.HotState_MinSize
  HotState_IndexAge             = var.HotState_IndexAge
  WarmState_IndexAge            = var.WarmState_IndexAge
  index-patterns                = var.index-patterns
  priority                      = var.priority
  policyid                      = var.policyid
  auto_tune_desired_state       = var.os_auto_tune_desired_state
  auto_tune_rollback_on_disable = var.os_auto_tune_rollback_on_disable
  use_aws_secret_manager        = var.use_aws_secret_manager
  OS_SecretName                 = var.OS_SecretName
  recovery_window_in_days       = var.recovery_window_in_days
  #os_master_user_password       = var.use_aws_secret_manager != true ? (module.radm_application.super_password) : (var.superuser_secret_arn != "" ? one(data.external.superuser_secrets.*.result.password) : (module.radm_application.super_password))
}


# ------------------------------------------------------------ ##
# Kinesis Firehose
# ------------------------------------------------------------ ##
data "aws_caller_identity" "this" {}

module "kinesis-firehose" {
  source                = "./kinesis-firehose"
  count                 = var.kinesis-firehose ? 1 : 0
  cluster_name          = var.controller_name
  es_arn                = var.opensearchEnabled ? module.opensearch_domain[0].arn : ""
  destination           = var.destination
  account_id            = data.aws_caller_identity.this.account_id
  region                = var.region
  s3_buffer_size        = var.s3_buffer_size
  s3_buffer_interval    = var.s3_buffer_interval
  s3_compression_format = var.s3_compression_format
  es_index_name         = var.es_index_name
  es_buffering_size     = var.es_buffering_size
  es_buffering_interval = var.es_buffering_interval
  s3_backup_mode        = var.s3_backup_mode
  os_log_stream_name    = var.os_log_stream_name
  s3_log_stream_name    = var.s3_log_stream_name
  default_tags          = var.additional_tags
  stream_name           = var.stream_name
  s3_bucket             = "${var.controller_name}-kinesisbucket"
  kinesis_iam_role      = "${var.controller_name}-KinesisRole"
  kinesis_iam_policy    = "${var.controller_name}-KinesisPolicy"
  kinesis_es_policy     = "${var.controller_name}-KinesisOpenSearch-Policy"
  subnet_ids            = var.opensearch_public ? (length(var.public_subnets_ids) != 0 ? var.public_subnets_ids : module.eks-cluster.public_subnets) : (length(var.private_subnets_ids) != 0 ? var.private_subnets_ids : module.eks-cluster.private_subnets)
  /* subnet_ids = var.opensearch_public ? ((var.create_vpc ? [for subnetID in module.eks-cluster.public_subnets : subnetID if subnetID != ""] : [for subnetID in var.public_subnets_ids : subnetID if subnetID != ""] )) : ((var.create_vpc ? [for subnetID in module.eks-cluster.private_subnets : subnetID if subnetID != ""] : [for subnetID in var.private_subnets_ids : subnetID if subnetID != ""] )) */
  vpc_id               = var.vpc_id != "" ? var.vpc_id : module.eks-cluster.vpc_id[0]
  opensearch_public    = var.opensearch_public
  eks_cluster_name     = module.eks-cluster.cluster_id
  domain               = var.os_domain
  kms_key_arn          = var.kms_key_arn != "" ? var.kms_key_arn : module.kms[0].kms_key_arn
  s3_logsbucket        = "${var.controller_name}-kinesislogsbucket"
  logsstream_name      = var.logsstream_name
  es_logsindex_name    = var.es_logsindex_name
  kinesislogs_iam_role = "${var.controller_name}-kinesislogs-role"
  ingress_cidr_blocks  = var.ingress_cidr_blocks
  egress_cidr_blocks   = var.egress_cidr_blocks
}

# -----------------------------------------------------------##
# RUNNING RADM APPLICATION
# ----------------------------------------------------------##

# Importing the AWS secrets created for database previously using arn.

data "aws_secretsmanager_secret" "postgresDBPwd" {
  count = var.dbsecret_arn != "" ? 1 : 0
  arn   = var.dbsecret_arn
}

# Importing the AWS secret version created previously using arn.

data "aws_secretsmanager_secret_version" "creds" {
  depends_on = [
    data.aws_secretsmanager_secret.postgresDBPwd
  ]
  count     = var.dbsecret_arn != "" ? 1 : 0
  secret_id = one(data.aws_secretsmanager_secret.postgresDBPwd.*.id)
}

data "external" "db_secrets" {
  depends_on = [
    data.aws_secretsmanager_secret.postgresDBPwd
  ]
  count   = var.dbsecret_arn != "" ? 1 : 0
  program = ["echo", "${one(data.aws_secretsmanager_secret_version.creds.*.secret_string)}"]
}

# Importing the AWS secrets created for super user previously using arn.

data "aws_secretsmanager_secret" "superuserPwd" {
  count = var.superuser_secret_arn != "" ? 1 : 0
  arn   = var.superuser_secret_arn
}

# Importing the AWS secret version created previously using arn.

data "aws_secretsmanager_secret_version" "superuser_creds" {
  count     = var.superuser_secret_arn != "" ? 1 : 0
  secret_id = one(data.aws_secretsmanager_secret.superuserPwd.*.id)
}

data "external" "superuser_secrets" {
  count   = var.superuser_secret_arn != "" ? 1 : 0
  program = ["echo", "${one(data.aws_secretsmanager_secret_version.superuser_creds.*.secret_string)}"]
}

resource "random_password" "password" {
  length      = 8
  special     = false
  min_lower   = 1
  min_special = 1
  min_numeric = 1
  min_upper   = 1
}

module "radm_application" {
  source                           = "./radm_application"
  deploymentType                   = var.deploymentType
  rds_hostname                     = var.existing_rds_host_address == "" ? (var.rds_engine == "postgres" ? one(module.rds.*.rds_hostname) : one(module.rds_aurora.*.rds_aurora_endpoint)) : ("${var.existing_rds_host_address}")
  rds_port                         = 5432
  rds_username                     = var.existing_rds_host_address == "" ? (var.rds_engine == "postgres" ? one(module.rds.*.rds_username) : one(module.rds_aurora.*.rds_aurora_username)) : (var.dbsecret_arn != "" ? one(data.external.db_secrets.*.result.username) : "")
  domain_name                      = var.domain_name
  rds_password                     = var.existing_rds_host_address == "" ? (var.rds_engine == "postgres" ? one(module.rds.*.rds_password) : one(module.rds_aurora.*.rds_aurora_password)) : (var.dbsecret_arn != "" ? one(data.external.db_secrets.*.result.password) : "")
  cluster_id                       = module.eks-cluster.cluster_id
  region                           = var.region
  path                             = pathexpand("${var.path}")
  controllerRepoUrl                = var.production ? var.prod_controllerRepoUrl : var.dev_controllerRepoUrl
  controllerVersion                = var.controllerVersion
  logo_path                        = pathexpand("${var.logo_path}")
  cluster_name                     = var.controller_name
  cluster_endpoint                 = module.eks-cluster.cluster_endpoint
  cert_acm                         = var.cert_acm
  aws_efs_fs_id                    = module.efs.aws_efs_fs_id
  efs_iam_role_arn                 = module.efs.iam_role_arn
  super_user                       = var.super_user
  super_user_password              = var.use_aws_secret_manager != true ? (module.radm_application.super_password) : (var.superuser_secret_arn != "" ? one(data.external.superuser_secrets.*.result.password) : (module.radm_application.super_password))
  super_user_SecretName            = var.super_user_SecretName
  enable_hosted_dns_server         = var.enable_hosted_dns_server
  external_lb                      = var.external_lb
  use_instance_role                = var.use_instance_role
  aws_account_id                   = data.aws_caller_identity.this.account_id
  aws_access_key_id                = var.aws_access_key #== "" ? base64encode(one(module.iam_user.*.access_key)) : var.aws_access_key
  aws_secret_access_key            = var.aws_secret_key #== "" ? base64encode(one(module.iam_user.*.secret_key)) : var.aws_secret_key
  kapenter_role_arn                = var.karpenter-enabled ? module.karpenter[0].karepnter_role_arn : ""
  amp_ingest_role_arn              = var.amp-enabled ? module.AMP[0].amp_ingest_role_arn : ""
  amp_query_role_arn               = var.amp-enabled ? module.AMP[0].amp_query_role_arn : ""
  amp_workspace_id                 = var.amp-enabled ? module.AMP[0].prometheus_workspace_id : ""
  controllerName                   = var.controllerName
  console-certificate              = var.console-certificate
  console-key                      = var.console-key
  partner_name                     = var.partner_name
  product_name                     = var.product_name
  help-desk-email                  = var.help-desk-email
  notifications-email              = var.notifications-email
  external-database                = var.external-database
  amp-enabled                      = var.amp-enabled
  generate-self-signed-certs       = var.generate-self-signed-certs
  karpenter-enabled                = var.karpenter-enabled
  external-dns-enabled             = var.external-dns-enabled
  externalDnsHostedZoneID          = var.zone_id
  external-dns-role_arn            = var.external-dns-enabled ? module.external-dns[0].external-dns-role-name : 0
  loadBalancerType                 = var.loadBalancerType
  backup-restore-enabled           = var.backup_enabled
  backup-restore-role_arn          = var.backup_enabled ? module.iam.BackupRestore_role_arn[0] : ""
  backup-restoreSchedule           = var.backup-restoreSchedule
  backup-restore-bucket_name       = var.existing_s3_backup_restore_bucketname != "" ? var.existing_s3_backup_restore_bucketname : "${var.controller_name}-s3-backup-restore-bucket"
  tsdb_backup_bucket               = var.tsdb_existing_s3_bucket_name != "" ? var.tsdb_existing_s3_bucket_name : "${var.controller_name}-tsdb-backup-bucket"
  tsdb_backup_role_arn             = var.amp-enabled ? "" : module.iam.tsdb_backup_role_arn[0]
  lb_controller_role_arn           = module.iam.lb_controller_role_arn
  lb_controller_clusterName        = module.eks-cluster.cluster_id
  backup-restore                   = var.backup-restore
  kinesis-firehose-delivery-stream = var.stream_name
  kinesis-firehose-role-arn        = var.amp-enabled ? module.kinesis-firehose[0].kinesis_role_arn : ""
  opensearchEnabled                = var.opensearchEnabled
  opensearch-endpoint              = var.opensearchEnabled ? module.opensearch_domain[0].endpoint : ""
  opensearch-user-name             = var.os_master_user_name
  opensearch-user-password         = var.opensearchEnabled ? module.opensearch_domain[0].opensearch_password : ""
  ami                              = var.ami_id
  ec2_instance_type                = var.ec2_instance_type
  public-ip                        = var.public-ip
  /* subnet_id                        = length(var.private_subnets_ids) != 0 ? var.private_subnets_ids : module.eks-cluster.private_subnets */
  subnet_id                     = var.publicLoadBalancer == "true" ? (length(var.public_subnets_ids) != 0 ? var.public_subnets_ids : module.eks-cluster.public_subnets) : (length(var.private_subnets_ids) != 0 ? var.private_subnets_ids : module.eks-cluster.private_subnets)
  vpc_id                        = var.vpc_id != "" ? var.vpc_id : module.eks-cluster.vpc_id[0]
  key_name                      = var.ec2_ssh_key
  delete_on_termination         = var.delete_on_termination
  volume_size                   = var.volume_size
  volume_type                   = var.volume_type
  default_tags                  = var.additional_tags
  aws_access_key                = var.aws_access_key #== "" ? base64encode(one(module.iam_user.*.access_key)) : var.aws_access_key
  aws_secret_key                = var.aws_secret_key #== "" ? base64encode(one(module.iam_user.*.secret_key)) : var.aws_secret_key
  minReplicaCount               = var.minReplicaCount
  irsa_instance_iam_role_arn    = var.use_instance_role ? module.iam.irsa_instance_iam_role_arn[0] : ""
  recovery_window_in_days       = var.recovery_window_in_days
  logsstream_name               = var.logsstream_name
  kinesis_firehose_logsrole_arn = var.kinesis-firehose ? module.kinesis-firehose[0].kinesis_logs_role_arn : ""
  RetentionPeriod               = var.RetentionPeriod
  BackupFolderName              = var.backup-name
  #RadmVersion                   = var.RadmVersion
  istioVersion                   = var.istioVersion
  run_only_infra                 = var.run_only_infra
  ecr_aws_access_key_id          = var.ecr_aws_access_key_id
  ecr_aws_secret_access_key      = var.ecr_aws_secret_access_key
  aws-ecr-endpoint               = var.aws-ecr-endpoint
  jfrog_user_name                = var.jfrog_user_name
  jfrog_password                 = var.jfrog_password
  ecr_aws_irsa_role              = var.ecr_aws_irsa_role
  tar-extract-path               = var.tar-extract-path
  jfrog_endpoint                 = var.jfrog_endpoint
  proxy_host                     = var.proxy_host
  proxy_ip                       = var.proxy_ip
  proxy_port                     = var.proxy_port
  no-proxy                       = var.no-proxy
  irsa_role_enabled              = var.irsa_role_enabled
  deploymentSize                 = var.deploymentSize
  external_logging_enabled       = var.external_logging_enabled
  external_logging_endpoint      = var.external_logging_endpoint
  external_logging_user_name     = var.external_logging_user_name
  external_logging_user_password = var.external_logging_user_password
  external_metrics_enabled       = var.external_metrics_enabled
  jfrog_insecure                 = var.jfrog_insecure
  blueprintVersion               = var.blueprintVersion
  rafay_registry_type            = var.registry_type
  tsdb_backup_enabled            = var.tsdb_backup_enabled
  engine_api_blob_provider       = var.engine_api_blob_provider
  engine_api_blob_bucket         = var.existing_eaas_bucketname != "" ? var.existing_eaas_bucketname : "${var.controller_name}-eaas-bucket"
  engine_api_irsa_role_arn       = module.iam.eaas_irsa_role_arn
  registry_subpath               = var.registry_subpath
  use_aws_secret_manager         = var.use_aws_secret_manager
  resticEnable                   = var.backup_resticEnable
}

# ------------------------------------------------------------
# ROUTE 53
# ------------------------------------------------------------
module "route_53" {
  source               = "./route_53"
  count                = var.creates_route53_records ? 1 : 0
  domain_name          = var.domain_name
  vpc_id               = var.vpc_id != "" ? var.vpc_id : module.eks-cluster.vpc_id[0]
  creates_route53_zone = var.creates_route53_zone
  allow_overwrite      = var.allow_overwrite
  record_name_ui       = var.record_name_ui
  record_ttl           = var.record_ttl
  record_type          = var.record_type
  zone_id              = var.zone_id
  record_name_backend  = var.record_name_backend
  default_tags         = var.additional_tags
  external_lb          = var.external_lb
}


# -----------------------------------------------------------
# KMS
# -----------------------------------------------------------
module "kms" {
  source         = "./kms"
  count          = var.kms_key_arn != "" ? 0 : 1
  kms_key_period = var.kms_key_period
  default_tags   = var.additional_tags
}

### ----------------------------------------------------------
#  Creates ISM Policy managed Indices in Opensearch
### ----------------------------------------------------------
resource "null_resource" "creates_ism_policy" {
  count = var.opensearchEnabled ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
         curl  -XPUT -u '${var.os_master_user_name}:${(module.opensearch_domain[0].opensearch_password)}' 'https://${module.opensearch_domain[0].endpoint}/_opendistro/_ism/policies/${var.policyid}' -k -H 'Content-Type: application/json' -d '{"policy":{"policy_id":"${var.policyid}","description":"hot-delete workflow policy to delete indices based on size and age.","default_state":"hot","states":[{"name":"hot","actions":[],"transitions":[{"state_name":"warm","conditions":{"min_size":"${var.HotState_MinSize}"}},{"state_name":"warm","conditions":{"min_index_age":"${var.HotState_IndexAge}"}}]},{"name":"warm","actions":[],"transitions":[{"state_name":"delete","conditions":{"min_index_age":"${var.WarmState_IndexAge}"}}]},{"name":"delete","actions":[{"delete":{}}],"transitions":[]}],"ism_template":[{"index_patterns":${jsonencode(var.index-patterns)},"priority":${var.priority}}]}}'
    EOT
  }
}

resource "null_resource" "to-get-seqno" {
  count = var.opensearchEnabled ? 1 : 0
  depends_on = [
    null_resource.creates_ism_policy
  ]
  triggers = {
    id  = var.HotState_MinSize,
    age = var.HotState_IndexAge
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        curl -XGET -u '${var.os_master_user_name}:${(module.opensearch_domain[0].opensearch_password)}' "https://${module.opensearch_domain[0].endpoint}/_opendistro/_ism/policies/${var.policyid}" | awk -F "," '{print $3}'  | cut -d ":" -f2 > seqno.txt
    EOT
  }
}

resource "null_resource" "to-get-primaryterm" {
  count = var.opensearchEnabled ? 1 : 0
  depends_on = [
    null_resource.creates_ism_policy
  ]
  triggers = {
    id  = var.HotState_MinSize,
    age = var.HotState_IndexAge
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
          curl -XGET -u '${var.os_master_user_name}:${(module.opensearch_domain[0].opensearch_password)}' "https://${module.opensearch_domain[0].endpoint}/_opendistro/_ism/policies/${var.policyid}" | awk -F "," '{print $4}'  | cut -d ":" -f2 > primaryterm.txt
      EOT
  }
}

data "local_file" "seq_no" {
  count = var.opensearchEnabled ? 1 : 0
  depends_on = [
    null_resource.to-get-seqno
  ]
  filename = "${path.module}/seqno.txt"
}

data "local_file" "primary_term" {
  count = var.opensearchEnabled ? 1 : 0
  depends_on = [
    null_resource.to-get-primaryterm
  ]
  filename = "${path.module}/primaryterm.txt"
}
