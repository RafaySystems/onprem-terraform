# Firstly create a random generated password to use in secrets.

resource "random_password" "opensearch_password" {
  length           = 10
  special          = true
  min_lower        = 1
  min_special      = 1
  min_numeric      = 1
  min_upper        = 1
  override_special = "_$"
}

# Creating a AWS secret for Open search (opensearchdomain-password)

resource "aws_secretsmanager_secret" "opensearch_Pwd" {
  count                   = var.use_aws_secret_manager ? 1 : 0
  name                    = var.OS_SecretName
  recovery_window_in_days = var.recovery_window_in_days
  tags = merge(
    var.default_tags,
    {
    },
  )

}

# Creating a AWS secret versions for Opensearch (postgres-password)

resource "aws_secretsmanager_secret_version" "opensearch_sversion" {
  count                   = var.use_aws_secret_manager ? 1 : 0
  secret_id     = aws_secretsmanager_secret.opensearch_Pwd[count.index].id
  depends_on    = [aws_secretsmanager_secret.opensearch_Pwd]
  secret_string = <<EOF
   {
    "username": "Rafay",
    "password": "${random_password.opensearch_password.result}"
   }
EOF
}

# Importing the AWS secrets created previously using arn.

data "aws_secretsmanager_secret" "opensearch_Pwd" {
  count                   = var.use_aws_secret_manager ? 1 : 0
  depends_on = [aws_secretsmanager_secret.opensearch_Pwd]
  arn        = aws_secretsmanager_secret.opensearch_Pwd[count.index].arn
}

# Importing the AWS secret version created previously using arn.

data "aws_secretsmanager_secret_version" "opensearch_creds" {
  count                   = var.use_aws_secret_manager ? 1 : 0
  depends_on = [
    aws_secretsmanager_secret_version.opensearch_sversion,
    data.aws_secretsmanager_secret.opensearch_Pwd
  ]
  secret_id = data.aws_secretsmanager_secret.opensearch_Pwd[0].arn
}

# After importing the secrets storing into Locals

locals {
  os_creds = var.use_aws_secret_manager ? jsondecode(data.aws_secretsmanager_secret_version.opensearch_creds[0].secret_string) : null
}

output "opensearch_password" {
  value = local.os_creds != null ? local.os_creds.password : random_password.opensearch_password.result
}