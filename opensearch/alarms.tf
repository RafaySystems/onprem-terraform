resource "aws_cloudwatch_metric_alarm" "OpenSearch_cpu_utilization_too_high" {
  alarm_name          = "${var.controllername}-cpu-utilization"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ES"
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = "Average OpenSearch CPU utilization over last 10 minutes too high"
  alarm_actions       = ["${var.sns_arn}"]
  ok_actions          = ["${var.sns_arn}"]

  dimensions = {
    DomainName = var.domain
  }
}

resource "aws_cloudwatch_metric_alarm" "OpenSearch_FreeStorageSpace" {
  alarm_name          = "${var.controllername}-cpu-utilization"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/ES"
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = "Average OpenSearch FreeStorageSpace over last 10 minutes"
  alarm_actions       = ["${var.sns_arn}"]
  ok_actions          = ["${var.sns_arn}"]

  dimensions = {
    DomainName = var.domain
  }
}

resource "aws_cloudwatch_metric_alarm" "OpenSearch_disk_queue_depth_too_high" {
  alarm_name          = "${var.controllername}-disk_queue"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = "DiskQueueDepth"
  namespace           = "AWS/ES"
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = "Average OpenSearch disk queue depth over last 10 minutes too high"
  alarm_actions       = ["${var.sns_arn}"]
  ok_actions          = ["${var.sns_arn}"]

  dimensions = {
    DomainName = var.domain
  }
}