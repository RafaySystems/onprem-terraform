### ----------------------------------------------------------
#  Creates ISM Policy managed Indices in Opensearch
### ----------------------------------------------------------
resource "null_resource" "creates_ism_policy" {
  count = var.opensearchEnabled ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
         curl  -XPUT -u '${var.os_master_user_name}:${(module.opensearch_domain[0].opensearch_password)}' 'https://${module.opensearch_domain[0].endpoint}/_opendistro/_ism/policies/${var.policyid}' -k -H 'Content-Type: application/json' -d '{"policy":{"policy_id":"${var.policyid}","description":"hot-delete workflow policy to delete indices based on size and age.","default_state":"hot","states":[{"name":"hot","actions":[],"transitions":[{"state_name":"warm","conditions":{"min_size":"${var.HotState_MinSize}"}},{"state_name":"warm","conditions":{"min_index_age":"${var.HotState_IndexAge}"}}]},{"name":"warm","actions":[],"transitions":[{"state_name":"delete","conditions":{"min_index_age":"${var.WarmState_IndexAge}"}}]},{"name":"delete","actions":[{"delete":{}}],"transitions":[]}],"ism_template":[{"index_patterns":${jsonencode(var.index-patterns)},"priority":${var.priority}}]}}'
    EOT
  }
}

resource "null_resource" "to-get-seqno" {
  count = var.opensearchEnabled ? 1 : 0
  depends_on = [
    null_resource.creates_ism_policy
  ]
  triggers = {
    id  = var.HotState_MinSize,
    age = var.HotState_IndexAge
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        curl -XGET -u '${var.os_master_user_name}:${(module.opensearch_domain[0].opensearch_password)}' "https://${module.opensearch_domain[0].endpoint}/_opendistro/_ism/policies/${var.policyid}" | awk -F "," '{print $3}'  | cut -d ":" -f2 > seqno.txt
    EOT
  }
}

resource "null_resource" "to-get-primaryterm" {
  count = var.opensearchEnabled ? 1 : 0
  depends_on = [
    null_resource.creates_ism_policy
  ]
  triggers = {
    id  = var.HotState_MinSize,
    age = var.HotState_IndexAge
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
          curl -XGET -u '${var.os_master_user_name}:${(module.opensearch_domain[0].opensearch_password)}' "https://${module.opensearch_domain[0].endpoint}/_opendistro/_ism/policies/${var.policyid}" | awk -F "," '{print $4}'  | cut -d ":" -f2 > primaryterm.txt
      EOT
  }
}

### Creates ISM policies For debug core logs
resource "null_resource" "creates_debug_core_policy" {
  count = var.opensearchEnabled ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
         curl -XPUT -u "${var.os_master_user_name}:${module.opensearch_domain[0].opensearch_password}" \
  "https://${module.opensearch_domain[0].endpoint}/_opendistro/_ism/policies/${var.debug_core_policyid}" \
  -k \
  -H "Content-Type: application/json" \
  -d '{
    "policy": {
      "policy_id": "${var.debug_core_policyid}",
      "description": "hot-delete workflow policy to delete indices based on size and age.",
      "default_state": "hot",
      "states": [
        {
          "name": "hot",
          "actions": [],
          "transitions": [
            {
              "state_name": "warm",
              "conditions": {
                "min_index_age": "${var.debug_core_HotState_IndexAge}"
              }
            }
          ]
        },
        {
          "name": "warm",
          "actions": [],
          "transitions": [
            {
              "state_name": "delete",
              "conditions": {
                "min_index_age": "${var.debug_core_WarmState_IndexAge}"
              }
            }
          ]
        },
        {
          "name": "delete",
          "actions": [
            {
              "delete": {}
            }
          ],
          "transitions": []
        }
      ],
      "ism_template": [
        {
          "index_patterns": ${jsonencode(var.debug_core_index)},
          "priority": ${var.priority}
        }
      ]
    }
  }'
  EOT
  }
}

resource "null_resource" "creates_index_template" {
  count = var.opensearchEnabled ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
       curl -XPUT -u '${var.os_master_user_name}:${module.opensearch_domain[0].opensearch_password}' 'https://${module.opensearch_domain[0].endpoint}/_index_template/template_debug' -k -H 'Content-Type: application/json' -d '{ "index_patterns":["debug-core*"],"template":{"settings":{"index.codec":"best_compression","index.refresh_interval":"5s","index.number_of_shards":1,"index.query.default_field":"querystring","index.routing.allocation.total_shards_per_node":1},"mappings":{"_source":{"enabled": true},"properties":{"@timestamp":{"type":"date","index":true}}}},"priority":1,"version":1,"_meta":{"description":"Template for debug indices"}}'
    EOT
  }
}

resource "null_resource" "creates_alias" {
  count = var.opensearchEnabled ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
       curl -XPOST -u '${var.os_master_user_name}:${module.opensearch_domain[0].opensearch_password}' 'https://${module.opensearch_domain[0].endpoint}/_aliases' -H 'Content-Type: application/json' -d '{"actions":[{"add":{"index": "debug-core-000001","alias": "debug-core","is_write_index": true}}]}'
    EOT
  }
}