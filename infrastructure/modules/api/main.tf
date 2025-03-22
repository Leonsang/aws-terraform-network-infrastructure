terraform {
  required_version = ">= 1.0.0"
}

locals {
  api_name = "${var.project_name}-fraud-api-${var.environment}"
}

# API Gateway
resource "aws_api_gateway_rest_api" "fraud_api" {
  name        = "${var.project_name}-${var.environment}-api"
  description = "API para detección de fraude"

  endpoint_configuration {
    types = [var.endpoint_type]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-api"
  })
}

# Recurso /predict
resource "aws_api_gateway_resource" "predict" {
  rest_api_id = aws_api_gateway_rest_api.fraud_api.id
  parent_id   = aws_api_gateway_rest_api.fraud_api.root_resource_id
  path_part   = "predict"
}

# Método POST para /predict
resource "aws_api_gateway_method" "predict_post" {
  rest_api_id   = aws_api_gateway_rest_api.fraud_api.id
  resource_id   = aws_api_gateway_resource.predict.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.api_authorizer.id

  request_parameters = {
    "method.request.header.X-API-Key" = true
  }
}

# Validador de requests
resource "aws_api_gateway_request_validator" "predict" {
  name                        = "predict-validator"
  rest_api_id                = aws_api_gateway_rest_api.fraud_api.id
  validate_request_body      = true
  validate_request_parameters = true
}

# Modelo de request
resource "aws_api_gateway_model" "predict_request" {
  rest_api_id  = aws_api_gateway_rest_api.fraud_api.id
  name         = "PredictRequest"
  description  = "Modelo de request para predicción"
  content_type = "application/json"

  schema = jsonencode({
    type = "object"
    required = ["transaction_amount", "merchant_category", "customer_id"]
    properties = {
      transaction_amount = {
        type = "number"
      }
      merchant_category = {
        type = "string"
      }
      customer_id = {
        type = "string"
      }
      card_type = {
        type = "string"
      }
      transaction_country = {
        type = "string"
      }
      transaction_city = {
        type = "string"
      }
    }
  })
}

# Rol IAM para API Gateway
resource "aws_iam_role" "api_gateway_role" {
  name = "${var.project_name}-api-gateway-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Política para invocar SageMaker
resource "aws_iam_role_policy" "api_gateway_sagemaker_policy" {
  name = "${var.project_name}-api-gateway-sagemaker-policy-${var.environment}"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:InvokeEndpoint"
        ]
        Resource = var.sagemaker_endpoint_arn
      }
    ]
  })
}

# Integración con SageMaker
resource "aws_api_gateway_integration" "predict_integration" {
  rest_api_id = aws_api_gateway_rest_api.fraud_api.id
  resource_id = aws_api_gateway_resource.predict.id
  http_method = aws_api_gateway_method.predict_post.http_method
  
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:runtime.sagemaker:path/endpoints/${var.endpoint_name}/invocations"
  credentials             = aws_iam_role.api_gateway_role.arn

  request_templates = {
    "application/json" = <<EOF
{
    "instances": [{
        "features": [
            $input.json('$.transaction_amount'),
            "$input.json('$.merchant_category')",
            "$input.json('$.customer_id')",
            "$input.json('$.card_type')",
            "$input.json('$.transaction_country')",
            "$input.json('$.transaction_city')"
        ]
    }]
}
EOF
  }
}

# Respuesta de integración
resource "aws_api_gateway_method_response" "predict_response_200" {
  rest_api_id = aws_api_gateway_rest_api.fraud_api.id
  resource_id = aws_api_gateway_resource.predict.id
  http_method = aws_api_gateway_method.predict_post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "predict_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.fraud_api.id
  resource_id = aws_api_gateway_resource.predict.id
  http_method = aws_api_gateway_method.predict_post.http_method
  status_code = aws_api_gateway_method_response.predict_response_200.status_code

  response_templates = {
    "application/json" = <<EOF
{
    "prediction": $input.path('$.predictions[0].score'),
    "is_fraud": #if($input.path('$.predictions[0].score') > 0.5) true #else false #end
}
EOF
  }
}

# Stage de despliegue
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.fraud_api.id

  depends_on = [
    aws_api_gateway_integration.predict_integration,
    aws_api_gateway_integration_response.predict_integration_response
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.fraud_api.id
  stage_name    = var.environment

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId = "$context.requestId",
      ip = "$context.identity.sourceIp",
      caller = "$context.identity.caller",
      user = "$context.identity.user",
      requestTime = "$context.requestTime",
      httpMethod = "$context.httpMethod",
      resourcePath = "$context.resourcePath",
      status = "$context.status",
      protocol = "$context.protocol",
      responseLength = "$context.responseLength"
    })
  }

  tags = var.tags
}

# Plan de uso
resource "aws_api_gateway_usage_plan" "api_usage_plan" {
  name        = "${var.project_name}-${var.environment}-usage-plan"
  description = "Plan de uso para API de fraude"

  api_stages {
    api_id = aws_api_gateway_rest_api.fraud_api.id
    stage  = aws_api_gateway_stage.api_stage.stage_name
  }

  quota_settings {
    limit  = var.quota_limit
    period = var.quota_period
  }

  throttle_settings {
    burst_limit = var.throttle_burst_limit
    rate_limit  = var.throttle_rate_limit
  }

  tags = var.tags
}

# CloudWatch para logs
resource "aws_api_gateway_account" "fraud_detection" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.project_name}-api-gateway-cloudwatch-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch_policy" {
  name = "${var.project_name}-api-gateway-cloudwatch-policy-${var.environment}"
  role = aws_iam_role.api_gateway_cloudwatch.id

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

# WAF para seguridad
resource "aws_wafv2_web_acl" "api_waf" {
  name        = "terraform-aws-dev-api-waf"
  description = "WAF para proteger la API"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimit"
    priority = 1

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    action {
      block {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "RateLimitRule"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "APIWAF"
    sampled_requests_enabled  = true
  }

  tags = {
    Environment = "dev"
    Project     = "terraform-aws"
    Terraform   = "true"
  }
}

# IP Set para IPs bloqueadas
resource "aws_wafv2_ip_set" "blocked_ips" {
  name               = "${var.project_name}-${var.environment}-blocked-ips"
  description        = "IPs bloqueadas para la API"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.blocked_ips

  tags = var.tags
}

# IP Set para IPs maliciosas
resource "aws_wafv2_ip_set" "malicious_ips" {
  name               = "${var.project_name}-${var.environment}-malicious-ips"
  description        = "IPs maliciosas para la API"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.malicious_ips

  tags = var.tags
}

# Asociación de WAF con API Gateway
resource "aws_wafv2_web_acl_association" "api_waf" {
  resource_arn = aws_api_gateway_stage.api_stage.arn
  web_acl_arn  = aws_wafv2_web_acl.api_waf.arn
}

# Authorizer Lambda
resource "aws_lambda_function" "authorizer" {
  filename         = "${path.module}/lambda/authorizer.zip"
  function_name    = "${var.project_name}-${var.environment}-api-authorizer"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 10
  memory_size     = 256

  environment {
    variables = {
      AUTH_TABLE = aws_dynamodb_table.auth.id
      ENVIRONMENT = var.environment
    }
  }

  tags = var.tags
}

# DynamoDB para autenticación
resource "aws_dynamodb_table" "auth" {
  name           = "${var.project_name}-${var.environment}-auth"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = var.tags
}

# API Gateway Authorizer
resource "aws_api_gateway_authorizer" "api_authorizer" {
  name                   = "api-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.fraud_api.id
  authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.authorizer_role.arn
  type                  = "TOKEN"
}

# Lambda para predicción
resource "aws_lambda_function" "predict" {
  filename         = "${path.module}/lambda/predict.zip"
  function_name    = "${var.project_name}-${var.environment}-predict"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory

  environment {
    variables = {
      MODEL_BUCKET = var.model_bucket
      MODEL_KEY    = var.model_key
      ENVIRONMENT  = var.environment
      LOG_LEVEL   = var.log_level
    }
  }

  tags = var.tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "api_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-api"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", aws_api_gateway_rest_api.fraud_api.name],
            [".", "4XXError", ".", "."],
            [".", "5XXError", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "API Requests y Errores"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiName", aws_api_gateway_rest_api.fraud_api.name, {"stat": "Average"}],
            ["...", {"stat": "p95"}]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "API Latencia"
          period  = 300
        }
      }
    ]
  })
}

# Alarmas CloudWatch
resource "aws_cloudwatch_metric_alarm" "api_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-api-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period             = "300"
  statistic          = "Sum"
  threshold          = var.error_threshold
  alarm_description  = "Monitoreo de errores 5XX en la API"
  alarm_actions      = var.alarm_actions

  dimensions = {
    ApiName = aws_api_gateway_rest_api.fraud_api.name
  }

  tags = var.tags
}

# Roles IAM
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-api-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role" "authorizer_role" {
  name = "${var.project_name}-${var.environment}-api-authorizer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Políticas IAM
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-${var.environment}-api-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${var.model_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.auth.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "authorizer_policy" {
  name = "${var.project_name}-${var.environment}-api-authorizer-policy"
  role = aws_iam_role.authorizer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = aws_lambda_function.authorizer.arn
      }
    ]
  })
}

# Data Sources
data "aws_region" "current" {} 