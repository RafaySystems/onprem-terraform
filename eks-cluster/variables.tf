###-----EKS CLUSTER VARIABLES----##
variable "cluster_name" {}
variable "eks_cluster_version" {}
variable "eks_cluster_log_types" {}
variable "retention_days" {}
variable "eks_endpoint_private_access" {}
variable "eks_endpoint_public_access" {}
variable "eks_endpoint_public_access_cidr" {}
variable "instance_type" {}
variable "ami_id" {}
variable "desired_capacity" {}
variable "max_size" {}
variable "min_size" {}
variable "device_name" {}
variable "volume_size" {}
variable "volume_type" {}
variable "ec2_ssh_key" {}
variable "creates_cloudwatch_log_group" {}
variable "launchtemp_update_version" {}
variable "resource_type" {}
variable "default_tags" {}
variable "user_custom_commands" {}
variable "path" {}
variable "eks_iam_role_name" {}
variable "eks_cluster_node_group_name" {}
variable "eks_workernode_iam_role_name" {}
variable "launchtemp_name" {}
variable "capacity_type" {}
variable "ebs_addon_name" {}
variable "ebs_addon_version" {}
variable "ebs_resolve_conflicts" {}
variable "ebs_arn" {}
variable "bottleRocket_os" {}
variable "ingress_cidr_blocks" {}
variable "egress_cidr_blocks" {}

variable "eks_cluster_encryption" {}
variable "encryption_resources" {}

###-----VPC VARIABLES-----####
variable "create_vpc" {}
variable "vpc_id" {}
variable "vpc_cidr" {}
variable "additional_cidr_block" {}
variable "azs" {}
variable "region" {}
variable "public_subnets_cidr" {}
variable "private_subnets_cidr" {}
variable "public_subnets_ids" {}
variable "private_subnets_ids" {}
variable "nodes_private_subnets_cidr" {}
variable "destination_cidr_block" {}
variable "enable_dns_support" {}
variable "enable_dns_hostnames" {}
variable "enable_nat_vpc" {}
variable "map_public_ip_on_launch" {}
variable "nodes_private_subnets_ids" {}
variable "public_ip_privatesubnet" {}
# variable "vpc_sg_name" {}
variable "vpc_name" {}
variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "eks-workernode-kms_customermanagedkey_policy" {}
variable "kms_key_arn" {}
