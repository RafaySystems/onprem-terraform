# Firstly create a random generated password to use in secrets.

resource "random_password" "super_password" {
  length           = 8
  special          = true
  min_lower        = 1
  min_special      = 1
  min_numeric      = 1
  min_upper        = 1
  override_special = "@"
}

# Creating a AWS secret for Super User  (Super User-password)

resource "aws_secretsmanager_secret" "super_user_password" {
  count                   = var.use_aws_secret_manager ? 1 : 0
  name                    = var.super_user_SecretName
  recovery_window_in_days = var.recovery_window_in_days
  tags = merge(
    var.default_tags,
    {
    },
  )
}

# Creating an AWS secret version for Super User (postgres-password)

resource "aws_secretsmanager_secret_version" "secret_version" {
  count         = var.use_aws_secret_manager ? 1 : 0
  secret_id     = aws_secretsmanager_secret.super_user_password[count.index].id
  depends_on    = [aws_secretsmanager_secret.super_user_password]
  secret_string = <<EOF
   {
    "username": "${var.super_user}",
    "password": "${random_password.super_password.result}"
   }
EOF
}

# Importing the AWS secrets created previously using ARN.

data "aws_secretsmanager_secret" "super_user_password" {
  count      = var.use_aws_secret_manager ? 1 : 0
  depends_on = [aws_secretsmanager_secret_version.secret_version]
  arn        = aws_secretsmanager_secret.super_user_password[count.index].arn
}

# Importing the AWS secret version created previously using ARN.

data "aws_secretsmanager_secret_version" "secret_creds" {
  count = var.use_aws_secret_manager ? 1 : 0
  depends_on = [
    aws_secretsmanager_secret_version.secret_version,
    data.aws_secretsmanager_secret.super_user_password
  ]
  secret_id = data.aws_secretsmanager_secret.super_user_password[0].arn
}

# After importing the secrets, storing into Locals

locals {
  super_creds = var.use_aws_secret_manager ? jsondecode(data.aws_secretsmanager_secret_version.secret_creds[0].secret_string) : null
}

output "super_password" {
  value = local.super_creds != null ? local.super_creds.password : random_password.super_password.result
}
