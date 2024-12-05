output "arn" {
  value = var.opensearch_public ? aws_opensearch_domain.opensearch_public[0].arn : aws_opensearch_domain.opensearch_private[0].arn
}
output "domain_id" {
  value = var.opensearch_public ? aws_opensearch_domain.opensearch_public[0].domain_id : aws_opensearch_domain.opensearch_private[0].domain_id
}
output "domain_name" {
  value = var.opensearch_public ? aws_opensearch_domain.opensearch_public[0].domain_name : aws_opensearch_domain.opensearch_private[0].domain_name
}
output "endpoint" {
  value = var.opensearch_public ? aws_opensearch_domain.opensearch_public[0].endpoint : aws_opensearch_domain.opensearch_private[0].endpoint
}
output "kibana_endpoint" {
  value = var.opensearch_public ? aws_opensearch_domain.opensearch_public[0].kibana_endpoint : aws_opensearch_domain.opensearch_private[0].kibana_endpoint
}