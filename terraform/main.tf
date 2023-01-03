# -----------------------------------------------------------------------
# Zipping lambda and dependency packages
# -----------------------------------------------------------------------
resource "null_resource" "lambda-copy" {
  provisioner "local-exec" {
    command = "cp -r ../lambda ."
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "py-deps" {
  provisioner "local-exec" {
    command = "pip3 install --target ./lambda botocore boto3 dijkstar"
  }
  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [
    null_resource.lambda-copy
  ]
}

data "archive_file" "lambda-zip" {
  type        = "zip"
  output_path = "lambda.zip"
  source_dir  = "./lambda"
  depends_on = [
    null_resource.py-deps
  ]
}

resource "aws_api_gateway_api_key" "holiday-key" {
  name = "holidaykey"
}
# -----------------------------------------------------------------------
# API key for auth header
# -----------------------------------------------------------------------
resource "aws_api_gateway_usage_plan_key" "devUsageKey" {
  key_id        = aws_api_gateway_api_key.holiday-key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.DevUsagePlan.id
}

resource "aws_api_gateway_usage_plan" "DevUsagePlan" {
  name         = "dev-usage-plan"
  description  = "dev usage plan for say hello"
  product_code = "holiday-key"

  api_stages {
    api_id = aws_api_gateway_rest_api.holiday-api.id
    stage  = aws_api_gateway_stage.holiday-stage.stage_name
  }

  quota_settings {
    limit  = 1000
    offset = 0
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 20
    rate_limit  = 100
  }
}
# -----------------------------------------------------------------------
# Provides an IAM role for Lambda
# -----------------------------------------------------------------------
resource "aws_iam_role" "iam-for-lambda" {
  name = "iam-for-lambda"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : [
            "lambda.amazonaws.com",
            "apigateway.amazonaws.com"
          ]
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })
}

# -----------------------------------------------------------------------
# Provides an IAM policy for DynamoDB-Lambda and ApiGateway-Lambda
# -----------------------------------------------------------------------
resource "aws_iam_policy" "dynamodb-lambda-policy" {
  name = "dynamodb-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGet*",
          "dynamodb:ConditionCheckItem",
          "dynamodb:DescribeTable",
          "dynamodb:DeleteItem",
          "dynamodb:Get*",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWrite*",
          "dynamodb:Update*",
          "dynamodb:PutItem"
        ]
        Resource = [
          aws_dynamodb_table.vehicle_dynamodb_table.arn,
          aws_dynamodb_table.airport_dynamodb_table.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "apigw-cloudwatch-policy" {
  name = "apigw-cloudwatch-policy"
  role = aws_iam_role.iam-for-lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------
# Attaches a IAM policy for DynamoDB-Lambda and ApiGateway-Lambda
# -----------------------------------------------------------------------
resource "aws_iam_policy_attachment" "dynamodb-lambda-attach" {
  name       = "dynamodb-lambda-attachment"
  roles      = [aws_iam_role.iam-for-lambda.name]
  policy_arn = aws_iam_policy.dynamodb-lambda-policy.arn
}

# -----------------------------------------------------------------------
# Cloudwatch resourses
# -----------------------------------------------------------------------
resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.iam-for-lambda.arn
}

resource "aws_cloudwatch_log_group" "api-gw-logs" {
  name              = "api-gw-logs_${aws_api_gateway_rest_api.holiday-api.id}/holiday-stage"
  retention_in_days = 1
}

# -----------------------------------------------------------------------
# DynamoDB table 'airport' and 'vehicle' resources
# -----------------------------------------------------------------------
resource "aws_dynamodb_table" "airport_dynamodb_table" {
  name         = "airport"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-airport"
    Environment = "dev"
  }
}

resource "aws_dynamodb_table" "vehicle_dynamodb_table" {
  name         = "vehicle"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-vehicle"
    Environment = "dev"
  }
}

# -----------------------------------------------------------------------
# Lambda Function resource
# -----------------------------------------------------------------------
resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = "holiday-lambda-function"
  role          = aws_iam_role.iam-for-lambda.arn
  handler       = "handler_as_app.lambda_handler"
  runtime       = "python3.7"
  depends_on = [
    data.archive_file.lambda-zip
  ]
}

# -----------------------------------------------------------------------
# OpenAPI API gateway management
# -----------------------------------------------------------------------
data "template_file" "open-api-specification" {
  template = file("../openapi/deploy-api.yaml")
  vars = {
    region                  = "us-east-1"
    lambda_arn              = aws_lambda_function.lambda.arn
    iam_role_arn            = aws_iam_role.iam-for-lambda.arn
    lambda_identity_timeout = var.lambda_identity_timeout
  }
}

resource "aws_api_gateway_rest_api" "holiday-api" {
  name           = "holiday-api"
  description    = "Proxy to handle requests to our API"
  api_key_source = "HEADER"
  body           = data.template_file.open-api-specification.rendered
  depends_on = [
    aws_lambda_function.lambda
  ]
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Manages an API Gateway Deployment (snapshot of the REST API configuration)
resource "aws_api_gateway_deployment" "holiday-deploy" {
  rest_api_id = aws_api_gateway_rest_api.holiday-api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.holiday-api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Manages an API Gateway Stage (named reference to a deployment)
resource "aws_api_gateway_stage" "holiday-stage" {
  deployment_id = aws_api_gateway_deployment.holiday-deploy.id
  rest_api_id   = aws_api_gateway_rest_api.holiday-api.id
  stage_name    = "holiday-stage"
}

# Manages API Gateway Stage Method Settings
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.holiday-api.id
  stage_name  = aws_api_gateway_stage.holiday-stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = var.api_metrics_enabled
    data_trace_enabled     = var.data_trace_enabled
    logging_level          = var.logging_level
    throttling_burst_limit = var.api_throttling_burst_limit
    throttling_rate_limit  = var.api_throttling_rate_limit
  }
}

# -----------------------------------------------------------------------
# Lambda permission API gateway 
# -----------------------------------------------------------------------
resource "aws_lambda_permission" "api-gateway-invoke-lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.holiday-api.execution_arn}/*/*"
}

# -----------------------------------------------------------------------
# Output URLs
# -----------------------------------------------------------------------
output "base_url" {
  value = aws_api_gateway_deployment.holiday-deploy.invoke_url
}
