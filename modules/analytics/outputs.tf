# Outputs de Redshift
output "redshift_cluster_id" {
  description = "ID del cluster de Redshift"
  value       = var.create_redshift ? aws_redshift_cluster.main[0].id : null
}

output "redshift_endpoint" {
  description = "Endpoint del cluster de Redshift"
  value       = var.create_redshift ? aws_redshift_cluster.main[0].endpoint : null
}

output "redshift_database_name" {
  description = "Nombre de la base de datos de Redshift"
  value       = var.create_redshift ? aws_redshift_cluster.main[0].database_name : null
}

# Outputs de Athena
output "athena_workgroup_name" {
  description = "Nombre del workgroup de Athena"
  value       = aws_athena_workgroup.main.name
}

output "athena_workgroup_arn" {
  description = "ARN del workgroup de Athena"
  value       = aws_athena_workgroup.main.arn
}

output "athena_database_name" {
  description = "Nombre de la base de datos de Athena"
  value       = aws_glue_catalog_database.analytics.name
}

# Outputs de Glue
output "glue_crawler_name" {
  description = "Nombre del crawler de Glue"
  value       = aws_glue_crawler.processed_data.name
}

output "glue_crawler_arn" {
  description = "ARN del crawler de Glue"
  value       = aws_glue_crawler.processed_data.arn
}

output "glue_table_name" {
  description = "Nombre de la tabla de transacciones en Glue"
  value       = aws_glue_catalog_table.transactions.name
} 