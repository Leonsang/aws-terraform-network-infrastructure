output "log_group_name" {
  description = "Nombre del grupo de logs de CloudWatch"
  value       = aws_cloudwatch_log_group.data_ingestion.name
}

output "redshift_cluster_endpoint" {
  description = "Endpoint of the Redshift cluster"
  value       = aws_redshift_cluster.main.endpoint
} 