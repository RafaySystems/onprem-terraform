###----CREATES AMAZON MANAGED PROMETHEUS----####
resource "aws_prometheus_workspace" "prod_eks_metrics" {
  alias = var.prometheus_workspace_alias

  tags = merge(
    var.default_tags,
    {

    },
  )
}

resource "aws_prometheus_alert_manager_definition" "alertmanager_config" {
  workspace_id = aws_prometheus_workspace.prod_eks_metrics.id
  definition   = <<EOF
alertmanager_config: |
  global:
    resolve_timeout: 24h
  route:
    receiver: 'default'
    group_interval: 20m
    group_wait: 1m
    repeat_interval: 2h
    routes:
    - receiver: 'default' 
      group_by:
        - server
        - team
        - alertname
        - alertNameAlias
        - edge_name
        - node
        - pod
        - priority
        - severity
  receivers:
    - name: 'default'
      sns_configs:
      - topic_arn: ${var.sns_arn}
        send_resolved: true
        subject: '{{ if .CommonAnnotations.summary }}Alert-{{ .Status }} ${var.controllername}-{{ .CommonAnnotations.summary }}{{ else }}Alert-{{ .Status }} ${var.controllername}-{{ .CommonLabels.alertname }}{{ end }}'
        sigv4:
          region: ${var.region}
        attributes:
          key: severity
          value: "{{ .CommonLabels.severity }}"        
        message: |
          Summary: {{ if .CommonAnnotations.summary }}{{ .CommonAnnotations.summary }}{{ else }}{{ .CommonLabels.alertname }}{{ end }}
          Controller_Name: ${var.controllername}
          Alert_Status: "{{ .Status }}"
          Alert_Name: {{ .CommonLabels.alertname }}
          Severity: {{ .CommonLabels.severity }}
          Namespace: {{ .CommonLabels.namespace }} 
          {{ if .CommonLabels.instance  -}}  
          Instance: {{ .CommonLabels.instance }}
          {{ end -}}          
          {{ if .GroupLabels.node -}}  
          Node: {{ .GroupLabels.node }}
          {{ end -}}
          {{ if .GroupLabels.edge_name -}}
          Cluster: {{ .GroupLabels.edge_name }}
          {{ end -}}
          Labels:
          {{ range $alertIndex, $alerts := .Alerts -}}
          {{ if eq $alertIndex 0 -}}
          {{ range $index, $label := $alerts.Labels.SortedPairs -}}
            {{ "-" }} {{ $label.Name }}: {{ $label.Value }} 
          {{ end -}} 
          {{ end -}}
          {{ end -}} 
EOF
}

resource "aws_prometheus_rule_group_namespace" "rules" {
  name         = "${var.eks_cluster_name}-PrometheusRules"
  workspace_id = aws_prometheus_workspace.prod_eks_metrics.id
  data         = <<EOF
groups:
  - name: cluster-alerts-v2
    rules:
      - alert: NodeHighCpuLoad
        annotations:
          description: 'Node {{ $labels.instance }} is on High Cpu Load'
          summary: Node {{ $labels.instance }} is on High Cpu Load
        expr: |
          (((sum by(node) ((rate(node_cpu_seconds_total{mode!="idle"}[1m])) * on(namespace, pod) group_left(node) node_namespace_pod:kube_pod_info:)) / sum by(node) (kube_node_status_capacity{resource="cpu",unit="core"})) * 100) > 90
        for: 5m
        labels:
          severity: critical      
      - alert: NodeHighMemLoad
        annotations:
          description: 'Node {{ $labels.instance }} is on High Memory Load'
          summary: Node {{ $labels.instance }} is on High Memory Load
        expr: |
          (((((node_memory_MemTotal_bytes - (node_memory_MemAvailable_bytes)) / node_memory_MemTotal_bytes) * on (namespace, pod) group_left(node) node_namespace_pod:kube_pod_info:)) * 100) > 80
        for: 5m
        labels:
          severity: critical     
      - alert: NodeDiskUsagePrediction 
        annotations:
          description: 'Node Disk Usage Prediction'
          summary: Node {{ $labels.instance }} Disk is in Usage Prediction
        expr: (predict_linear(node_filesystem_free_bytes{fstype!~"tmpfs"}[3h], 24 * 3600) * on (namespace, pod) group_left(node) node_namespace_pod:kube_pod_info:) < 0
        for: 5m
        labels:
          severity: warning
      - alert: NodeUnhealthy
        annotations:
          description: 'Node is in Unhealthy state'
          summary: Node is in Unhealthy state
        expr: (max by(node, pod, status, condition) (kube_node_status_condition{condition!="Ready", status="true"})) > 0
        for: 5m
        labels:
          severity: critical
      - alert: NodeDown
        annotations:
          description: '{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes.'
          summary: Instance {{ $labels.instance }} down
        expr: (max by(node, pod, status, condition) (kube_node_status_condition{condition!="Ready", status="unknown"})) > 0
        for: 5m
        labels:
          severity: warning
      - alert: PodOOMKilled 
        annotations:
          description: 'PodOOMKilled'
          summary: Kubernetes pod oomkilled (instance {{ $labels.instance }})
        expr: sum by(node, namespace, pod, label_rep_workload) ((kube_pod_container_status_terminated_reason{reason="OOMKilled"} * on(namespace, pod) group_left(node) kube_pod_info) * on (namespace, pod) group_left(label_rep_workload) kube_pod_labels) > 0
        for: 30s
        labels:
          severity: critical
      - alert: PodEvicted 
        annotations:
          description: 'Pod Evicted'
          summary: Kubernetes pod evicted (instance {{ $labels.instance }})
        expr: sum by(node, namespace, pod, label_rep_workload) ((kube_pod_status_reason{reason="Evicted"} * on(namespace, pod) group_left(node) kube_pod_info)* on (namespace, pod) group_left(label_rep_workload) kube_pod_labels) > 0
        for: 30s
        labels:
          severity: critical
      - alert: PodPending
        annotations:
          description: 'Pod is in pending state for more thaen 5m'
          summary: Kubernetes pod pending (instance {{ $labels.instance }})
        expr: sum by(node, namespace, pod, label_rep_workload) ((kube_pod_status_phase{phase="Pending"} * on(namespace, pod) group_left(node) kube_pod_info) * on (namespace, pod) group_left(label_rep_workload) kube_pod_labels) > 0
        for: 5m
        labels:
          severity: critical
      - alert: FrequentPodRestart 
        annotations:
          description: 'Frequent Pod Restart'
          summary: Kubernetes pod Frequent Pod Restart (instance {{ $labels.instance }})
        expr: ((rate(kube_pod_container_status_restarts_total[1h]) * 60 * 60 > 3) * on(namespace, pod) group_left(node) kube_pod_info) * on (namespace, pod) group_left(label_rep_workload) kube_pod_labels
        for: 5m
        labels:
          severity: critical  
      - alert: PodWaiting 
        annotations:
          description: 'Pod is in waiting state for more than 5m'
          summary: Kubernetes pod waiting (instance {{ $labels.instance }})
        expr: sum by(node, namespace, pod, label_rep_workload, reason) ((kube_pod_container_status_waiting_reason * on (namespace, pod) group_left(label_rep_workload) kube_pod_labels) * on(namespace, pod) group_left(node) kube_pod_info) > 0
        for: 5m
        labels:
          severity: critical
  - name: kubernetes 
    rules:           
      - alert: KubernetesNodeReady
        expr: kube_node_status_condition{condition="Ready",status="true"} == 0
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes Node ready (instance {{ $labels.instance }})
          description: "Node {{ $labels.node }} has been unready for a long time\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesMemoryPressure
        expr: kube_node_status_condition{condition="MemoryPressure",status="true"} == 1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes memory pressure (instance {{ $labels.instance }})
          description: "{{ $labels.node }} has MemoryPressure condition\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesDiskPressure
        expr: kube_node_status_condition{condition="DiskPressure",status="true"} == 1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes disk pressure (instance {{ $labels.instance }})
          description: "{{ $labels.node }} has DiskPressure condition\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesOutOfDisk
        expr: kube_node_status_condition{condition="OutOfDisk",status="true"} == 1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes out of disk (instance {{ $labels.instance }})
          description: "{{ $labels.node }} has OutOfDisk condition\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesOutOfCapacity
        expr: sum by (node) ((kube_pod_status_phase{phase="Running"} == 1) + on(uid) group_left(node) (0 * kube_pod_info{pod_template_hash=""})) / sum by (node) (kube_node_status_allocatable{resource="pods"}) * 100 > 90
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes out of capacity (instance {{ $labels.instance }})
          description: "{{ $labels.node }} is out of capacity\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesContainerOomKiller
        expr: (kube_pod_container_status_restarts_total - kube_pod_container_status_restarts_total offset 10m >= 1) and ignoring (reason) min_over_time(kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}[10m]) == 1
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes container oom killer (instance {{ $labels.instance }})
          description: "Container {{ $labels.container }} in pod {{ $labels.namespace }}/{{ $labels.pod }} has been OOMKilled {{ $value }} times in the last 10 minutes.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesJobFailed
        expr: kube_job_status_failed > 0
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes Job failed (instance {{ $labels.instance }})
          description: "Job {{$labels.namespace}}/{{$labels.exported_job}} failed to complete\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesCronjobSuspended
        expr: kube_cronjob_spec_suspend != 0
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes CronJob suspended (instance {{ $labels.instance }})
          description: "CronJob {{ $labels.namespace }}/{{ $labels.cronjob }} is suspended\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesPersistentvolumeclaimPending
        expr: kube_persistentvolumeclaim_status_phase{phase="Pending"} == 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes PersistentVolumeClaim pending (instance {{ $labels.instance }})
          description: "PersistentVolumeClaim {{ $labels.namespace }}/{{ $labels.persistentvolumeclaim }} is pending\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesVolumeOutOfDiskSpace
        expr: kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes * 100 < 10
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes Volume out of disk space (instance {{ $labels.instance }})
          description: "Volume is almost full (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesVolumeFullInFourDays
        expr: predict_linear(kubelet_volume_stats_available_bytes[6h], 4 * 24 * 3600) < 0
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes Volume full in four days (instance {{ $labels.instance }})
          description: "{{ $labels.namespace }}/{{ $labels.persistentvolumeclaim }} is expected to fill up within four days. Currently {{ $value | humanize }}% is available.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesPersistentvolumeError
        expr: kube_persistentvolume_status_phase{phase=~"Failed|Pending", job="kube-state-metrics"} > 0
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes PersistentVolume error (instance {{ $labels.instance }})
          description: "Persistent volume is in bad state\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesStatefulsetDown
        expr: (kube_statefulset_status_replicas_ready / kube_statefulset_status_replicas_current) != 1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes StatefulSet down (instance {{ $labels.instance }})
          description: "A StatefulSet went down\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesHpaScalingAbility
        expr: kube_horizontalpodautoscaler_status_condition{status="false", condition="AbleToScale"} == 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes HPA scaling ability (instance {{ $labels.instance }})
          description: "Pod is unable to scale\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesHpaMetricAvailability
        expr: kube_horizontalpodautoscaler_status_condition{status="false", condition="ScalingActive"} == 1
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes HPA metric availability (instance {{ $labels.instance }})
          description: "HPA is not able to collect metrics\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesHpaScaleCapability
        expr: kube_horizontalpodautoscaler_status_desired_replicas >= kube_horizontalpodautoscaler_spec_max_replicas
        for: 2m
        labels:
          severity: info
        annotations:
          summary: Kubernetes HPA scale capability (instance {{ $labels.instance }})
          description: "The maximum number of desired Pods has been hit\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
  - name: kubernetes-resources
    rules:           
      - alert: KubernetesPodNotHealthy
        expr: min_over_time(sum by (namespace, pod) (kube_pod_status_phase{phase=~"Pending|Unknown|Failed"})[15m:1m]) > 0
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes Pod not healthy (instance {{ $labels.instance }})
          description: "Pod has been in a non-ready state for longer than 15 minutes.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesPodCrashLooping
        expr: increase(kube_pod_container_status_restarts_total[1m]) > 3
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes pod crash looping (instance {{ $labels.instance }})
          description: "Pod {{ $labels.pod }} is crash looping\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesReplicassetMismatch
        expr: kube_replicaset_spec_replicas != kube_replicaset_status_ready_replicas
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes ReplicasSet mismatch (instance {{ $labels.instance }})
          description: "Deployment Replicas mismatch\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesDeploymentReplicasMismatch
        expr: kube_deployment_spec_replicas != kube_deployment_status_replicas_available
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes Deployment replicas mismatch (instance {{ $labels.instance }})
          description: "Deployment Replicas mismatch\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesStatefulsetReplicasMismatch
        expr: kube_statefulset_status_replicas_ready != kube_statefulset_status_replicas
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes StatefulSet replicas mismatch (instance {{ $labels.instance }})
          description: "A StatefulSet does not match the expected number of replicas.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesDeploymentGenerationMismatch
        expr: kube_deployment_status_observed_generation != kube_deployment_metadata_generation
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes Deployment generation mismatch (instance {{ $labels.instance }})
          description: "A Deployment has failed but has not been rolled back.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesStatefulsetGenerationMismatch
        expr: kube_statefulset_status_observed_generation != kube_statefulset_metadata_generation
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes StatefulSet generation mismatch (instance {{ $labels.instance }})
          description: "A StatefulSet has failed but has not been rolled back.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesStatefulsetUpdateNotRolledOut
        expr: max without (revision) (kube_statefulset_status_current_revision unless kube_statefulset_status_update_revision) * (kube_statefulset_replicas != kube_statefulset_status_replicas_updated)
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes StatefulSet update not rolled out (instance {{ $labels.instance }})
          description: "StatefulSet update has not been rolled out.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesDaemonsetRolloutStuck
        expr: kube_daemonset_status_number_ready / kube_daemonset_status_desired_number_scheduled * 100 < 100 or kube_daemonset_status_desired_number_scheduled - kube_daemonset_status_current_number_scheduled > 0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes DaemonSet rollout stuck (instance {{ $labels.instance }})
          description: "Some Pods of DaemonSet are not scheduled or not ready\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesDaemonsetMisscheduled
        expr: kube_daemonset_status_number_misscheduled > 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes DaemonSet misscheduled (instance {{ $labels.instance }})
          description: "Some DaemonSet Pods are running where they are not supposed to run\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesCronjobTooLong
        expr: time() - kube_cronjob_next_schedule_time > 3600
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes CronJob too long (instance {{ $labels.instance }})
          description: "CronJob {{ $labels.namespace }}/{{ $labels.cronjob }} is taking more than 1h to complete.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesJobSlowCompletion
        expr: kube_job_spec_completions - kube_job_status_succeeded > 0
        for: 12h
        labels:
          severity: critical
        annotations:
          summary: Kubernetes job slow completion (instance {{ $labels.instance }})
          description: "Kubernetes Job {{ $labels.namespace }}/{{ $labels.job_name }} did not complete in time.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesApiServerErrors
        expr: sum(rate(apiserver_request_total{job="apiserver",code=~"^(?:5..)$"}[1m])) / sum(rate(apiserver_request_total{job="apiserver"}[1m])) * 100 > 3
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes API server errors (instance {{ $labels.instance }})
          description: "Kubernetes API server is experiencing high error rate\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesApiClientErrors
        expr: (sum(rate(rest_client_requests_total{code=~"(4|5).."}[1m])) by (instance, job) / sum(rate(rest_client_requests_total[1m])) by (instance, job)) * 100 > 1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes API client errors (instance {{ $labels.instance }})
          description: "Kubernetes API client is experiencing high error rate\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesClientCertificateExpiresNextWeek
        expr: apiserver_client_certificate_expiration_seconds_count{job="apiserver"} > 0 and histogram_quantile(0.01, sum by (job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job="apiserver"}[5m]))) < 7*24*60*60
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes client certificate expires next week (instance {{ $labels.instance }})
          description: "A client certificate used to authenticate to the apiserver is expiring next week.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesClientCertificateExpiresSoon
        expr: apiserver_client_certificate_expiration_seconds_count{job="apiserver"} > 0 and histogram_quantile(0.01, sum by (job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job="apiserver"}[5m]))) < 24*60*60
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes client certificate expires soon (instance {{ $labels.instance }})
          description: "A client certificate used to authenticate to the apiserver is expiring in less than 24.0 hours.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      - alert: KubernetesApiServerLatency
        expr: histogram_quantile(0.99, sum(rate(apiserver_request_latencies_bucket{subresource!="log",verb!~"^(?:CONNECT|WATCHLIST|WATCH|PROXY)$"} [10m])) WITHOUT (instance, resource)) / 1e+06 > 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes API server latency (instance {{ $labels.instance }})
          description: "Kubernetes API server has a 99th percentile latency of {{ $value }} seconds for {{ $labels.verb }} {{ $labels.resource }}.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
EOF
}


###----------IAM ROLES FOR AMP-----------####
data "aws_caller_identity" "this" {}
data "aws_region" "this" {}
data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

locals {
  oidc_provider = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

###---CREATES INGEST IAM ROLE FOR AMP---###
data "aws_iam_policy_document" "remote_write_assume" {
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
        "system:serviceaccount:istio-system:prometheus",
        "system:serviceaccount:rafay-core:rafay-core-kube-prometheus-prometheus",
        "system:serviceaccount:rafay-core:sigv4-proxy-sa"
      ]
    }
  }
}

resource "aws_iam_role" "amp-iamproxy-ingest-role" {
  name               = var.ingest_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.remote_write_assume.json
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_role_policy_attachment" "amp_write" {
  role       = aws_iam_role.amp-iamproxy-ingest-role.name
  policy_arn = var.IRSA_AMP_Policy
}

###---CREATES QUERY IAM ROLE FOR AMP---###
data "aws_iam_policy_document" "query_write_assume" {
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
      values   = ["system:serviceaccount:rafay-core:frontend-sa"]
    }
  }
}

resource "aws_iam_role" "amp-iamproxy-query-role" {
  name               = var.query_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.query_write_assume.json
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_policy" "AMPQueryPolicy" {
  name = var.query_iam_policy_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole",
          "aps:QueryMetrics",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ],
        "Resource" : "*"
      }
    ]
  })
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_role_policy_attachment" "AMPQueryPolicy" {
  role       = aws_iam_role.amp-iamproxy-query-role.name
  policy_arn = aws_iam_policy.AMPQueryPolicy.arn
}
