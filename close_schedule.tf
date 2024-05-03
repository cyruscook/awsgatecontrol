resource "aws_scheduler_schedule" "close_gate_schedule" {
  name       = "close-gates"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }


  # Schedule it in the past for now
  schedule_expression = "at(2000-01-01T00:00:00)"

  target {
    arn      = "arn:aws:sns:${var.region}:123456789012:Placeholder"
    role_arn = aws_iam_role.close_gate_schedule.arn
    input    = "close"
  }

  lifecycle {
    ignore_changes = [
      schedule_expression,
      target,
    ]
  }
}

data "aws_iam_policy_document" "close_gate_schedule_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "close_gate_schedule" {
  assume_role_policy = data.aws_iam_policy_document.close_gate_schedule_trust.json
}


data "aws_iam_policy_document" "close_gate_schedule_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_lambda_function.gate_open_lambda.arn]
  }
}

resource "aws_iam_policy" "close_gate_schedule_policy" {
  name_prefix = "close_gate_schedule_policy"
  policy      = data.aws_iam_policy_document.close_gate_schedule_policy.json
}

resource "aws_iam_role_policy_attachment" "close_gate_schedule_attach" {
  role       = aws_iam_role.close_gate_schedule.name
  policy_arn = aws_iam_policy.close_gate_schedule_policy.arn
}
