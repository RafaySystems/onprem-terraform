###----CREATES S3 BUCKET FOR VELERO----###
resource "aws_s3_bucket" "restores_data" {
  count         = var.backup_enabled ? (var.backup-restore ? 0 : (var.use_existing_s3_backup_restore_bucket ? 0 : 1)) : 0
  bucket        = var.s3_backup_restore_bucketname
  force_destroy = true
  tags = merge(
    var.default_tags,
    {
    },
  )

}

resource "aws_s3_bucket_server_side_encryption_configuration" "kinesis_s3_encrypts" {
  count  = var.backup_enabled ? (var.backup-restore ? 0 : (var.use_existing_s3_backup_restore_bucket ? 0 : 1)) : 0
  bucket = var.s3_backup_restore_bucketname

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

###---CREATES VELERO IAM ROLE SECRETS AND BACKUP---###
data "aws_iam_policy_document" "BackupRestore_trustpolicy" {
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
        "system:serviceaccount:velero:rafay-velero-sa"
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

resource "aws_iam_role" "BackupRestore_iam_role" {
  count              = var.backup_enabled ? 1 : 0
  name               = var.BackupRestore_role_name
  assume_role_policy = data.aws_iam_policy_document.BackupRestore_trustpolicy.json
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_policy" "BackupRestore_policy" {
  count = var.backup_enabled ? 1 : 0
  name  = var.BackupRestore_policy_name
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
          "arn:aws:s3:::${var.s3_backup_restore_bucketname}/*"
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
          "arn:aws:s3:::${var.s3_backup_restore_bucketname}",
          "arn:aws:s3:::${var.s3_backup_restore_bucketname}/*",
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

resource "aws_iam_role_policy_attachment" "attach_veleropolicy" {
  count      = var.backup_enabled ? 1 : 0
  role       = aws_iam_role.BackupRestore_iam_role[0].name
  policy_arn = aws_iam_policy.BackupRestore_policy[0].arn
}
