data "aws_caller_identity" "this" {}

resource "aws_sns_topic" "sns_topic" {
  name = "${var.cluster_name}-sns"
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
  arn = aws_sns_topic.sns_topic.arn

  policy = jsonencode({
    "Version" : "2008-10-17",
    "Id" : "__default_policy_ID",
    "Statement" : [
      {
        "Sid" : "__default_statement_ID",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "SNS:Publish",
          "SNS:RemovePermission",
          "SNS:SetTopicAttributes",
          "SNS:DeleteTopic",
          "SNS:ListSubscriptionsByTopic",
          "SNS:GetTopicAttributes",
          "SNS:AddPermission",
          "SNS:Subscribe"
        ],
        "Resource" : "${aws_sns_topic.sns_topic.arn}",
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceOwner" : "${data.aws_caller_identity.this.account_id}"
          }
        }
      },
      {
        "Sid" : "__console_pub_0",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : "SNS:Publish",
        "Resource" : "${aws_sns_topic.sns_topic.arn}"
      }
    ]
  })

}

resource "aws_sns_topic_subscription" "user_updates_sns_target" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = var.protocol
  endpoint  = var.email_lists
}
