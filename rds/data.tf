#############------------------------Database password-----------------------------------------#####################

# Importing the AWS secrets created for database previously using arn.
data "aws_secretsmanager_secret" "postgresdbpwd" {
  count = var.dbsecret_arn != "" ? 1 : 0
  arn   = var.dbsecret_arn
}

# Importing the AWS secret version created previously using arn.
data "aws_secretsmanager_secret_version" "existing_creds" {
  depends_on = [
    data.aws_secretsmanager_secret.postgresdbpwd
  ]
  count     = var.dbsecret_arn != "" ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.postgresdbpwd[0].arn
}