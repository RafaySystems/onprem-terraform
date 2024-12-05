###---------EKS CLUSTER OUTPUTS--------###
output "cluster_id" {
  value = module.eks-cluster.cluster_id
}

output "cluster_endpoint" {
  value = module.eks-cluster.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks-cluster.cluster_certificate_authority_data
}

output "kubectl_config" {
  value     = module.eks-cluster.kubectl_config
  sensitive = true
}

output "config_map_aws_auth" {
  value     = module.eks-cluster.config_map_aws_auth
  sensitive = true
}

output "cluster_name" {
  value = module.eks-cluster.cluster_name
}

output "oidc_provider" {
  value = module.eks-cluster.oidc_provider
}

output "oidc_provider_arn" {
  value = module.eks-cluster.oidc_provider_arn
}

output "cluster_iam_role_name" {
  value = module.eks-cluster.cluster_iam_role_name
}

#output "eks_node_group_ASG_name" {
#	value = values(element(lookup(module.eks-cluster.node_group_info[0], "autoscaling_groups"), 0))
#}
#output "instanceID" {
#	value = module.eks-cluster.instance_ID
#}
output "cluster_iam_role_arn" {
  value = module.eks-cluster.cluster_iam_role_arn
}

output "worker_iam_role_name" {
  value = module.eks-cluster.worker_iam_role_name
}

output "worker_iam_role_arn" {
  value = module.eks-cluster.worker_iam_role_arn
}

###-------VPC OUTPUTS------------###
output "vpc_id" {
  value = module.eks-cluster.vpc_id
}

output "private_subnets" {
  value = module.eks-cluster.private_subnets
}

output "nodes_private_subnets" {
  value = module.eks-cluster.nodes_private_subnets
}

output "security_groups" {
  value = module.eks-cluster.security_groups
}

###--------RDS OUTPUTS------------####
# #output "rds_hostname" {
#   value = module.rds.rds_hostname
# }

# output "rds_port" {
#   value = module.rds.rds_port
# }

###--------AMP OUTPUTS------###
#output "prometheus_workspace_id" {
#  value = module.AMP.prometheus_workspace_id
#}
###--------AMG OUTPUTS------###
#output "grafana_workspace_endpoint" {
#  value = module.AMG.grafana_workspace_endpoint
#}
#output "grafana_workspace_arn" {
#  value = module.AMG.grafana_workspace_arn
#}

###----------KARPENTER OUTPUTS-----####
#output "karepnter_role_arn" {
#  value = module.karpenter.karepnter_role_arn
#}

###-------OPENSEARCH OUTPUTS-----####
#output "os_arn" {
#  description = "Amazon Resource Name (ARN) of the domain"
#  value       = module.opensearch_domain.arn
#}

#output "os_domain_id" {
#  description = "Unique identifier for the domain."
#  value       = module.opensearch_domain.domain_id
#}
#output "os_endpoint" {
#  description = "Domain-specific endpoint used to submit index, search, and data upload requests."
#  value       = module.opensearch_domain.endpoint
#}

#output "os_kibana_endpoint" {
#  description = "Domain-specific endpoint for kibana without https scheme."
#  value       = module.opensearch_domain.kibana_endpoint
#}

####------KINESIS OUTPUTS----###
#output "kinesis_arn" {
#  description = "Kineses Firehose Stream ARN"
#  value       = module.kinesis-firehose.arn
#}
#output "kinesis_role_arn" {
#  value = module.kinesis-firehose.kinesis_role_arn
#}
