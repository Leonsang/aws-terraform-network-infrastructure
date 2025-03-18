# Módulo de procesamiento mejorado para el proyecto de Detección de Fraude

locals {
  glue_db_name     = "${var.project_name}-${var.environment}-db"
  glue_crawler_raw = "${var.project_name}-${var.environment}-raw-crawler"
  glue_job_name    = "${var.project_name}-${var.environment}-etl-job"
  lambda_layer_name = "${var.project_name}-${var.environment}-pandas-layer"
  kinesis_stream   = "${var.project_name}-${var.environment}-transaction-stream"
  dynamodb_table   = "${var.project_name}-${var.environment}-card-stats"
  
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  })
}

# Base de datos de Glue
resource "aws_glue_catalog_database" "fraud_db" {
  name = local.glue_db_name
  description = "Base de datos para detección de fraude"
  
  tags = local.common_tags
}

# Crawler para datos raw
resource "aws_glue_crawler" "raw_crawler" {
  database_name = aws_glue_catalog_database.fraud_db.name
  name          = local.glue_crawler_raw
  role          = var.glue_role_arn

  s3_target {
    path = "s3://${var.raw_bucket_name}/transactions/"
  }

  schedule = var.crawler_schedule
  security_configuration = aws_glue_security_configuration.main.name

  tags = local.common_tags
}

# Configuración de seguridad para Glue
resource "aws_glue_security_configuration" "main" {
  name = "${var.project_name}-${var.environment}-glue-security"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn              = var.kms_key_arn
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                  = var.kms_key_arn
    }

    s3_encryption {
      kms_key_arn        = var.kms_key_arn
      s3_encryption_mode = "SSE-KMS"
    }
  }

  tags = local.common_tags
}

# Job de ETL en Glue
resource "aws_glue_job" "etl_job" {
  name     = local.glue_job_name
  role_arn = var.glue_role_arn

  command {
    script_location = "s3://${var.proc_bucket_name}/scripts/etl_job.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"               = "python"
    "--continuous-log-logGroup"    = "/aws-glue/jobs/${local.glue_job_name}"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"            = "true"
    "--raw-bucket"               = var.raw_bucket_name
    "--processed-bucket"         = var.proc_bucket_name
    "--analytics-bucket"         = var.analy_bucket_name
    "--job-bookmark-option"      = "job-bookmark-enable"
    "--TempDir"                  = "s3://${var.proc_bucket_name}/temp/"
    "--enable-spark-ui"          = "true"
    "--spark-event-logs-path"    = "s3://${var.proc_bucket_name}/spark-logs/"
  }

  execution_property {
    max_concurrent_runs = 2
  }

  glue_version = "3.0"

  max_capacity = 10
  max_retries  = 3
  timeout      = 2880 # 48 horas

  security_configuration = aws_glue_security_configuration.main.name

  tags = local.common_tags
}

# Stream de Kinesis para datos en tiempo real
resource "aws_kinesis_stream" "transaction_stream" {
  name             = local.kinesis_stream
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_period

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
    "IncomingRecords",
    "OutgoingRecords",
    "WriteProvisionedThroughputExceeded",
    "ReadProvisionedThroughputExceeded",
    "IteratorAgeMilliseconds"
  ]

  encryption_type = "KMS"
  kms_key_id      = var.kms_key_arn

  tags = local.common_tags
}

# Tabla DynamoDB para estadísticas de tarjetas
resource "aws_dynamodb_table" "card_stats" {
  name             = local.dynamodb_table
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "card_id"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "card_id"
    type = "S"
  }

  ttl {
    attribute_name = "ExpirationTime"
    enabled       = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
    kms_key_arn = var.kms_key_arn
  }

  tags = local.common_tags
}

# Función Lambda para validación de datos
resource "aws_lambda_function" "data_validation" {
  filename         = "${path.module}/lambda/data_quality_lambda.zip"
  function_name    = "${var.project_name}-${var.environment}-data-validation"
  role            = var.lambda_role_arn
  handler         = "data_quality_lambda.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256
  publish         = true

  environment {
    variables = {
      RAW_BUCKET       = var.raw_bucket_name
      PROCESSED_BUCKET = var.proc_bucket_name
      DYNAMODB_TABLE   = local.dynamodb_table
      LOG_LEVEL        = "INFO"
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = local.common_tags
}

# Configuración de auto-scaling para Lambda
resource "aws_appautoscaling_target" "lambda_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "function:${aws_lambda_function.data_validation.function_name}"
  scalable_dimension = "lambda:function:ProvisionedConcurrency"
  service_namespace  = "lambda"
}

resource "aws_appautoscaling_policy" "lambda_policy" {
  name               = "${aws_lambda_function.data_validation.function_name}-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.lambda_target.resource_id
  scalable_dimension = aws_appautoscaling_target.lambda_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.lambda_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "LambdaProvisionedConcurrencyUtilization"
    }
    target_value = 0.7
  }
}

# Security Group para Lambda
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-${var.environment}-lambda-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# Función Lambda para procesamiento en tiempo real
resource "aws_lambda_function" "realtime_processing" {
  filename         = "${path.module}/lambda/realtime_fraud_lambda.zip"
  function_name    = "${var.project_name}-${var.environment}-realtime-fraud"
  role            = var.lambda_role_arn
  handler         = "realtime_fraud_lambda.handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256
  publish         = true

  environment {
    variables = {
      DYNAMODB_TABLE     = local.dynamodb_table
      PROCESSED_BUCKET   = var.proc_bucket_name
      ANALYTICS_BUCKET   = var.analy_bucket_name
      LOG_LEVEL         = "INFO"
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = local.common_tags
}

# Configuración de auto-scaling para Lambda de procesamiento en tiempo real
resource "aws_appautoscaling_target" "realtime_lambda_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "function:${aws_lambda_function.realtime_processing.function_name}"
  scalable_dimension = "lambda:function:ProvisionedConcurrency"
  service_namespace  = "lambda"
}

resource "aws_appautoscaling_policy" "realtime_lambda_policy" {
  name               = "${aws_lambda_function.realtime_processing.function_name}-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.realtime_lambda_target.resource_id
  scalable_dimension = aws_appautoscaling_target.realtime_lambda_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.realtime_lambda_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "LambdaProvisionedConcurrencyUtilization"
    }
    target_value = 0.7
  }
}

# Trigger de Kinesis para Lambda
resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = aws_kinesis_stream.transaction_stream.arn
  function_name     = aws_lambda_function.realtime_processing.arn
  starting_position = "LATEST"
  batch_size        = 100
  maximum_batching_window_in_seconds = 5

  function_response_types = ["ReportBatchItemFailures"]
}

# Configuración de invocación asíncrona para Lambda
resource "aws_lambda_function_event_invoke_config" "kinesis_trigger" {
  function_name = aws_lambda_function.realtime_processing.function_name

  destination_config {
    on_failure {
      destination = aws_sns_topic.fraud_alerts.arn
    }
    on_success {
      destination = aws_sns_topic.processing_success.arn
    }
  }

  maximum_event_age_in_seconds = 3600
  maximum_retry_attempts      = 2
}

# SNS Topics para alertas
resource "aws_sns_topic" "fraud_alerts" {
  name = "${var.project_name}-${var.environment}-fraud-alerts"
  
  tags = local.common_tags
}

resource "aws_sns_topic" "processing_success" {
  name = "${var.project_name}-${var.environment}-processing-success"
  
  tags = local.common_tags
}

# Suscripciones a SNS
resource "aws_sns_topic_subscription" "fraud_alerts_email" {
  topic_arn = aws_sns_topic.fraud_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_sns_topic_subscription" "processing_success_email" {
  topic_arn = aws_sns_topic.processing_success.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "data_validation" {
  name              = "/aws/lambda/${aws_lambda_function.data_validation.function_name}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "realtime_processing" {
  name              = "/aws/lambda/${aws_lambda_function.realtime_processing.function_name}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

# Métricas personalizadas de CloudWatch
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${aws_lambda_function.data_validation.function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Esta alarma se activa cuando hay errores en la función Lambda"
  alarm_actions       = [aws_sns_topic.fraud_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.data_validation.function_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {
  alarm_name          = "${aws_kinesis_stream.transaction_stream.name}-iterator-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 300
  statistic           = "Maximum"
  threshold           = 3600000 # 1 hora en milisegundos
  alarm_description   = "Esta alarma se activa cuando el retraso en el procesamiento de Kinesis es mayor a 1 hora"
  alarm_actions       = [aws_sns_topic.fraud_alerts.arn]

  dimensions = {
    StreamName = aws_kinesis_stream.transaction_stream.name
  }

  tags = local.common_tags
} 