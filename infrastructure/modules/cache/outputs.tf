output "replication_group_id" {
  description = "ID del Replication Group de Redis"
  value       = aws_elasticache_replication_group.main.id
}

output "replication_group_arn" {
  description = "ARN del Replication Group de Redis"
  value       = aws_elasticache_replication_group.main.arn
}

output "primary_endpoint" {
  description = "Endpoint del nodo primario"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Endpoint de lectura para los nodos réplica"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "port" {
  description = "Puerto del cluster de Redis"
  value       = aws_elasticache_replication_group.main.port
}

output "cache_nodes" {
  description = "Lista de nodos en el cluster"
  value       = aws_elasticache_replication_group.main.member_clusters
}

output "subnet_group_name" {
  description = "Nombre del grupo de subredes"
  value       = aws_elasticache_subnet_group.main.name
}

output "subnet_group_arn" {
  description = "ARN del grupo de subredes"
  value       = aws_elasticache_subnet_group.main.arn
}

output "parameter_group_name" {
  description = "Nombre del grupo de parámetros"
  value       = aws_elasticache_parameter_group.main.name
}

output "parameter_group_arn" {
  description = "ARN del grupo de parámetros"
  value       = aws_elasticache_parameter_group.main.arn
}

output "high_cpu_alarm_arn" {
  description = "ARN de la alarma de CPU alta"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "low_memory_alarm_arn" {
  description = "ARN de la alarma de memoria baja"
  value       = aws_cloudwatch_metric_alarm.memory_low.arn
}

output "high_connections_alarm_arn" {
  description = "ARN de la alarma de conexiones altas"
  value       = aws_cloudwatch_metric_alarm.connections_high.arn
}

output "cache_dashboard_name" {
  description = "Nombre del dashboard de CloudWatch para caché"
  value       = aws_cloudwatch_dashboard.cache.dashboard_name
} 