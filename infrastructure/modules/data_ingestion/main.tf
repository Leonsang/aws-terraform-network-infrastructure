# Módulo de ingesta de datos para el proyecto de Detección de Fraude Financiero

locals {
  lambda_function_name = "${var.project_name}-${var.environment}-kaggle-downloader"
  layer_name          = "${var.project_name}-${var.environment}-kaggle-layer"
  
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Component   = "data-ingestion"
  })
}

# Dependencia del módulo de seguridad
module "security" {
  source = "../security"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  account_id   = var.account_id
  tags         = var.tags
  security_alert_emails = [var.alert_email]
  alarm_actions = []
}

# Capa Lambda para dependencias
resource "aws_lambda_layer_version" "kaggle_layer" {
  filename            = "${path.module}/layers/kaggle_layer.zip"
  layer_name         = "${var.project_name}-${var.environment}-kaggle-layer"
  compatible_runtimes = ["python3.8", "python3.9"]
  description        = "Capa Lambda con dependencias de Kaggle"
}

# Función Lambda de ingesta
resource "aws_lambda_function" "kaggle_downloader" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = local.lambda_function_name
  role         = module.security.lambda_role_arn
  handler      = "main.lambda_handler"
  runtime      = "python3.9"
  timeout      = 900
  memory_size  = 512

  layers = [aws_lambda_layer_version.kaggle_layer.arn]

  environment {
    variables = {
      KAGGLE_USERNAME = var.kaggle_username
      KAGGLE_KEY      = var.kaggle_key
      RAW_BUCKET      = var.raw_bucket_name
    }
  }

  tags = merge(local.common_tags, {
    Name = local.lambda_function_name
  })
}

# Empaquetado de la función Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/functions/kaggle_downloader"
  output_path = "${path.module}/../src/functions/kaggle_downloader.zip"
}

# Programación de ejecución
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${local.lambda_function_name}-schedule"
  description         = "Programa la ingesta periódica de datos"
  schedule_expression = var.download_schedule

  tags = merge(local.common_tags, {
    Name = "${local.lambda_function_name}-schedule"
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "KaggleDownloader"
  arn       = aws_lambda_function.kaggle_downloader.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kaggle_downloader.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

# Logs
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.kaggle_downloader.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.lambda_function_name}-logs"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "data_ingestion" {
  name              = "/aws/data-ingestion/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.tags
} 