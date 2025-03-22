terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version              = ">= 4.0.0"
      configuration_aliases = [aws.dr_region]
    }
  }
}

locals {
  backup_vault_name = "${var.project_name}-${var.environment}-vault"
}

# Backup Vault para almacenar los respaldos
resource "aws_backup_vault" "main" {
  name = "${var.project_name}-${var.environment}-vault"
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vault"
  })
}

# Plan de respaldo
resource "aws_backup_plan" "main" {
  name = "${var.project_name}-${var.environment}-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = var.daily_backup_schedule

    lifecycle {
      delete_after = var.daily_retention_days
    }
  }

  rule {
    rule_name         = "weekly_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = var.weekly_backup_schedule

    lifecycle {
      delete_after = var.weekly_retention_days
    }
  }

  rule {
    rule_name         = "monthly_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = var.monthly_backup_schedule

    lifecycle {
      delete_after = var.monthly_retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn
    }
  }

  advanced_backup_setting {
    backup_options = {
      WindowsVSS = "enabled"
    }
    resource_type = "EC2"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backup-plan"
  })
}

# Vault para Disaster Recovery en otra región
resource "aws_backup_vault" "dr" {
  provider = aws.dr_region
  name     = "${var.project_name}-${var.environment}-dr-vault"
  tags     = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-dr-vault"
  })
}

# Rol IAM para AWS Backup
resource "aws_iam_role" "backup" {
  name = "${var.project_name}-${var.environment}-backup-role"

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
}

# Política para el rol de backup
resource "aws_iam_role_policy_attachment" "backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup.name
}

# Selección de recursos para respaldar
resource "aws_backup_selection" "main" {
  name         = "${var.project_name}-${var.environment}-backup-selection"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.main.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Environment"
    value = var.environment
  }

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}

# Notificaciones de estado de respaldos
resource "aws_sns_topic" "backup_notifications" {
  name = "${var.project_name}-${var.environment}-backup-notifications"
}

resource "aws_sns_topic_policy" "backup_notifications" {
  arn = aws_sns_topic.backup_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBackupNotifications"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.backup_notifications.arn
      }
    ]
  })
}

# CloudWatch Event Rule para monitorear estados de respaldo
resource "aws_cloudwatch_event_rule" "backup_events" {
  name        = "${var.project_name}-${var.environment}-backup-events"
  description = "Captura eventos de AWS Backup"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["AWS Backup Job State Change"]
  })
}

resource "aws_cloudwatch_event_target" "backup_notifications" {
  rule      = aws_cloudwatch_event_rule.backup_events.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.backup_notifications.arn
}

# CloudWatch Dashboard para monitoreo de backups
resource "aws_cloudwatch_dashboard" "backup" {
  dashboard_name = "${var.project_name}-backup-${var.environment}"

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
            ["AWS/Backup", "NumberOfBackupJobs", "BackupVaultName", aws_backup_vault.main.name],
            [".", "NumberOfRestoreJobs", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Trabajos de Backup y Restauración"
          period  = 3600
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
            ["AWS/Backup", "NumberOfFailedJobs", "BackupVaultName", aws_backup_vault.main.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Trabajos Fallidos"
          period  = 3600
        }
      }
    ]
  })
}

# Alarmas de CloudWatch para backups fallidos
resource "aws_cloudwatch_metric_alarm" "backup_failures" {
  alarm_name          = "${var.project_name}-backup-failures-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfFailedJobs"
  namespace           = "AWS/Backup"
  period              = "3600"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alerta cuando hay trabajos de backup fallidos"
  alarm_actions       = [aws_sns_topic.backup_notifications.arn]

  dimensions = {
    BackupVaultName = aws_backup_vault.main.name
  }

  tags = var.tags
}

# Política de retención para el vault
resource "aws_backup_vault_policy" "main" {
  backup_vault_name = aws_backup_vault.main.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action = [
          "backup:DeleteRecoveryPoint"
        ]
        Resource = "*"
        Condition = {
          StringNotLike = {
            "aws:PrincipalArn": var.allowed_principal_arns
          }
        }
      }
    ]
  })
} 