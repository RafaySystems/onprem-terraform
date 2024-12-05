###----CREATES S3 BUCKET FOR EAAS Service----###
resource "aws_s3_bucket" "eaas_bucket" {
  count         = var.use_existing_s3_eaas_bucket ? 0 : 1
  bucket        = var.eaas_bucketname
  force_destroy = true
  tags = merge(
    var.default_tags,
    {
    },
  )

}

resource "aws_s3_bucket_server_side_encryption_configuration" "eaas_bucket_s3_encrypts" {
  count      = var.use_existing_s3_eaas_bucket ? 0 : 1
  depends_on = [aws_s3_bucket.eaas_bucket]
  bucket     = var.eaas_bucketname

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}


resource "aws_s3_bucket_policy" "allow_access_from_other_resource" {
  count = var.use_existing_s3_eaas_bucket ? 0 : 1
  depends_on = [
    aws_s3_bucket.eaas_bucket,
    aws_s3_bucket_server_side_encryption_configuration.eaas_bucket_s3_encrypts,
    data.aws_iam_policy_document.allow_access_for_s3,
  ]
  bucket = aws_s3_bucket.eaas_bucket[0].id
  policy = data.aws_iam_policy_document.allow_access_for_s3[0].json
}

data "aws_iam_policy_document" "allow_access_for_s3" {
  count      = var.use_existing_s3_eaas_bucket ? 0 : 1
  depends_on = [aws_s3_bucket.eaas_bucket]
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/${var.eaas_role_name}"]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.eaas_bucket[0].arn,
      "${aws_s3_bucket.eaas_bucket[0].arn}/*",
    ]
  }
}

###---CREATES IRSA ROLE AND Policy for EAAS SERVICE---###
data "aws_iam_policy_document" "eaas_role_trustpolicy" {
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
        "system:serviceaccount:rafay-core:engine-api-sa"
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

resource "aws_iam_role" "eaas_iam_role" {
  name               = var.eaas_role_name
  assume_role_policy = data.aws_iam_policy_document.eaas_role_trustpolicy.json
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_policy" "eaas_iam_policy" {
  name = var.eaas_policy_name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "s3:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.eaas_bucketname}",
          "arn:aws:s3:::${var.eaas_bucketname}/*",
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

resource "aws_iam_role_policy_attachment" "attach_eaas_policy" {
  role       = aws_iam_role.eaas_iam_role.name
  policy_arn = aws_iam_policy.eaas_iam_policy.arn
}
