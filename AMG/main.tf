resource "aws_grafana_workspace" "grafana_workspace" {
  account_access_type      = var.grafana_workspace_account_access_type
  authentication_providers = var.grafana_workspace_authentication_providers
  permission_type          = var.grafana_workspace_permission_type
  role_arn                 = aws_iam_role.grafana_service_role.arn
  data_sources             = var.grafana_workspace_data_sources
  name                     = var.grafana_workspace_name
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_role" "grafana_service_role" {
  name = "${var.grafana_workspace_name}-assume-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      },
    ]
  })
  tags = merge(
    var.default_tags,
    {
    },
  )
}
resource "aws_iam_policy" "AMP_access_to_AMG" {
  name = "${var.grafana_workspace_name}-AMP_access_to_AMG-policy"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "aps:ListWorkspaces",
            "aps:DescribeWorkspace",
            "aps:QueryMetrics",
            "aps:GetLabels",
            "aps:GetSeries",
            "aps:GetMetricMetadata"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
  description = "Allows Amazon Grafana to access Amazon Prometheus"
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_policy" "OS_access_to_AMG" {
  name = "${var.grafana_workspace_name}-OS_access_to_AMG-policy"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "es:ESHttpGet",
            "es:DescribeElasticsearchDomains",
            "es:ListDomainNames"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "es:ESHttpPost",
          "Resource" : [
            "arn:aws:es:*:*:domain/*/_msearch*",
            "arn:aws:es:*:*:domain/*/_opendistro/_ppl"
          ]
        }
      ]
    }
  )
  description = "Allows Amazon Grafana to access Amazon OpenSearch"
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_role_policy_attachment" "AMP_access_to_AMG_attachment" {
  role       = aws_iam_role.grafana_service_role.name
  policy_arn = aws_iam_policy.AMP_access_to_AMG.arn
}
resource "aws_iam_role_policy_attachment" "OS_access_to_AMG_attachment" {
  role       = aws_iam_role.grafana_service_role.name
  policy_arn = aws_iam_policy.OS_access_to_AMG.arn
}