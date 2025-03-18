# Módulo de ingesta de datos para el proyecto de Detección de Fraude Financiero

locals {
  lambda_function_name = "${var.project_name}-${var.environment}-kaggle-downloader"
  layer_name          = "${var.project_name}-${var.environment}-kaggle-layer"
  
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  })
}

# Capa Lambda para Kaggle
resource "aws_lambda_layer_version" "kaggle_layer" {
  filename            = "${path.module}/layers/kaggle_layer.zip"
  layer_name          = local.layer_name
  description         = "Capa con la biblioteca Kaggle para Python"
  compatible_runtimes = ["python3.9"]

  tags = merge(local.common_tags, {
    Name = local.layer_name
    Purpose = "Kaggle Layer"
  })
}

# Función Lambda para descargar datos de Kaggle
resource "aws_lambda_function" "kaggle_downloader" {
  filename         = "${path.module}/functions/kaggle_downloader.zip"
  function_name    = local.lambda_function_name
  role            = var.lambda_role_arn
  handler         = "kaggle_downloader.lambda_handler"
  runtime         = "python3.9"
  timeout         = 900
  memory_size     = 512

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
    Purpose = "Kaggle Data Downloader"
  })
}

# Regla EventBridge para programar la descarga
resource "aws_cloudwatch_event_rule" "download_schedule" {
  name                = "${local.lambda_function_name}-schedule"
  description         = "Programa la descarga periódica de datos de Kaggle"
  schedule_expression = var.download_schedule

  tags = merge(local.common_tags, {
    Name = "${local.lambda_function_name}-schedule"
    Purpose = "Kaggle Download Schedule"
  })
}

# Objetivo de la regla EventBridge
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.download_schedule.name
  target_id = "KaggleDownloader"
  arn       = aws_lambda_function.kaggle_downloader.arn
}

# Permiso para que EventBridge invoque la función Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kaggle_downloader.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.download_schedule.arn
}

# Crear un grupo de logs para la función Lambda
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.kaggle_downloader.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-kaggle-downloader-logs"
    Purpose = "Kaggle Downloader Logs"
  })
} 