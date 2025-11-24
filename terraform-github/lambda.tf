data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/stop_instances.py"
  output_path = "${path.module}/lambda/stop_instances.zip"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_ec2_stop_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda-ec2-stop-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "stop_ec2" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "stop-ec2-if-shutdown-true"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "stop_instances.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [aws_iam_role_policy.lambda_policy]
}

resource "aws_cloudwatch_event_rule" "daily_1am" {
  name                = "stop-ec2-daily-1am"
  schedule_expression = "cron(0 1 * * ? *)"
  description         = "Daily rule at 01:00 UTC to stop EC2 instances tagged shutdown=true"
}

resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_1am.name
  target_id = "stop-ec2-lambda"
  arn       = aws_lambda_function.stop_ec2.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_ec2.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_1am.arn
}
