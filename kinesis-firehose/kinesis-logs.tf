###---CREATES AND ECRYTPS THE S3 BUCKET------###
resource "aws_s3_bucket" "controllerlogs_for_kinesis" {
  bucket = var.s3_logsbucket
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kinesis_s3encrypts" {
  bucket = aws_s3_bucket.controllerlogs_for_kinesis.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

## IAM POLICY FOR CONTROLLER LOGS USING KINESIS
###---CREATES INGEST IAM ROLE FOR AMP---###
data "aws_iam_policy_document" "firehose_delivery_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    sid     = "2"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:oidc-provider/${local.oidc_provider}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values = [
        "system:serviceaccount:rafay-core:fluentd-aggregator"
      ]
    }
  }
}

resource "aws_iam_policy" "firehose-elasticsearch-logspolicy" {
  name   = "${var.eks_cluster_name}-elasticsearchlogs"
  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "es:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "${var.es_arn}",
                "${var.es_arn}/*"
            ]
        },
        {
            "Action": [
                "ec2:DescribeVpcs",
                "ec2:DescribeVpcAttribute",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface"
            ],
            "Effect": "Allow",
            "Resource": [
                "*"
            ]
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_policy" "firehose-elasticsearch-logs" {
  name   = "${var.eks_cluster_name}-elasticsearch-logs"
  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:PutObject"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::${var.s3_logsbucket}",
                "arn:aws:s3:::${var.s3_logsbucket}/*",	
                "arn:aws:s3:::${var.s3_bucket}",
                "arn:aws:s3:::${var.s3_bucket}/*"	
            ]
        },
        {
            "Action": [
                "kms:Decrypt",
                "kms:GenerateDataKey"
            ],
            "Condition": {
                "StringEquals": {
                    "kms:ViaService": "s3.${data.aws_region.this.name}.amazonaws.com"
                },
                "StringLike": {
                    "kms:EncryptionContext:aws:s3:arn": [
                        "arn:aws:s3:::${var.s3_logsbucket}/*",	
                        "arn:aws:s3:::${var.s3_bucket}/*"
                    ]
                }
            },
            "Effect": "Allow",
            "Resource": [
                "${var.kms_key_arn}"
            ]
        },
        {
            "Action": [
                "es:DescribeDomain",
                "es:DescribeDomains",
                "es:DescribeDomainConfig",
                "es:ESHttpPost",
                "es:ESHttpPut"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/*"
            ]
        },
        {
            "Action": [
                "es:ESHttpGet"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/_all/_settings",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/_cluster/stats",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/relay-audit*/_mapping/*",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/_nodes",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/_nodes/stats",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/_nodes/*/stats",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/_stats",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/relay-audit*/_stats"
            ]
        },
        {
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords",
                "kinesis:ListShards"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:kinesis:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:stream/${var.stream_name}"
        },
        {
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords",
                "kinesis:ListShards"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:kinesis:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:stream/${var.logsstream_name}"
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_policy" "firehose-elasticsearch-controllerlogs" {
  name   = "${var.eks_cluster_name}-es-controllerlogs"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::${var.s3_logsbucket}",
                "arn:aws:s3:::${var.s3_logsbucket}/*"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVpcs",
                "ec2:DescribeVpcAttribute",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface"
            ],
            "Resource": "*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "es:DescribeElasticsearchDomain",
                "es:DescribeElasticsearchDomains",
                "es:DescribeElasticsearchDomainConfig",
                "es:ESHttpPost",
                "es:ESHttpPut"
            ],
            "Resource": [
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/*"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "es:ESHttpGet"
            ],
            "Resource": [
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/_all/_settings",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/_cluster/stats",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/rafay-controller-logs*/_mapping/*",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/_nodes",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/_nodes/*/stats",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/_stats",
                "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/rafay-controller-logs*/_stats"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:log-group:/aws/kinesisfirehose/${var.logsstream_name}:log-stream:*"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords",
                "kinesis:ListShards"
            ],
            "Resource": "arn:aws:kinesis:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:stream/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
        }
    ]
}
EOF
}

resource "aws_iam_role" "firehose_delivery_logs_role" {
  name               = var.kinesislogs_iam_role
  assume_role_policy = data.aws_iam_policy_document.firehose_delivery_logs_assume_role.json
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_role_policy_attachment" "attach_kinesis_fullaccess" {
  role       = aws_iam_role.firehose_delivery_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess"
}

resource "aws_iam_role_policy_attachment" "attach_firehose_elasticsearch_ec2_ploicy" {
  role       = aws_iam_role.firehose_delivery_logs_role.name
  policy_arn = aws_iam_policy.firehose-elasticsearch-logspolicy.arn
}

resource "aws_iam_role_policy_attachment" "attach_firehose_elasticsearch_logs_ploicy" {
  role       = aws_iam_role.firehose_delivery_logs_role.name
  policy_arn = aws_iam_policy.firehose-elasticsearch-logs.arn
}

resource "aws_iam_role_policy_attachment" "attach_firehose_controller_logs_ploicy" {
  role       = aws_iam_role.firehose_delivery_logs_role.name
  policy_arn = aws_iam_policy.firehose-elasticsearch-controllerlogs.arn
}

###KINESIS FIRE HOUSE DELIVERY STREAM

resource "aws_kinesis_firehose_delivery_stream" "kinesis-firehose-logs" {
  name        = var.logsstream_name
  destination = var.destination
  count       = var.opensearch_public ? 0 : 1

  s3_configuration {
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    bucket_arn         = aws_s3_bucket.controllerlogs_for_kinesis.arn
    buffer_size        = var.s3_buffer_size
    buffer_interval    = var.s3_buffer_interval
    compression_format = var.s3_compression_format
    cloudwatch_logging_options {
      enabled         = false
      log_group_name  = "/aws/kinesisfirehose/${var.logsstream_name}"
      log_stream_name = var.s3_log_stream_name
    }
  }

  elasticsearch_configuration {
    domain_arn         = var.es_arn
    role_arn           = aws_iam_role.firehose_delivery_logs_role.arn
    index_name         = var.es_logsindex_name
    buffering_size     = var.es_buffering_size
    buffering_interval = var.es_buffering_interval
    s3_backup_mode     = var.s3_backup_mode
    cloudwatch_logging_options {
      enabled         = false
      log_group_name  = "/aws/kinesisfirehose/${var.logsstream_name}"
      log_stream_name = var.os_log_stream_name
    }
    vpc_config {
      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.kinesis.id]
      role_arn           = aws_iam_role.firehose_delivery_logs_role.arn
    }
  }
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_kinesis_firehose_delivery_stream" "kinesis-firehose-logspublic" {
  name        = var.logsstream_name
  destination = var.destination
  count       = var.opensearch_public ? 1 : 0

  s3_configuration {
    role_arn           = aws_iam_role.firehose_delivery_logs_role.arn
    bucket_arn         = aws_s3_bucket.controllerlogs_for_kinesis.arn
    buffer_size        = var.s3_buffer_size
    buffer_interval    = var.s3_buffer_interval
    compression_format = var.s3_compression_format
    cloudwatch_logging_options {
      enabled         = false
      log_group_name  = "/aws/kinesisfirehose/${var.logsstream_name}"
      log_stream_name = var.s3_log_stream_name
    }
  }

  elasticsearch_configuration {
    domain_arn         = var.es_arn
    role_arn           = aws_iam_role.firehose_delivery_logs_role.arn
    index_name         = var.es_logsindex_name
    buffering_size     = var.es_buffering_size
    buffering_interval = var.es_buffering_interval
    s3_backup_mode     = var.s3_backup_mode
    cloudwatch_logging_options {
      enabled         = false
      log_group_name  = "/aws/kinesisfirehose/${var.logsstream_name}"
      log_stream_name = var.os_log_stream_name
    }
  }
  tags = merge(
    var.default_tags,
    {
    },
  )
}
