###----KINESIS VARIABLES-----####
variable "s3_bucket" {}
variable "kinesis_iam_role" {}
variable "kinesis_iam_policy" {}
variable "kinesis_es_policy" {}
variable "stream_name" {}
variable "cluster_name" {}
variable "destination" {}
variable "s3_buffer_size" {}
variable "s3_buffer_interval" {}
variable "s3_compression_format" {}
variable "s3_log_stream_name" {}
variable "es_arn" {}
variable "es_index_name" {}
variable "es_buffering_size" {}
variable "es_buffering_interval" {}
variable "s3_backup_mode" {}
variable "os_log_stream_name" {}
variable "region" {}
variable "account_id" {}
variable "default_tags" {}
variable "subnet_ids" {}
variable "vpc_id" {}
variable "opensearch_public" {}
variable "eks_cluster_name" {}
variable "domain" {}
variable "kms_key_arn" {}
variable "ingress_cidr_blocks" {}
variable "egress_cidr_blocks" {}

##
variable "s3_logsbucket" {}
variable "logsstream_name" {}
variable "es_logsindex_name" {}
variable "kinesislogs_iam_role" {}