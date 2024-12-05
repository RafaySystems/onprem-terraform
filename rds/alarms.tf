resource "aws_cloudwatch_metric_alarm" "cpu_utilization_too_high" {
  alarm_name          = "${var.controllername}-cpu-utilization"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = "Average database CPU utilization over last 10 minutes too high"
  alarm_actions       = ["${var.sns_arn}"]
  ok_actions          = ["${var.sns_arn}"]

  dimensions = {
    DBInstanceIdentifier = var.replication_db == "" ? aws_db_instance.postgres_sql[0].id : aws_db_instance.postgres_sql_replica[0].id
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_queue_depth_too_high" {
  alarm_name          = "${var.controllername}-disk_queue"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = "DiskQueueDepth"
  namespace           = "AWS/RDS"
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = "Average database disk queue depth over last 10 minutes too high"
  alarm_actions       = ["${var.sns_arn}"]
  ok_actions          = ["${var.sns_arn}"]

  dimensions = {
    DBInstanceIdentifier = var.replication_db == "" ? aws_db_instance.postgres_sql[0].id : aws_db_instance.postgres_sql_replica[0].id
  }
}

resource "aws_cloudwatch_metric_alarm" "freeable_memory_too_low" {
  alarm_name          = "${var.controllername}-freeable_memory"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = "Average database freeable memory over last 10 minutes too low"
  alarm_actions       = ["${var.sns_arn}"]
  ok_actions          = ["${var.sns_arn}"]

  dimensions = {
    DBInstanceIdentifier = var.replication_db == "" ? aws_db_instance.postgres_sql[0].id : aws_db_instance.postgres_sql_replica[0].id
  }
}

resource "aws_cloudwatch_metric_alarm" "database_connection_too_high" {
  alarm_name          = "${var.controllername}-database_connection"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = "Average database connection over last 10 minutes too high"
  alarm_actions       = ["${var.sns_arn}"]
  ok_actions          = ["${var.sns_arn}"]

  dimensions = {
    DBInstanceIdentifier = var.replication_db == "" ? aws_db_instance.postgres_sql[0].id : aws_db_instance.postgres_sql_replica[0].id
  }
}
