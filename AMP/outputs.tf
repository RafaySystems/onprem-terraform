output "prometheus_workspace_id" {
  value = aws_prometheus_workspace.prod_eks_metrics.id
}

output "prometheus_workspace_arn" {
  value = aws_prometheus_workspace.prod_eks_metrics.arn
}

output "prometheus_workspace_endpoint" {
  value = aws_prometheus_workspace.prod_eks_metrics.prometheus_endpoint
}

output "amp_ingest_role_arn" {
  value = aws_iam_role.amp-iamproxy-ingest-role.arn
}

output "amp_query_role_arn" {
  value = aws_iam_role.amp-iamproxy-query-role.arn
}

