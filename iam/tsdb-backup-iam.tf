###----CREATES S3 BUCKET FOR TSDB BACKUP----###
resource "aws_s3_bucket" "tsdb_bucket" {
  count         = var.amp-enabled ? 0 : (var.use_existing_s3_tsdb_bucket ? 0 : 1)
  bucket        = var.s3_tsdb_backup_bucket
  force_destroy = true
  tags = merge(
    var.default_tags,
    {
    },
  )

}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  count  = var.amp-enabled ? 0 : (var.use_existing_s3_tsdb_bucket ? 0 : 1)
  bucket = var.s3_tsdb_backup_bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

###---CREATES TSDB IAM ROLE SECRETS AND BACKUP---###
data "aws_iam_policy_document" "tsdb_trustpolicy" {
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
        "system:serviceaccount:rafay-core:rafay-tsdb-sa"
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

resource "aws_iam_role" "tsdb_iam_role" {
  count              = var.amp-enabled ? 0 : 1
  name               = var.tsdb_backup_role_name
  assume_role_policy = data.aws_iam_policy_document.tsdb_trustpolicy.json
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_policy" "tsdb_policy" {
  count = var.amp-enabled ? 0 : 1
  name  = var.tsdb_backup_policy_name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.s3_tsdb_backup_bucket}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.s3_tsdb_backup_bucket}",
          "arn:aws:s3:::${var.s3_tsdb_backup_bucket}/*",
          "arn:aws:kms:*:*:key/*"
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

resource "aws_iam_role_policy_attachment" "attach_tsdbpolicy" {
  count      = var.amp-enabled ? 0 : 1
  role       = aws_iam_role.tsdb_iam_role[0].name
  policy_arn = aws_iam_policy.tsdb_policy[0].arn
}
