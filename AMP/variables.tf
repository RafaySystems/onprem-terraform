variable "eks_cluster_name" {}
variable "region" {}
variable "default_tags" {}
variable "prometheus_workspace_alias" {}
variable "ingest_iam_role_name" {}
variable "ingest_iam_policy_name" {}
variable "query_iam_role_name" {}
variable "query_iam_policy_name" {}

##Cloud watch alarms variables
variable "controllername" {}
variable "comparison_operator" {}
variable "evaluation_periods" {}
variable "period" {}
variable "statistic" {}
variable "threshold" {}
variable "sns_arn" {}
variable "IRSA_AMP_Policy" {}
