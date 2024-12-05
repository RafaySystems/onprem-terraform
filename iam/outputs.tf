output "BackupRestore_role_arn" {
  value = aws_iam_role.BackupRestore_iam_role.*.arn
}

output "irsa_instance_iam_role_arn" {
  value = aws_iam_role.irsa_instance_iam_role.*.arn
}

output "ebs_csi_driver_arn" {
  value = aws_iam_role.ebs_iam_role.arn
}

output "BackupRestore_policy_arn" {
  value = aws_iam_policy.BackupRestore_policy.*.arn
}

output "IRSA_AMP_Policy" {
  value = aws_iam_policy.IRSA_AMP_Policy.arn
}
output "lb_controller_role_arn" {
  value = aws_iam_role.lb_controller_iam_role.arn
}
output "tsdb_backup_role_arn" {
  value = aws_iam_role.tsdb_iam_role.*.arn
}
output "eaas_irsa_role_arn" {
  value = aws_iam_role.eaas_iam_role.arn
}
