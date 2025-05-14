resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "sqs_send_policy" {
  name = "sqs_send_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["sqs:SendMessage"],
        Resource = aws_sqs_queue.app_queue.arn
      }
    ]
  })
}

resource "aws_sqs_queue" "app_queue" {
  name = "serverless-app-queue"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../lambda/send_to_sqs"
  output_path = "../lambda/send_to_sqs.zip"
}

resource "aws_lambda_function" "send_to_sqs" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.app_queue.id
    }
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.send_to_sqs.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /send"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_to_sqs.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}


data "archive_file" "consumer_lambda_zip" {
  type        = "zip"
  source_dir  = "../lambda/process_sqs"
  output_path = "../lambda/process_sqs.zip"
}

resource "aws_lambda_function" "process_sqs" {
  filename         = data.archive_file.consumer_lambda_zip.output_path
  function_name    = "processSQS"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.consumer_lambda_zip.output_base64sha256
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.app_queue.arn
  function_name    = aws_lambda_function.process_sqs.arn
  batch_size       = 10
  enabled          = true
}


resource "aws_s3_bucket" "job_bucket" {
  bucket = "serverless-job-postings-${random_id.bucket_id.hex}"
  force_destroy = true
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_lambda_function" "process_sqs" {
  filename         = data.archive_file.consumer_lambda_zip.output_path
  function_name    = "processSQS"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.consumer_lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.job_bucket.bucket
    }
  }
}

resource "aws_iam_role_policy" "s3_write_policy" {
  name = "s3_write_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:PutObject"],
        Resource = "${aws_s3_bucket.job_bucket.arn}/*"
      }
    ]
  })
}
