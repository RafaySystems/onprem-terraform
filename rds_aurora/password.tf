# Firstly create a random generated password to use in secrets.

resource "random_password" "password" {
  length           = 12
  special          = true
  min_lower        = 1
  min_special      = 1
  min_numeric      = 1
  min_upper        = 1
  override_special = "!#%&*()-_=+[]{}<>:?"
}

# Creating a AWS secret for database  (postgres-password)

resource "aws_secretsmanager_secret" "postgresDBPwd" {
  count                   = var.use_aws_secret_manager ? 1 : 0
  name                    = var.rds_SecretName
  recovery_window_in_days = var.recovery_window_in_days
  tags = merge(
    var.default_tags,
    {
    },
  )
}

# Creating a AWS secret versions for database (postgres-password)

resource "aws_secretsmanager_secret_version" "sversion" {
  count         = var.use_aws_secret_manager ? 1 : 0
  secret_id     = aws_secretsmanager_secret.postgresDBPwd[count.index].id
  depends_on    = [aws_secretsmanager_secret.postgresDBPwd]
  secret_string = <<EOF
   {
    "username": "${var.username}",
    "password": "${random_password.password.result}"
   }
EOF
}

# Importing the AWS secrets created previously using arn.

data "aws_secretsmanager_secret" "postgresDBPwd" {
  count      = var.use_aws_secret_manager ? 1 : 0
  depends_on = [aws_secretsmanager_secret.postgresDBPwd]
  arn        = aws_secretsmanager_secret.postgresDBPwd[count.index].arn
}

# Importing the AWS secret version created previously using arn.

data "aws_secretsmanager_secret_version" "creds" {
  count = var.use_aws_secret_manager ? 1 : 0
  depends_on = [
    aws_secretsmanager_secret_version.sversion,
    data.aws_secretsmanager_secret.postgresDBPwd
  ]
  secret_id = data.aws_secretsmanager_secret.postgresDBPwd[0].arn
}

# After importing the secrets storing into Locals

locals {
  db_creds = var.use_aws_secret_manager ? jsondecode(data.aws_secretsmanager_secret_version.creds[0].secret_string) : null
}