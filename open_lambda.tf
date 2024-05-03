variable "gateopencode" {
  description = "Code to text gate to open"
}

variable "gateclosecode" {
  description = "Code to text gate to close"
}

data "aws_iam_policy_document" "start_iam_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "start_iam_policy" {
  statement {
    effect  = "Allow"
    actions = ["sns:Publish"]
    resources = [
      aws_sns_topic.control_sns.arn
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["eventbridge:*", "scheduler:*"]
    resources = [aws_scheduler_schedule.close_gate_schedule.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.close_gate_schedule.arn]
  }
}

resource "aws_iam_role" "start_iam" {
  assume_role_policy = data.aws_iam_policy_document.start_iam_trust.json
}

resource "aws_iam_role_policy_attachment" "start_basic_attach" {
  role       = aws_iam_role.start_iam.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "start_policy" {
  name_prefix = "start_iam_policy"
  policy      = data.aws_iam_policy_document.start_iam_policy.json
}

resource "aws_iam_role_policy_attachment" "start_policy_attach" {
  role       = aws_iam_role.start_iam.name
  policy_arn = aws_iam_policy.start_policy.arn
}

resource "aws_lambda_function" "gate_open_lambda" {
  function_name    = "vw_start"
  filename         = "${path.module}/open_lambda_code/lambda_deployment.zip"
  source_code_hash = filesha256("${path.module}/open_lambda_code/lambda_deployment.zip")
  role             = aws_iam_role.start_iam.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  architectures    = ["arm64"]
  timeout          = 240

  environment {
    variables = {
      LOGLEVEL          = "INFO"
      EC2_ID            = aws_instance.vw_host.id
      CLOSE_TIME        = 120
      CLOSE_MSG         = var.gateclosecode
      OPEN_MSG          = var.gateopencode
      SNS_TOPIC         = aws_sns_topic.control_sns.arn
      SCHEDULE_NAME     = aws_scheduler_schedule.close_gate_schedule.name
      SCHEDULE_ROLE_ARN = aws_iam_role.close_gate_schedule.arn
    }
  }
}

resource "aws_lambda_function_url" "gate_open_lambda" {
  authorization_type = "NONE"
  function_name      = aws_lambda_function.gate_open_lambda.function_name
}

output "gate_open_lambda_url" {
  value = aws_lambda_function_url.gate_open_lambda.function_url
}
