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

resource "aws_iam_policy" "apigw-lambda-policy" {
  name = "apigw-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:*"
        ]
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

resource "aws_iam_policy_attachment" "apigw-lambda-attach" {
  name       = "apigw-lambda-attachment"
  roles      = [aws_iam_role.iam-for-lambda.name]
  policy_arn = aws_iam_policy.apigw-lambda-policy.arn
}

# -----------------------------------------------------------------------
# DynamoDB table 'airport' and 'vehicle' resources
# -----------------------------------------------------------------------
resource "aws_dynamodb_table" "airport_dynamodb_table" {
  name         = "airport"
  billing_mode = "PAY_PER_REQUEST"
  #   read_capacity  = 20
  #   write_capacity = 20
  hash_key = "id"

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
  #   read_capacity  = 20
  #   write_capacity = 20
  hash_key = "id"

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
}

resource "aws_lambda_function_url" "lambda" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"

}

# -----------------------------------------------------------------------
# OpenAPI API gateway management
# -----------------------------------------------------------------------
data "template_file" "open-api-specification" {
  template = file("../openapi/deploy-api.yaml")
  vars = {
    region       = "us-east-1"
    lambda_arn   = aws_lambda_function.lambda.arn
    iam_role_arn = aws_iam_role.iam-for-lambda.arn
  }
}

resource "aws_api_gateway_rest_api" "holiday-api" {
  name        = "holiday-api"
  description = "Proxy to handle requests to our API"
  body        = data.template_file.open-api-specification.rendered
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
    throttling_burst_limit = var.api_throttling_burst_limit
    throttling_rate_limit  = var.api_throttling_rate_limit
    metrics_enabled        = var.api_metrics_enabled
  }
}

resource "aws_api_gateway_authorizer" "holiday-lambda-auth" {
  name                   = "holiday-lambda-auth"
  rest_api_id            = aws_api_gateway_rest_api.holiday-api.id
  authorizer_uri         = aws_lambda_function.lambda.invoke_arn
  authorizer_credentials = aws_iam_role.iam-for-lambda.arn
}

# data "aws_arn" "api_gw_deployment_arn" {
#   arn = aws_api_gateway_deployment.holiday-deploy.execution_arn
# }

# resource "aws_api_gateway_resource" "resource" {
#   path_part   = "resource"
#   parent_id   = aws_api_gateway_rest_api.holiday-api.root_resource_id
#   rest_api_id = aws_api_gateway_rest_api.holiday-api.id
# }

# resource "aws_api_gateway_method" "method" {
#   rest_api_id   = aws_api_gateway_rest_api.holiday-api.id
#   resource_id   = aws_api_gateway_resource.resource.id
#   http_method   = "GET"
#   authorization = "CUSTOM"
# }

# resource "aws_lambda_permission" "vehicle_get_trigger" {
#   statement_id = "AllowAPIGatewayInvokeGETVehicle"
#   action       = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn = "arn:aws:execute-api:${data.aws_arn.api_gw_deployment_arn.region}:${data.aws_arn.api_gw_deployment_arn.account}:${aws_api_gateway_deployment.holiday-deploy.rest_api_id}/*/GET/vehicle/*/*"
# }

# resource "aws_lambda_permission" "airport_get_trigger" {
#   statement_id = "AllowAPIGatewayInvokeGETAirport"
#   action       = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn = "arn:aws:execute-api:${data.aws_arn.api_gw_deployment_arn.region}:${data.aws_arn.api_gw_deployment_arn.account}:${aws_api_gateway_deployment.holiday-deploy.rest_api_id}/*/GET/airport"
# }

# resource "aws_lambda_permission" "to_airport_get_trigger" {
#   statement_id = "AllowAPIGatewayInvokeGETToAirport"
#   action       = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn = "arn:aws:execute-api:${data.aws_arn.api_gw_deployment_arn.region}:${data.aws_arn.api_gw_deployment_arn.account}:${aws_api_gateway_deployment.holiday-deploy.rest_api_id}/*/GET/airport/*/to/*"
# }

# -----------------------------------------------------------------------
# Output URLs
# -----------------------------------------------------------------------
output "base_url" {
  value = aws_api_gateway_deployment.holiday-deploy.invoke_url
}

output "lamda_function_url" {
  value = aws_lambda_function_url.lambda.function_url
}
