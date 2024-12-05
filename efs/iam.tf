data "aws_caller_identity" "this" {}
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

locals {
  oidc_provider = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
}


data "aws_iam_policy_document" "remote_write_assume" {
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
      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "service_iam_role" {
  name               = var.efs_role_name
  assume_role_policy = data.aws_iam_policy_document.remote_write_assume.json
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_policy" "service_iam_policy" {
  name = var.efs_policy_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticfilesystem:CreateAccessPoint"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:RequestTag/efs.csi.aws.com/cluster" : "true"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : "elasticfilesystem:DeleteAccessPoint",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/efs.csi.aws.com/cluster" : "true"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticfilesystem:TagResource"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:ResourceTag/efs.csi.aws.com/cluster" : "true"
          }
        }
      }
    ]
  })
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_role_policy_attachment" "efs_policy_attachment" {
  role       = aws_iam_role.service_iam_role.name
  policy_arn = aws_iam_policy.service_iam_policy.arn
}