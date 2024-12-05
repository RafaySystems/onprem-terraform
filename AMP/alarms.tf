resource "aws_cloudwatch_metric_alarm" "amp_notifications_failed" {
  alarm_name          = "${var.controllername}-notifications-failed"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = "AlertManagerNotificationsFailed"
  namespace           = "AWS/Prometheus"
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = "Alert Manager Notifications failed"
  alarm_actions       = ["${var.sns_arn}"]
  ok_actions          = ["${var.sns_arn}"]

  dimensions = {
    Workspace = aws_prometheus_workspace.prod_eks_metrics.id
  }
}

resource "aws_cloudwatch_metric_alarm" "amp_notifications_throttled" {
  alarm_name          = "${var.controllername}-notifications-throttled"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = "AlertManagerNotificationsThrottled"
  namespace           = "AWS/Prometheus"
  period              = var.period
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Average database swap usage over last 10 minutes too high, performance may suffer"
  alarm_actions       = ["${var.sns_arn}"]
  ok_actions          = ["${var.sns_arn}"]

  dimensions = {
    Workspace = aws_prometheus_workspace.prod_eks_metrics.id
  }
}