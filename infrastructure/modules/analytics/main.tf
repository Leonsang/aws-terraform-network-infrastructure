terraform {
  required_version = ">= 1.0.0"
}

locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
    Component   = "analytics"
  }

  workgroup_name = "${var.project_name}-${var.environment}-analytics"
  database_name  = "${var.project_name}_${var.environment}"
}

# Redshift Cluster
resource "aws_redshift_cluster" "main" {
  cluster_identifier  = "${var.project_name}-${var.environment}"
  database_name      = "analytics"
  master_username    = var.redshift_master_username
  master_password    = var.redshift_master_password
  node_type          = var.redshift_node_type
  cluster_type       = "single-node"
  skip_final_snapshot = true

  vpc_security_group_ids = var.security_group_ids
  cluster_subnet_group_name = aws_redshift_subnet_group.main.name

  tags = var.tags
}

# Redshift Subnet Group
resource "aws_redshift_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

# Grupo de seguridad para Redshift
resource "aws_security_group" "redshift" {
  name_prefix = "${var.project_name}-${var.environment}-redshift-"
  description = "Security group for Redshift cluster"
  vpc_id      = var.vpc_id
  tags        = var.tags

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Considerar restringir según necesidades
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "data_ingestion" {
  name              = "/aws/data-ingestion/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = var.tags
}

# Outputs
output "redshift_cluster_id" {
  description = "ID del cluster de Redshift"
  value       = aws_redshift_cluster.main.id
}

output "redshift_endpoint" {
  description = "Endpoint del cluster de Redshift"
  value       = aws_redshift_cluster.main.endpoint
}

output "redshift_database_name" {
  description = "Nombre de la base de datos de Redshift"
  value       = aws_redshift_cluster.main.database_name
}

# Athena Workgroup
resource "aws_athena_workgroup" "analytics" {
  name = local.workgroup_name

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    result_configuration {
      output_location = "s3://${var.analytics_bucket_name}/athena-results/"
    }
  }

  tags = local.tags
}

# Athena Database
resource "aws_athena_database" "fraud_detection" {
  name   = "fraud_detection"
  bucket = var.analytics_bucket_name

  force_destroy = true
}

# Athena Named Queries
resource "aws_athena_named_query" "fraud_rate_by_hour" {
  name        = "fraud-rate-by-hour"
  workgroup   = aws_athena_workgroup.analytics.name
  database    = aws_athena_database.fraud_detection.name
  description = "Fraud rate by hour of day"
  query       = <<-EOF
    SELECT 
      hour_of_day,
      COUNT(*) as total_transactions,
      SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) as fraud_count,
      ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate
    FROM transactions
    GROUP BY hour_of_day
    ORDER BY hour_of_day;
  EOF
}

resource "aws_athena_named_query" "fraud_by_merchant_category" {
  name        = "fraud-by-merchant-category"
  workgroup   = aws_athena_workgroup.analytics.name
  database    = aws_athena_database.fraud_detection.name
  description = "Fraud analysis by merchant category"
  query       = <<-EOF
    SELECT 
      merchant_category,
      COUNT(*) as total_transactions,
      SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) as fraud_count,
      ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate,
      ROUND(AVG(Amount), 2) as avg_amount
    FROM transactions
    GROUP BY merchant_category
    ORDER BY fraud_rate DESC;
  EOF
}

resource "aws_athena_named_query" "high_risk_cards" {
  name        = "high-risk-cards"
  workgroup   = aws_athena_workgroup.analytics.name
  database    = aws_athena_database.fraud_detection.name
  description = "Identify high-risk cards"
  query       = <<-EOF
    SELECT 
      card_id,
      COUNT(*) as transaction_count,
      SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) as fraud_count,
      ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate,
      ROUND(AVG(Amount), 2) as avg_amount
    FROM transactions
    GROUP BY card_id
    HAVING COUNT(*) > 10
    ORDER BY fraud_rate DESC
    LIMIT 100;
  EOF
}

# S3 Bucket for Athena Results
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.project_name}-${var.environment}-athena-results"
  tags   = local.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    id     = "cleanup_old_results"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }
}

# IAM Role for Athena
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

  tags = local.tags
}

resource "aws_iam_role_policy" "athena_policy" {
  name = "${var.project_name}-${var.environment}-athena-policy"
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
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.analytics_bucket_name}",
          "arn:aws:s3:::${var.analytics_bucket_name}/*",
          "arn:aws:glue:*:*:catalog",
          "arn:aws:glue:*:*:database/${aws_athena_database.fraud_detection.name}",
          "arn:aws:glue:*:*:table/${aws_athena_database.fraud_detection.name}/*"
        ]
      }
    ]
  })
} 