data "aws_caller_identity" "this" {}

#############------------------------Opensearch-----------------------------------------#####################

data "local_file" "seq_no" {
  count = var.opensearchEnabled ? 1 : 0
  depends_on = [
    null_resource.to-get-seqno
  ]
  filename = "${path.module}/seqno.txt"
}

data "local_file" "primary_term" {
  count = var.opensearchEnabled ? 1 : 0
  depends_on = [
    null_resource.to-get-primaryterm
  ]
  filename = "${path.module}/primaryterm.txt"
}

#############------------------------Database password-----------------------------------------#####################

# Importing the AWS secrets created for database previously using arn.
data "aws_secretsmanager_secret" "postgresDBPwd" {
  count = var.dbsecret_arn != "" ? 1 : 0
  arn   = var.dbsecret_arn
}

# Importing the AWS secret version created previously using arn.
data "aws_secretsmanager_secret_version" "creds" {
  depends_on = [
    data.aws_secretsmanager_secret.postgresDBPwd
  ]
  count     = var.dbsecret_arn != "" ? 1 : 0
  secret_id = one(data.aws_secretsmanager_secret.postgresDBPwd.*.id)
}

data "external" "db_secrets" {
  depends_on = [
    data.aws_secretsmanager_secret.postgresDBPwd
  ]
  count   = var.dbsecret_arn != "" ? 1 : 0
  program = ["echo", "${one(data.aws_secretsmanager_secret_version.creds.*.secret_string)}"]
}

#############------------------------Super user password-----------------------------------------#####################

# Importing the AWS secrets created for super user previously using arn.
data "aws_secretsmanager_secret" "superuserPwd" {
  count = var.superuser_secret_arn != "" ? 1 : 0
  arn   = var.superuser_secret_arn
}

# Importing the AWS secret version created previously using arn.
data "aws_secretsmanager_secret_version" "superuser_creds" {
  count     = var.superuser_secret_arn != "" ? 1 : 0
  secret_id = one(data.aws_secretsmanager_secret.superuserPwd.*.id)
}

data "external" "superuser_secrets" {
  count   = var.superuser_secret_arn != "" ? 1 : 0
  program = ["echo", "${one(data.aws_secretsmanager_secret_version.superuser_creds.*.secret_string)}"]
}


#############------------------------External user password-----------------------------------------#####################

# Importing the AWS secrets created for super user previously using arn.
data "aws_secretsmanager_secret" "external_es_password" {
  count = var.external_elasticserach_secret_arn != "" ? 1 : 0
  arn   = var.external_elasticserach_secret_arn
}

# Importing the AWS secret version created previously using arn.
data "aws_secretsmanager_secret_version" "external_es_password_creds" {
  count     = var.external_elasticserach_secret_arn != "" ? 1 : 0
  secret_id = one(data.aws_secretsmanager_secret.external_es_password.*.id)
}

data "external" "external_es_secrets" {
  count   = var.external_elasticserach_secret_arn != "" ? 1 : 0
  program = ["echo", "${one(data.aws_secretsmanager_secret_version.external_es_password_creds.*.secret_string)}"]
}
