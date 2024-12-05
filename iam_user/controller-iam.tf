resource "aws_iam_policy" "rafay_sts_policy" {
  name = var.sts_policy_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : "sts:*",
        "Resource" : "*"
      },
      {
        "Action" : [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      }
    ]
  })
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_user_policy_attachment" "attach_ec2readonly" {
  user       = aws_iam_user.delegate_account.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}


resource "aws_iam_user" "delegate_account" {
  name = var.iam_user_name
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_user_policy_attachment" "sts-policy-attach" {
  user       = aws_iam_user.delegate_account.name
  policy_arn = aws_iam_policy.rafay_sts_policy.arn
}

resource "aws_iam_access_key" "User_account" {
  user = aws_iam_user.delegate_account.name
}

data "template_file" "secret" {
  template = aws_iam_access_key.User_account.secret
}

###---Secret Manager-----##
resource "aws_secretsmanager_secret" "awscredentials" {
  name                    = var.User_credentials
  recovery_window_in_days = var.recovery_window_in_days
  tags = merge(
    var.default_tags,
    {
    },
  )
}

# Creating a AWS secret versions for AWS CREDENTIALS

resource "aws_secretsmanager_secret_version" "credentials-sversion" {
  secret_id     = aws_secretsmanager_secret.awscredentials.id
  secret_string = <<EOF
   {
    "accesskey": "${aws_iam_access_key.User_account.id}",
    "secretkey": "${data.template_file.secret.rendered}"
   }
EOF
}

# Importing the AWS secrets created previously using arn.

data "aws_secretsmanager_secret" "awscredentials" {
  depends_on = [aws_secretsmanager_secret.awscredentials]
  arn        = aws_secretsmanager_secret.awscredentials.arn
}


# Importing the AWS secret version created previously using arn.

data "aws_secretsmanager_secret_version" "credentialsUser" {
  depends_on = [aws_secretsmanager_secret_version.credentials-sversion]
  secret_id  = data.aws_secretsmanager_secret.awscredentials.arn
}

# After importing the secrets storing into Local variables

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.credentialsUser.secret_string)
}

/* resource "null_resource" "execute_user_permission" {
  depends_on = [
    aws_iam_user.delegate_account
  ]
  provisioner "local-exec" {
    command = <<EOT
    kubectl patch configmap --kubeconfig "${var.path}/${var.cluster_name}-kubeconfig" -n kube-system aws-auth -p '{"data":{"mapUsers": [{\"userarn\": \"${aws_iam_user.delegate_account.arn}\", \"username\": \"${var.iam_user_name}\", \"groups\": [\"system:masters\"]}]}}'
    EOT
  }
} */
