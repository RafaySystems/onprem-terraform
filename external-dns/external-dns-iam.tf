data "aws_caller_identity" "this" {}
data "aws_region" "this" {}
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  oidc_provider = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

###---CREATES EXTERNAL DNS IAM ROLE---###
data "aws_iam_policy_document" "external_dns" {
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
        "system:serviceaccount:kube-system:rafay-external-dns-sa"
      ]
    }
  }
}

resource "aws_iam_role" "external-dns-role" {
  name               = var.external_dns_role_name
  assume_role_policy = data.aws_iam_policy_document.external_dns.json
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_policy" "external-dns-policy" {
  name = var.external_dns_policy_name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource" : [
          "arn:aws:route53:::hostedzone/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_role_policy_attachment" "amp_write" {
  role       = aws_iam_role.external-dns-role.name
  policy_arn = aws_iam_policy.external-dns-policy.arn
}
