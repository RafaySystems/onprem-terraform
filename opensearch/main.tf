data "aws_caller_identity" "this" {}
data "aws_region" "this" {}
data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "opensearch" {
  name   = "${var.domain}-sg"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = compact(concat(var.ingress_cidr_blocks, formatlist(data.aws_vpc.selected.cidr_block)))
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = compact(concat(var.egress_cidr_blocks, formatlist(data.aws_vpc.selected.cidr_block)))
  }
}

resource "aws_iam_service_linked_role" "opensearch" {
  count            = var.create_iam_service_linked_role_for_opensearch ? 1 : 0
  aws_service_name = "opensearchservice.amazonaws.com"
}


resource "aws_opensearch_domain" "opensearch_private" {
  count          = var.opensearch_public ? 0 : 1
  domain_name    = var.domain
  engine_version = var.opensearch_version
  depends_on     = [aws_iam_service_linked_role.opensearch]

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    zone_awareness_enabled = var.zone_awareness_enabled
    zone_awareness_config {
      availability_zone_count = var.availability_zone_count
    }
  }
  vpc_options {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.opensearch.id]
  }


  advanced_security_options {
    enabled                        = var.advanced_sg_enabled
    internal_user_database_enabled = var.internal_user_database_enabled

    master_user_options {
      master_user_name     = var.os_master_user_name
      master_user_password = local.os_creds.password
    }
  }

  access_policies = <<CONFIG
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": "es:*",
              "Principal": "*",
              "Effect": "Allow",
              "Resource": "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/*"
          }
      ]
  }
  CONFIG

  domain_endpoint_options {
    enforce_https       = var.os_enforce_https
    tls_security_policy = var.tls_security_policy
  }
  encrypt_at_rest {
    enabled = var.encrypt_at_rest
  }
  node_to_node_encryption {
    enabled = var.node_to_node_encryption
  }
  ebs_options {
    ebs_enabled = var.ebs_enabled
    volume_size = var.ebs_volume_size
    volume_type = var.volume_type
  }

  auto_tune_options {
    desired_state       = var.auto_tune_desired_state
    rollback_on_disable = var.auto_tune_rollback_on_disable
  }

  tags = merge(
    var.default_tags,
    {
    },
  )

}

resource "aws_opensearch_domain" "opensearch_public" {
  count          = var.opensearch_public ? 1 : 0
  domain_name    = var.domain
  engine_version = var.opensearch_version
  depends_on     = [aws_iam_service_linked_role.opensearch]

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    zone_awareness_enabled = var.zone_awareness_enabled
    zone_awareness_config {
      availability_zone_count = var.availability_zone_count
    }
  }

  advanced_security_options {
    enabled                        = var.advanced_sg_enabled
    internal_user_database_enabled = var.internal_user_database_enabled

    master_user_options {
      master_user_name     = var.os_master_user_name
      master_user_password = local.os_creds.password
    }
  }

  access_policies = <<CONFIG
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": "es:*",
              "Principal": "*",
              "Effect": "Allow",
              "Resource": "arn:aws:es:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:domain/${var.domain}/*"
          }
      ]
  }
  CONFIG

  domain_endpoint_options {
    enforce_https       = var.os_enforce_https
    tls_security_policy = var.tls_security_policy
  }
  encrypt_at_rest {
    enabled = var.encrypt_at_rest
  }
  node_to_node_encryption {
    enabled = var.node_to_node_encryption
  }
  ebs_options {
    ebs_enabled = var.ebs_enabled
    volume_size = var.ebs_volume_size
    volume_type = var.volume_type
  }

  auto_tune_options {
    desired_state       = var.auto_tune_desired_state
    rollback_on_disable = var.auto_tune_rollback_on_disable
  }

  tags = merge(
    var.default_tags,
    {
    },
  )

}

locals {
  opensearch_endpoint = var.opensearch_public ? aws_opensearch_domain.opensearch_public[0].endpoint : aws_opensearch_domain.opensearch_private[0].endpoint
}


# ###------Creates IAM roles for OpenSearch------####
# resource "null_resource" "create_role" {
#   depends_on = [
#     local.opensearch_endpoint,
#     aws_opensearch_domain.opensearch_private,
#     aws_opensearch_domain.opensearch_public,
#   ]
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = <<EOT
#            curl  -XPUT -u '${var.os_master_user_name}:${local.os_creds.password}' 'https://${local.opensearch_endpoint}/_opendistro/_security/api/roles/relay-audit' -k -H 'Content-Type: application/json' -d '{"cluster_permissions":["*"],"index_permissions":[{"index_patterns":["relay-audits*"],"allowed_actions":["*"]}]}'
#            if [ $? == 0 ]; then echo "Opensearch role creation Success !!!!!!"; else echo "Opensearch role creation Failure !!!!!!"; fi
#     EOT
#   }
# }

# resource "null_resource" "create_role_mapping" {
#   depends_on = [
#     local.opensearch_endpoint,
#     aws_opensearch_domain.opensearch_private,
#     aws_opensearch_domain.opensearch_public,
#   ]
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = <<EOT
#         curl -XPUT -u '${var.os_master_user_name}:${local.os_creds.password}' 'https://${local.opensearch_endpoint}/_opendistro/_security/api/rolesmapping/relay-audit' -k -H 'Content-Type: application/json' -d '{"backend_roles":["${var.kinesis_arn}"],"users":["${var.kinesis_arn}"]}'
#         if [ $? == 0 ]; then echo "Opensearch roleMapping creation Success !!!!!!"; else echo "Opensearch roleMapping creation Failure !!!!!!"; fi
#     EOT
#   }
# }

## Updates the existing policy
resource "null_resource" "updates_ism_policies" {
  count = var.update_policy ? 1 : 0
  triggers = {
    id  = var.HotState_MinSize,
    age = var.HotState_IndexAge
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
         curl  -XPUT -u '${var.os_master_user_name}:${local.os_creds.password}' 'https://${var.opensearch_public ? aws_opensearch_domain.opensearch_public[0].endpoint : aws_opensearch_domain.opensearch_private[0].endpoint}/_opendistro/_ism/policies/${var.policyid}?if_seq_no=${trim("${var.seq_no}", "\n")}&if_primary_term=${trim("${var.primary_term}", "\n")}' -k -H 'Content-Type: application/json' -d '{"policy":{"policy_id":"${var.policyid}","description":"hot-delete workflow policy to delete indices based on size and age.","default_state":"hot","states":[{"name":"hot","actions":[],"transitions":[{"state_name":"warm","conditions":{"min_size":"${var.HotState_MinSize}"}},{"state_name":"warm","conditions":{"min_index_age":"${var.HotState_IndexAge}"}}]},{"name":"warm","actions":[],"transitions":[{"state_name":"delete","conditions":{"min_index_age":"${var.WarmState_IndexAge}"}}]},{"name":"delete","actions":[{"delete":{}}],"transitions":[]}],"ism_template":[{"index_patterns":${jsonencode(var.index-patterns)},"priority":${var.priority}}]}}'
    EOT
  }
}