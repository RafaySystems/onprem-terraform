output "iam_role_arn" {
  value = aws_iam_role.service_iam_role.arn
}

output "aws_efs_fs_id" {
  value = aws_efs_file_system.rafay_efs_fs.id
}