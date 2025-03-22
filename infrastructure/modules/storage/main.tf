terraform {
  required_version = ">= 1.0.0"
}

locals {
  s3_bucket_name = "${var.project_name}-storage-${var.environment}-${data.aws_caller_identity.current.account_id}"
  efs_name       = "${var.project_name}-efs-${var.environment}"
  raw_bucket_name        = "${var.project_name}-${var.environment}-${var.raw_bucket_suffix}"
  processed_bucket_name  = "${var.project_name}-${var.environment}-${var.processed_bucket_suffix}"
  analytics_bucket_name  = "${var.project_name}-${var.environment}-${var.analytics_bucket_suffix}"
}

# Obtener la cuenta actual
data "aws_caller_identity" "current" {}

# Raw Data Bucket
resource "aws_s3_bucket" "raw" {
  bucket = local.raw_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Processed Data Bucket
resource "aws_s3_bucket" "processed" {
  bucket = local.processed_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "processed" {
  bucket = aws_s3_bucket.processed.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id

  rule {
    id     = "transition_rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.processed_transition_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.processed_transition_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.processed_expiration_days
    }
  }
}

# Analytics Bucket
resource "aws_s3_bucket" "analytics" {
  bucket = local.analytics_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "analytics" {
  bucket = aws_s3_bucket.analytics.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics" {
  bucket = aws_s3_bucket.analytics.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Outputs
output "raw_bucket_name" {
  value = aws_s3_bucket.raw.id
}

output "raw_bucket_arn" {
  value = aws_s3_bucket.raw.arn
}

output "processed_bucket_name" {
  value = aws_s3_bucket.processed.id
}

output "processed_bucket_arn" {
  value = aws_s3_bucket.processed.arn
}

output "analytics_bucket_name" {
  value = aws_s3_bucket.analytics.id
}

output "analytics_bucket_arn" {
  value = aws_s3_bucket.analytics.arn
}

output "logs_bucket_arn" {
  value = aws_s3_bucket.main.arn
}

module "s3_data_lake" {
  source = "./s3"

  project_name = var.project_name
  environment  = var.environment
}

module "feature_store" {
  source = "./feature_store"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  feature_definitions = var.feature_definitions
  offline_store_config = {
    disable_glue_table_creation = false
    data_catalog_config = {
      table_name       = "${var.project_name}_${var.environment}_fraud_features"
      database_name    = "${var.project_name}_${var.environment}_feature_store"
      catalog_role_arn = null
    }
  }
}

# Outputs
output "data_lake_buckets" {
  description = "Información de los buckets del Data Lake"
  value = {
    raw       = module.s3_data_lake.raw_bucket
    processed = module.s3_data_lake.processed_bucket
    analytics = module.s3_data_lake.analytics_bucket
  }
}

output "feature_store" {
  description = "Información del Feature Store"
  value = {
    bucket = module.feature_store.feature_store_bucket
    role   = module.feature_store.feature_store_role
  }
}

# S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket = local.s3_bucket_name
  force_destroy = var.force_destroy_bucket

  tags = merge(
    var.tags,
    {
      Name = local.s3_bucket_name
    }
  )
}

# Configuración del bucket S3
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.enable_lifecycle_rules ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "transition_to_ia"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.transition_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration_days
    }
  }
}

# EFS File System
resource "aws_efs_file_system" "main" {
  count          = var.create_efs ? 1 : 0
  creation_token = local.efs_name
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = var.efs_transition_to_ia
  }

  performance_mode = var.efs_performance_mode
  throughput_mode = var.efs_throughput_mode
  provisioned_throughput_in_mibps = var.efs_provisioned_throughput

  tags = merge(
    var.tags,
    {
      Name = local.efs_name
    }
  )
}

# Mount targets para EFS
resource "aws_efs_mount_target" "main" {
  count           = var.create_efs ? length(var.subnet_ids) : 0
  file_system_id  = aws_efs_file_system.main[0].id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs[0].id]
}

# Security Group para EFS
resource "aws_security_group" "efs" {
  count       = var.create_efs ? 1 : 0
  name        = "${local.efs_name}-sg"
  description = "Security group para EFS"
  vpc_id      = var.vpc_id

  ingress {
    description = "NFS desde VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.efs_name}-sg"
    }
  )
}

# Backup para EFS
resource "aws_backup_plan" "efs" {
  count = var.create_efs && var.enable_efs_backup ? 1 : 0
  name  = "${local.efs_name}-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = var.backup_schedule

    lifecycle {
      delete_after = var.backup_retention_days
    }
  }

  tags = var.tags
}

resource "aws_backup_vault" "main" {
  count = var.create_efs && var.enable_efs_backup ? 1 : 0
  name  = "${local.efs_name}-backup-vault"
  tags  = var.tags
}

resource "aws_backup_selection" "efs" {
  count        = var.create_efs && var.enable_efs_backup ? 1 : 0
  name         = "${local.efs_name}-backup-selection"
  plan_id      = aws_backup_plan.efs[0].id
  iam_role_arn = aws_iam_role.backup[0].arn

  resources = [
    aws_efs_file_system.main[0].arn
  ]
}

# IAM Role para AWS Backup
resource "aws_iam_role" "backup" {
  count = var.create_efs && var.enable_efs_backup ? 1 : 0
  name  = "${local.efs_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  count      = var.create_efs && var.enable_efs_backup ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup[0].name
}

# CloudWatch Alarmas
resource "aws_cloudwatch_metric_alarm" "s3_bucket_size" {
  alarm_name          = "${local.s3_bucket_name}-size"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = var.bucket_size_threshold
  alarm_description   = "Monitoreo del tamaño del bucket S3"
  alarm_actions       = var.alarm_actions

  dimensions = {
    BucketName = aws_s3_bucket.main.id
    StorageType = "StandardStorage"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "efs_storage" {
  count               = var.create_efs ? 1 : 0
  alarm_name          = "${local.efs_name}-storage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "StorageBytes"
  namespace           = "AWS/EFS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.efs_storage_threshold
  alarm_description   = "Monitoreo del almacenamiento EFS"
  alarm_actions       = var.alarm_actions

  dimensions = {
    FileSystemId = aws_efs_file_system.main[0].id
  }

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "storage" {
  dashboard_name = "${var.project_name}-storage-${var.environment}"

  dashboard_body = jsonencode({
    widgets = concat([
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", aws_s3_bucket.main.id, "StorageType", "StandardStorage"],
            ["AWS/S3", "NumberOfObjects", "BucketName", aws_s3_bucket.main.id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Métricas S3"
          period  = 86400
        }
      }
    ],
    var.create_efs ? [
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EFS", "StorageBytes", "FileSystemId", aws_efs_file_system.main[0].id],
            ["AWS/EFS", "ClientConnections", "FileSystemId", aws_efs_file_system.main[0].id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Métricas EFS"
          period  = 300
        }
      }
    ] : [])
  })
}

# Metrics Bucket
resource "aws_s3_bucket" "metrics" {
  count  = var.create_metrics_bucket ? 1 : 0
  bucket = var.metrics_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "metrics" {
  count  = var.create_metrics_bucket ? 1 : 0
  bucket = aws_s3_bucket.metrics[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "metrics" {
  count  = var.create_metrics_bucket ? 1 : 0
  bucket = aws_s3_bucket.metrics[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "metrics" {
  count  = var.create_metrics_bucket ? 1 : 0
  bucket = aws_s3_bucket.metrics[0].id

  rule {
    id     = "metrics_lifecycle"
    status = "Enabled"

    filter {
      prefix = "metrics/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }
  }
}

output "metrics_bucket_name" {
  value = var.create_metrics_bucket ? aws_s3_bucket.metrics[0].id : ""
}

output "metrics_bucket_arn" {
  value = var.create_metrics_bucket ? aws_s3_bucket.metrics[0].arn : ""
}

output "s3_bucket_id" {
  value = aws_s3_bucket.raw.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.raw.arn
}

output "model_bucket_name" {
  value = aws_s3_bucket.analytics.id
}

output "model_bucket_arn" {
  value = aws_s3_bucket.analytics.arn
} 