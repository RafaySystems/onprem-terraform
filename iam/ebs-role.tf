data "aws_caller_identity" "this" {}
data "aws_region" "this" {}
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  oidc_provider = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

###---CREATES EBS IAM ROLE FOR ENCRYPTION OF VOLUMES---###
data "aws_iam_policy_document" "ebs_csi_role_trustpolicy" {
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
        "system:serviceaccount:kube-system:ebs-csi-controller-sa"
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

resource "aws_iam_role" "ebs_iam_role" {
  name               = var.ebs_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_role_trustpolicy.json
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  role       = aws_iam_role.ebs_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_policy" "KMS_Key_For_Encryption_On_EBS_Policy" {
  name = var.kms_ebspolicy_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        "Resource" : ["${var.kms_key_arn}"],
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : ["${var.kms_key_arn}"]
      }
    ]
  })
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_role_policy_attachment" "kms_ebspolicy_attachment" {
  role       = aws_iam_role.ebs_iam_role.name
  policy_arn = aws_iam_policy.KMS_Key_For_Encryption_On_EBS_Policy.arn
}
