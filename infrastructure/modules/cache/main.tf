locals {
  cache_name = "${var.project_name}-redis-${var.environment}"
}

# Grupo de Subredes de ElastiCache
resource "aws_elasticache_subnet_group" "main" {
  name        = "${var.project_name}-cache-subnet-${var.environment}"
  subnet_ids  = var.subnet_ids
  description = "Grupo de subredes para ElastiCache ${var.environment}"

  tags = var.tags
}

# Grupo de Parámetros de Redis
resource "aws_elasticache_parameter_group" "main" {
  family      = "redis6.x"
  name        = "${var.project_name}-redis-params-${var.environment}"
  description = "Grupo de parámetros de Redis ${var.environment}"

  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"
  }

  parameter {
    name  = "notify-keyspace-events"
    value = "KEA"
  }

  tags = var.tags
}

# Replication Group de Redis
resource "aws_elasticache_replication_group" "main" {
  replication_group_id          = local.cache_name
  replication_group_description = "Cluster de Redis para ${var.project_name} ${var.environment}"
  node_type                    = var.node_type
  number_cache_clusters        = var.number_cache_clusters
  port                        = 6379
  parameter_group_name        = aws_elasticache_parameter_group.main.name
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = var.security_group_ids
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled          = var.multi_az_enabled

  engine               = "redis"
  engine_version      = var.engine_version
  maintenance_window  = var.maintenance_window
  snapshot_window    = var.snapshot_window
  snapshot_retention_limit = var.snapshot_retention_days

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  auto_minor_version_upgrade = true
  apply_immediately         = var.apply_immediately

  notification_topic_arn = var.notification_topic_arn

  tags = merge(
    var.tags,
    {
      Name = local.cache_name
    }
  )
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.cache_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "CPU alta en el cluster de Redis"
  alarm_actions       = var.alarm_actions

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
  alarm_name          = "${local.cache_name}-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "Memoria baja en el cluster de Redis"
  alarm_actions       = var.alarm_actions

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "connections_high" {
  alarm_name          = "${local.cache_name}-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = var.connections_threshold
  alarm_description   = "Número alto de conexiones en Redis"
  alarm_actions       = var.alarm_actions

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "cache" {
  dashboard_name = "${var.project_name}-cache-${var.environment}"

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
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", aws_elasticache_replication_group.main.id],
            [".", "FreeableMemory", ".", "."],
            [".", "SwapUsage", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Métricas de Recursos"
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
            ["AWS/ElastiCache", "CurrConnections", "CacheClusterId", aws_elasticache_replication_group.main.id],
            [".", "CacheHits", ".", "."],
            [".", "CacheMisses", ".", "."],
            [".", "Evictions", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Métricas de Rendimiento"
          period  = 300
        }
      }
    ]
  })
} 