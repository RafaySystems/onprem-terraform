output "arn" {
  description = "Kineses Firehose Stream ARN"
  value       = var.opensearch_public ? aws_kinesis_firehose_delivery_stream.kinesis-firehose-public[0].arn : aws_kinesis_firehose_delivery_stream.kinesis-firehose-private[0].arn
}
output "kinesis_role_arn" {
  value = aws_iam_role.firehose_delivery_role.arn
}

output "kinesis_firehose_arn" {
  value = var.opensearch_public ? aws_kinesis_firehose_delivery_stream.kinesis-firehose-logspublic[0].arn : aws_kinesis_firehose_delivery_stream.kinesis-firehose-logs[0].arn
}

output "kinesis_logs_role_arn" {
  value = aws_iam_role.firehose_delivery_logs_role.arn
}
