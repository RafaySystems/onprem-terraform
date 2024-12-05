###---CREATES AND ECRYTPS THE S3 BUCKET------###
resource "aws_s3_bucket" "logs_for_kinesis" {
  bucket = var.s3_bucket
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kinesis_s3_encrypts" {
  bucket = aws_s3_bucket.logs_for_kinesis.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

#######################################-------------------------------------------------Kinesis-------------------------------##############################
data "aws_caller_identity" "this" {}
data "aws_region" "this" {}
data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

locals {
  oidc_provider = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

###---CREATES INGEST IAM ROLE FOR AMP---###
data "aws_iam_policy_document" "firehose_delivery_assume_role" {
  statement {
    sid     = "1"
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
      variable = "${local.oidc_provider}:sub"
      values = [
        "system:serviceaccount:rafay-core:fluentd-aggregator"
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

resource "aws_iam_policy" "firehose-elasticsearch" {
  name   = "${var.eks_cluster_name}-elasticsearch"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "es:*"
      ],
      "Resource": [
        "${var.es_arn}",
        "${var.es_arn}/*"
      ]
        },
        {
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
          "Resource": [
            "*"
          ]
        }
  ]
}
EOF
}

resource "aws_iam_policy" "firehose-elasticsearch-vpc" {
  name   = "${var.eks_cluster_name}-elasticsearch-vpc"
  policy = <<EOF
{
    "Version": "2012-10-17",  
    "Statement": [    
        {      
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
                "arn:aws:s3:::${var.s3_bucket}",
                "arn:aws:s3:::${var.s3_bucket}/*"		    
            ]    
        },
        {
           "Effect": "Allow",
           "Action": [
               "kms:Decrypt",
               "kms:GenerateDataKey"
           ],
           "Resource": [
               "${var.kms_key_arn}"           
           ],
           "Condition": {
               "StringEquals": {
                   "kms:ViaService": "s3.${data.aws_region.this.name}.amazonaws.com"
               },
               "StringLike": {
                   "kms:EncryptionContext:aws:s3:arn": "arn:aws:s3:::${var.s3_bucket}/*"
               }
           }
        },
        {
           "Effect": "Allow",
           "Action": [
               "es:DescribeDomain",
               "es:DescribeDomains",
               "es:DescribeDomainConfig",
               "es:ESHttpPost",
               "es:ESHttpPut"
           ],
          "Resource": [
              "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}",
              "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/*"
          ]
       },
       {
          "Effect": "Allow",
          "Action": [
              "es:ESHttpGet"
          ],
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
          "Effect": "Allow",
          "Action": [
              "kinesis:DescribeStream",
              "kinesis:GetShardIterator",
              "kinesis:GetRecords",
              "kinesis:ListShards"
          ],
          "Resource": "arn:aws:kinesis:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:stream/${var.stream_name}"
       }
    ]
}
EOF
}

resource "aws_iam_role" "firehose_delivery_role" {
  name               = var.kinesis_iam_role
  assume_role_policy = data.aws_iam_policy_document.firehose_delivery_assume_role.json
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_role_policy_attachment" "attach_kinesis_full_access" {
  role       = aws_iam_role.firehose_delivery_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess"
}

resource "aws_iam_role_policy_attachment" "attach_firehose_elasticsearch_ploicy" {
  role       = aws_iam_role.firehose_delivery_role.name
  policy_arn = aws_iam_policy.firehose-elasticsearch.arn
}

resource "aws_iam_role_policy_attachment" "attach_firehose_elasticsearch_public_ploicy" {
  role       = aws_iam_role.firehose_delivery_role.name
  policy_arn = aws_iam_policy.firehose-elasticsearch-vpc.arn
}

resource "aws_kinesis_firehose_delivery_stream" "kinesis-firehose-private" {
  name        = var.stream_name
  destination = var.destination
  count       = var.opensearch_public ? 0 : 1

  s3_configuration {
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    bucket_arn         = aws_s3_bucket.logs_for_kinesis.arn
    buffer_size        = var.s3_buffer_size
    buffer_interval    = var.s3_buffer_interval
    compression_format = var.s3_compression_format
    cloudwatch_logging_options {
      enabled         = false
      log_group_name  = "/aws/kinesisfirehose/${var.stream_name}"
      log_stream_name = var.s3_log_stream_name
    }
  }

  elasticsearch_configuration {
    domain_arn         = var.es_arn
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    index_name         = var.es_index_name
    buffering_size     = var.es_buffering_size
    buffering_interval = var.es_buffering_interval
    s3_backup_mode     = var.s3_backup_mode
    cloudwatch_logging_options {
      enabled         = false
      log_group_name  = "/aws/kinesisfirehose/${var.stream_name}"
      log_stream_name = var.os_log_stream_name
    }
    vpc_config {
      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.kinesis.id]
      role_arn           = aws_iam_role.firehose_delivery_role.arn
    }
  }
  tags = merge(
    var.default_tags,
    {
    },
  )
}


resource "aws_kinesis_firehose_delivery_stream" "kinesis-firehose-public" {
  name        = var.stream_name
  destination = var.destination
  count       = var.opensearch_public ? 1 : 0

  s3_configuration {
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    bucket_arn         = aws_s3_bucket.logs_for_kinesis.arn
    buffer_size        = var.s3_buffer_size
    buffer_interval    = var.s3_buffer_interval
    compression_format = var.s3_compression_format
    cloudwatch_logging_options {
      enabled         = false
      log_group_name  = "/aws/kinesisfirehose/${var.stream_name}"
      log_stream_name = var.s3_log_stream_name
    }
  }

  elasticsearch_configuration {
    domain_arn         = var.es_arn
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    index_name         = var.es_index_name
    buffering_size     = var.es_buffering_size
    buffering_interval = var.es_buffering_interval
    s3_backup_mode     = var.s3_backup_mode
    cloudwatch_logging_options {
      enabled         = false
      log_group_name  = "/aws/kinesisfirehose/${var.stream_name}"
      log_stream_name = var.os_log_stream_name
    }
  }
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_security_group" "kinesis" {
  vpc_id = var.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = var.ingress_cidr_blocks
  }
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = var.ingress_cidr_blocks
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = var.egress_cidr_blocks
  }
  tags = merge(
    var.default_tags,
    {
    },
  )
}
