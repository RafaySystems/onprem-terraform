# Firstly create a random generated password to use in secrets.

resource "random_password" "restore_rds_password" {
  length           = 12
  special          = false
  min_lower        = 1
  min_special      = 1
  min_numeric      = 1
  min_upper        = 1
  override_special = "!#%&*()-_=+[]{}<>:?"
}

# Creating a AWS secret for database  (postgres-password)

resource "aws_secretsmanager_secret" "restore_postgresDBPwd" {
  name                    = var.secretsName
  recovery_window_in_days = var.recovery_window_in_days
  tags = merge(
    var.default_tags,
    {
    },
  )
}

# Creating a AWS secret versions for database (postgres-password)

resource "aws_secretsmanager_secret_version" "restore_sversion" {
  secret_id     = aws_secretsmanager_secret.restore_postgresDBPwd.id
  depends_on    = [aws_secretsmanager_secret.restore_postgresDBPwd]
  secret_string = <<EOF
   {
    "username": "postgres",
    "password": "${random_password.restore_rds_password.result}"
   }
EOF
}

# Importing the AWS secrets created previously using arn.

data "aws_secretsmanager_secret" "restore_postgresDBPwd" {
  arn        = aws_secretsmanager_secret.restore_postgresDBPwd.arn
  depends_on = [aws_secretsmanager_secret.restore_postgresDBPwd]
}

# Importing the AWS secret version created previously using arn.

data "aws_secretsmanager_secret_version" "restore_creds" {
  secret_id  = data.aws_secretsmanager_secret.restore_postgresDBPwd.arn
  depends_on = [aws_secretsmanager_secret_version.restore_sversion]
}

# After importing the secrets storing into Locals

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.restore_creds.secret_string)
}
