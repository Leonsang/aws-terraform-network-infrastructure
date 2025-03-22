terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Workgroup de Athena
resource "aws_athena_workgroup" "fraud_detection" {
  name = "${var.project_name}-${var.environment}-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.athena_output_bucket}/output/"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-workgroup"
    Environment = var.environment
  }
}

# Base de datos de Athena
resource "aws_athena_database" "fraud_detection" {
  name   = "${var.project_name}_${var.environment}"
  bucket = var.athena_database_bucket
}

# Tabla de transacciones
resource "aws_athena_named_query" "create_transactions_table" {
  name        = "create_transactions_table"
  workgroup   = aws_athena_workgroup.fraud_detection.name
  database    = aws_athena_database.fraud_detection.name
  description = "Crear tabla de transacciones"
  query       = <<-EOF
    CREATE EXTERNAL TABLE IF NOT EXISTS transactions (
      transaction_id STRING,
      timestamp TIMESTAMP,
      amount DOUBLE,
      merchant_id STRING,
      card_number STRING,
      is_fraud BOOLEAN
    )
    STORED AS PARQUET
    LOCATION 's3://${var.processed_bucket}/transactions/'
    TBLPROPERTIES ('parquet.compression'='SNAPPY');
  EOF
}

# Tabla de comerciantes
resource "aws_athena_named_query" "create_merchants_table" {
  name        = "create_merchants_table"
  workgroup   = aws_athena_workgroup.fraud_detection.name
  database    = aws_athena_database.fraud_detection.name
  description = "Crear tabla de comerciantes"
  query       = <<-EOF
    CREATE EXTERNAL TABLE IF NOT EXISTS merchants (
      merchant_id STRING,
      merchant_name STRING,
      category STRING,
      location STRING
    )
    STORED AS PARQUET
    LOCATION 's3://${var.processed_bucket}/merchants/'
    TBLPROPERTIES ('parquet.compression'='SNAPPY');
  EOF
}

# Tabla de análisis de fraude
resource "aws_athena_named_query" "create_fraud_analysis_table" {
  name        = "create_fraud_analysis_table"
  workgroup   = aws_athena_workgroup.fraud_detection.name
  database    = aws_athena_database.fraud_detection.name
  description = "Crear tabla de análisis de fraude"
  query       = <<-EOF
    CREATE EXTERNAL TABLE IF NOT EXISTS fraud_analysis (
      analysis_id STRING,
      transaction_id STRING,
      risk_score DOUBLE,
      model_version STRING,
      features_used STRING
    )
    STORED AS PARQUET
    LOCATION 's3://${var.processed_bucket}/fraud_analysis/'
    TBLPROPERTIES ('parquet.compression'='SNAPPY');
  EOF
}

# Vistas materializadas
resource "aws_athena_named_query" "create_fraud_metrics_view" {
  name        = "create_fraud_metrics_view"
  workgroup   = aws_athena_workgroup.fraud_detection.name
  database    = aws_athena_database.fraud_detection.name
  description = "Crear vista de métricas de fraude"
  query       = <<-EOF
    CREATE OR REPLACE VIEW fraud_metrics AS
    SELECT 
      DATE(timestamp) as date,
      COUNT(*) as total_transactions,
      SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) as fraud_count,
      AVG(CASE WHEN is_fraud THEN amount ELSE 0 END) as avg_fraud_amount
    FROM transactions
    GROUP BY DATE(timestamp);
  EOF
}

# IAM Role para Athena
resource "aws_iam_role" "athena_role" {
  name = "${var.project_name}-${var.environment}-athena-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
      }
    ]
  })
}

# Políticas IAM para Athena
resource "aws_iam_role_policy" "athena_s3_access" {
  name = "athena-s3-access"
  role = aws_iam_role.athena_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.athena_database_bucket}",
          "arn:aws:s3:::${var.athena_database_bucket}/*",
          "arn:aws:s3:::${var.athena_output_bucket}",
          "arn:aws:s3:::${var.athena_output_bucket}/*",
          "arn:aws:s3:::${var.processed_bucket}",
          "arn:aws:s3:::${var.processed_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "athena_glue_access" {
  name = "athena-glue-access"
  role = aws_iam_role.athena_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "athena_queries_failed" {
  alarm_name          = "${var.project_name}-${var.environment}-athena-queries-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FailedQueries"
  namespace           = "AWS/Athena"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.failed_queries_threshold
  alarm_description   = "Número alto de consultas fallidas en Athena"
  alarm_actions       = var.alarm_actions

  dimensions = {
    WorkGroup = aws_athena_workgroup.fraud_detection.name
  }

  tags = var.tags
}

# Outputs
output "workgroup_name" {
  value = aws_athena_workgroup.fraud_detection.name
}

output "database_name" {
  value = aws_athena_database.fraud_detection.name
}

output "athena_role_arn" {
  value = aws_iam_role.athena_role.arn
} 