#####------------------render config yaml file------------------#####
resource "local_file" "import_cluster_yaml" {
  content = templatefile("${path.module}/templates/config.tftpl", {
    controllerName                   = "${var.controllerName}",
    deploymentType                   = "${var.deploymentType}",
    external-database                = "${var.external-database}",
    rds_hostname                     = "${var.rds_hostname}",
    rds_port                         = "${var.rds_port}",
    amp-enabled                      = "${var.amp-enabled}",
    ingest_role_arn                  = "${var.amp_ingest_role_arn}",
    query_role_arn                   = "${var.amp_query_role_arn}",
    region                           = "${var.region}",
    workspace_id                     = "${var.amp_workspace_id}",
    path                             = "${var.path}",
    logo_path                        = "${var.logo_path}",
    generate-self-signed-certs       = "${var.generate-self-signed-certs}",
    console-certificate              = "${var.console-certificate}",
    console-key                      = "${var.console-key}",
    super_user                       = "${var.super_user}",
    super_user_password              = "${var.super_user_password}",
    domain_name                      = "${var.domain_name}",
    partner_name                     = "${var.partner_name}",
    product_name                     = "${var.product_name}",
    help-desk-email                  = "${var.help-desk-email}",
    notifications-email              = "${var.notifications-email}",
    enable_hosted_dns_server         = "${var.enable_hosted_dns_server}",
    external_lb                      = "${var.external_lb}",
    loadBalancerType                 = "${var.loadBalancerType}"
    cert_acm                         = "${var.cert_acm}",
    cluster_name                     = "${var.cluster_name}",
    use_instance_role                = "${var.use_instance_role}",
    irsa_instance_iam_role_arn       = "${var.irsa_instance_iam_role_arn}"
    aws_account_id                   = "${var.aws_account_id}",
    aws_access_key_id                = "${var.aws_access_key}",
    aws_secret_access_key            = "${var.aws_secret_key}",
    file_system_id                   = "${var.aws_efs_fs_id}",
    iam_role_arn                     = "${var.efs_iam_role_arn}",
    karpenter-enabled                = "${var.karpenter-enabled}",
    cluster_endpoint                 = "${var.cluster_endpoint}",
    kapenter_role_arn                = "${var.kapenter_role_arn}",
    external_dns_enabled             = "${var.external-dns-enabled}",
    external_dns_role_arn            = "${var.external-dns-role_arn}",
    externalDnsHostedZoneID          = "${var.externalDnsHostedZoneID}",
    velero_enabled                   = "${var.backup-restore-enabled}",
    velero_role_arn                  = "${var.backup-restore-role_arn}",
    veleroSchedule                   = "${var.backup-restoreSchedule}",
    velero_bucket_name               = "${var.backup-restore-bucket_name}",
    velero_restore                   = "${var.backup-restore}",
    kinesis_firehose_delivery_stream = "${var.kinesis-firehose-delivery-stream}",
    kinesis_firehose_role_arn        = "${var.kinesis-firehose-role-arn}",
    opensearchEnabled                = "${var.opensearchEnabled}",
    opensearch_endpoint              = "${var.opensearch-endpoint}",
    opensearch_user_name             = "${var.opensearch-user-name}",
    opensearch_user_password         = "${var.opensearch-user-password}",
    subnet_ids                       = join(" ", [for s in var.subnet_id : trim(format("%q", s), "\"")]),
    minReplicaCount                  = "${var.minReplicaCount}"
    kinesis_firehose_logsstreams     = "${var.logsstream_name}"
    kinesis_firehose_logsrole_arn    = "${var.kinesis_firehose_logsrole_arn}"
    RetentionPeriod                  = "${var.RetentionPeriod}"
    BackupFolderName                 = "${var.BackupFolderName}"
    istioVersion                     = "${var.istioVersion}"
    ecr_aws_access_key_id            = var.ecr_aws_access_key_id
    ecr_aws_secret_access_key        = var.ecr_aws_secret_access_key
    aws-ecr-endpoint                 = var.aws-ecr-endpoint
    jfrog_user_name                  = var.jfrog_user_name
    jfrog_password                   = var.jfrog_password
    ecr_aws_irsa_role                = var.ecr_aws_irsa_role
    tar-extract-path                 = var.tar-extract-path
    jfrog_endpoint                   = var.jfrog_endpoint
    proxy_host                       = var.proxy_host
    proxy_ip                         = var.proxy_ip
    proxy_port                       = var.proxy_port
    proxy_no-proxy                   = var.no-proxy
    irsa_role_enabled                = var.irsa_role_enabled
    lb_controller_role_arn           = var.lb_controller_role_arn
    lb_controller_clusterName        = var.lb_controller_clusterName
    tsdb_backup_bucket               = var.tsdb_backup_bucket
    tsdb_backup_role_arn             = var.tsdb_backup_role_arn
    deploymentSize                   = var.deploymentSize
    external_logging_enabled         = var.external_logging_enabled
    external_logging_endpoint        = var.external_logging_endpoint
    external_logging_user_name       = var.external_logging_user_name
    external_logging_user_password   = var.external_logging_user_password
    external_metrics_enabled         = var.external_metrics_enabled
    jfrog_insecure                   = var.jfrog_insecure
    blueprintVersion                 = var.blueprintVersion
    rafay_registry_type              = var.rafay_registry_type
    tsdb_backup_enabled              = var.tsdb_backup_enabled
    engine_api_blob_provider         = var.engine_api_blob_provider
    engine_api_blob_bucket           = var.engine_api_blob_bucket
    engine_api_region                = var.region
    engine_api_irsa_role_arn         = var.engine_api_irsa_role_arn
    registry_subpath                 = var.registry_subpath
    resticEnable                     = var.resticEnable
  })
  filename = "${var.path}/config.yaml"
}


#####------------------Download required tools to radm application------------------#####

/* resource "null_resource" "download_controller_package" {
  depends_on = [
    local_file.import_cluster_yaml,
  ]

  triggers = {
    id = var.controllerVersion
  }

  provisioner "local-exec" {
    command     = "mkdir -p ${var.path} && curl -s ${var.controllerRepoUrl}/${var.controllerVersion}.tar.gz | tar xzvf - -C ${var.path}/"
    interpreter = ["/bin/bash", "-c"]
  }
} */

resource "null_resource" "download_controller_package" {
  depends_on = [
    local_file.import_cluster_yaml,
  ]

  triggers = {
    id = var.controllerVersion
  }

  provisioner "local-exec" {
    command     = "mkdir -p ${var.path} && cd ${var.path} && aria2c -x 8 ${var.controllerRepoUrl}/${var.controllerVersion}.tar.gz && sleep 30 && tar -I pigz -xvf ${var.controllerVersion}.tar.gz"
    interpreter = ["/bin/bash", "-c"]
  }
}

# resource "null_resource" "download_radm" {
#   depends_on = [
#     null_resource.download_controller_package,
#     local_file.import_cluster_yaml,
#   ]
#   triggers = {
#     id = var.controllerVersion
#   }
#   provisioner "local-exec" {
#     command     = "if [[ $(uname) == \"Darwin\" ]]; then curl -O https://dev-rafay-controller.s3.us-west-1.amazonaws.com/radm/darwin/radm-${var.RadmVersion} && chmod +x $PWD/radm-${var.RadmVersion} && mv $PWD/radm-${var.RadmVersion} ${var.path}/radm && alias radm=${var.path}/radm; else curl -O https://dev-rafay-controller.s3.us-west-1.amazonaws.com/radm/linux/radm-${var.RadmVersion} && chmod +x $PWD/radm-${var.RadmVersion} && mv $PWD/radm-${var.RadmVersion} ${var.path}/radm && alias radm=${var.path}/radm; fi"
#     interpreter = ["/bin/bash", "-c"]
#   }
# }

resource "time_sleep" "sleepfor1m" {
  depends_on = [
    #null_resource.download_radm,
    null_resource.download_controller_package,
    local_file.import_cluster_yaml,
  ]
  triggers = {
    id = var.controllerVersion
  }
  create_duration = "1m"
}

resource "null_resource" "checkForFiles" {
  depends_on = [
    #null_resource.download_radm,
    local_file.import_cluster_yaml,
    null_resource.download_controller_package,
    time_sleep.sleepfor1m,
  ]

  triggers = {
    id = var.controllerVersion
  }
  provisioner "local-exec" {
    command     = "if [[ -f \"${var.path}/radm\" && -f \"${var.path}/rafay-core.tar.gz\" && -f \"${var.path}/rafay-dep.tar.gz\" && -f \"${var.path}/rafay-cluster-assets.tar.gz\" && -f \"${var.path}/rafay-cluster-images.tar.gz\" ]]; then echo 'All Files Exists !!!!!'; else echo 'Some Files are Missing !!!!!'; exit 1; fi"
    interpreter = ["/bin/bash", "-c"]
  }
}

# ####---------------EXECUTES RADM Database COMMAND-------------#####

resource "null_resource" "execute-radm-database" {
  count = var.run_only_infra ? 0 : (var.rds_password != "" ? 1 : 0)
  depends_on = [
    #null_resource.download_radm,
    local_file.import_cluster_yaml,
    null_resource.download_controller_package,
    time_sleep.sleepfor1m,
    null_resource.checkForFiles,
  ]
  triggers = {
    id = var.controllerVersion
  }
  provisioner "local-exec" {
    command     = "${var.path}/radm database --host ${var.rds_hostname} --kubeconfig ${var.path}/${var.cluster_name}-kubeconfig --port ${var.rds_port} --root-password '${var.rds_password}' --root-user ${var.rds_username}"
    interpreter = ["/bin/bash", "-c"]
  }
}

# ####---------------EXECUTES RADM DEPENDENCY COMMAND-------------#####
resource "null_resource" "execute-radm-dependency" {
  count = var.run_only_infra ? 0 : 1
  depends_on = [
    #null_resource.download_radm,
    null_resource.execute-radm-database,
    local_file.import_cluster_yaml,
    null_resource.download_controller_package,
    time_sleep.sleepfor1m,
    null_resource.checkForFiles,

  ]
  triggers = {
    id = var.controllerVersion
  }
  provisioner "local-exec" {
    command     = "${var.path}/radm dependency --config ${var.path}/config.yaml --kubeconfig ${var.path}/${var.cluster_name}-kubeconfig"
    interpreter = ["/bin/bash", "-c"]
  }
}

####---------------EXECUTES RADM APPLICATION COMMAND-------------#####
resource "null_resource" "execute-radm-application" {
  count = var.run_only_infra ? 0 : 1
  depends_on = [
    #null_resource.download_radm,
    null_resource.execute-radm-dependency,
    local_file.import_cluster_yaml,
    null_resource.download_controller_package,
    time_sleep.sleepfor1m,
    null_resource.execute-radm-database,
    null_resource.checkForFiles,
  ]
  triggers = {
    id = var.controllerVersion
  }
  provisioner "local-exec" {
    command     = "${var.path}/radm application --config ${var.path}/config.yaml --kubeconfig ${var.path}/${var.cluster_name}-kubeconfig"
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "deletepods" {
  count = var.backup-restore ? 1 : 0
  depends_on = [
    null_resource.execute-radm-dependency,
    local_file.import_cluster_yaml,
    null_resource.download_controller_package,
    time_sleep.sleepfor1m,
    null_resource.execute-radm-database,
    null_resource.checkForFiles,
    null_resource.execute-radm-application,
  ]
  provisioner "local-exec" {
    command     = "kubectl delete po --all -n rafay-core --kubeconfig ${var.path}/${var.cluster_name}-kubeconfig"
    interpreter = ["/bin/bash", "-c"]
  }
}

# ####---------------Waiting for all pods to come up-------------#####
resource "time_sleep" "WaitForPodsToComeUp" {
  count = var.run_only_infra ? 0 : 1
  depends_on = [
    #null_resource.download_radm,
    null_resource.execute-radm-dependency,
    null_resource.execute-radm-application,
    local_file.import_cluster_yaml,
    time_sleep.sleepfor1m,
    null_resource.execute-radm-database,
    null_resource.download_controller_package,
    null_resource.checkForFiles,
  ]
  triggers = {
    id = var.controllerVersion
  }
  create_duration = "5m"
}


####---------------EXECUTES RADM CLUSTER COMMAND-------------#####
resource "null_resource" "execute-radm-cluster" {
  count = var.run_only_infra ? 0 : 1
  depends_on = [
    #null_resource.download_radm,
    null_resource.execute-radm-dependency,
    null_resource.execute-radm-application,
    local_file.import_cluster_yaml,
    time_sleep.sleepfor1m,
    time_sleep.WaitForPodsToComeUp,
    null_resource.execute-radm-database,
    null_resource.download_controller_package,
    null_resource.checkForFiles,
    null_resource.deletepods,
  ]
  triggers = {
    id = var.controllerVersion
  }
  provisioner "local-exec" {
    command     = "${var.path}/radm cluster --config ${var.path}/config.yaml --kubeconfig ${var.path}/${var.cluster_name}-kubeconfig"
    interpreter = ["/bin/bash", "-c"]
  }
}
