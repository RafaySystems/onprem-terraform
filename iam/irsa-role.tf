###---CREATES VELERO IAM ROLE SECRETS AND BACKUP---###
data "aws_iam_policy_document" "irsa_instance_role_trustpolicy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:oidc-provider/${local.oidc_provider}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values = [
        "system:serviceaccount:rafay-core:edgesrv-sa",
        "system:serviceaccount:rafay-core:edge-factory-sa"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "irsa_instance_iam_role" {
  count                = var.use-instance-role ? 1 : 0
  name                 = var.irsa_instance_iam_role_name
  max_session_duration = var.iam_max_session_duration
  assume_role_policy   = data.aws_iam_policy_document.irsa_instance_role_trustpolicy.json
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_policy" "IRSA_AMP_Policy" {
  name = var.irsa_AMP_policy_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole",
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ],
        "Resource" : "*"
      }
    ]
  })
  tags = merge(
    var.default_tags,
    {
    },
  )
}


resource "aws_iam_role_policy_attachment" "amp_ingest_policy" {
  count      = var.use-instance-role ? 1 : 0
  role       = one(aws_iam_role.irsa_instance_iam_role.*.name)
  policy_arn = aws_iam_policy.IRSA_AMP_Policy.arn
}
