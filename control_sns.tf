variable "gatenumber" {
  description = "Phone Number for gate control"
}

resource "aws_sns_topic" "control_sns" {
  name = "gate-control-sns"
}

resource "aws_sns_topic_subscription" "control_sns_phone_sub" {
  topic_arn = aws_sns_topic.control_sns.arn
  protocol  = "sms"
  endpoint  = var.gatenumber
}
