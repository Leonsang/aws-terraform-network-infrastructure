# Outputs del proyecto de Detección de Fraude Financiero

# Outputs del módulo de almacenamiento
output "raw_bucket_name" {
  description = "Nombre del bucket S3 para la zona raw"
  value       = module.storage.raw_bucket_name
}

output "processed_bucket_name" {
  description = "Nombre del bucket S3 para la zona processed"
  value       = module.storage.processed_bucket_name
}

output "analytics_bucket_name" {
  description = "Nombre del bucket S3 para la zona analytics"
  value       = module.storage.analytics_bucket_name
}

# Outputs del módulo de procesamiento
/*
output "glue_database_name" {
  description = "Nombre de la base de datos de Glue"
  value       = module.processing.glue_database_name
}

output "glue_crawler_names" {
  description = "Nombres de los crawlers de Glue"
  value       = module.processing.glue_crawler_names
}

output "glue_job_name" {
  description = "Nombre del job de Glue"
  value       = module.processing.glue_job_name
}

output "kinesis_stream_name" {
  description = "Nombre del stream de Kinesis"
  value       = module.processing.kinesis_stream_name
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB"
  value       = module.processing.dynamodb_table_name
}

# Outputs del módulo de analítica
output "redshift_cluster_endpoint" {
  description = "Endpoint del cluster de Redshift (solo en producción)"
  sensitive   = true
  value       = var.environment == "prod" ? module.analytics.redshift_cluster_endpoint : "No disponible en ambiente ${var.environment}"
}

# Outputs del módulo de monitoreo
output "cloudwatch_dashboard_url" {
  description = "URL del dashboard de CloudWatch"
  value       = module.monitoring.cloudwatch_dashboard_url
}

output "sns_topic_arn" {
  description = "ARN del topic SNS para notificaciones"
  value       = module.monitoring.sns_topic_arn
}

# Salidas del módulo de descarga de datos
output "kaggle_downloader_lambda_function" {
  description = "Nombre de la función Lambda para descargar datos de Kaggle"
  value       = module.data_ingestion.lambda_function_name
}

output "kaggle_download_schedule" {
  description = "Nombre de la regla de CloudWatch Events para la descarga programada"
  value       = module.data_ingestion.cloudwatch_event_rule_name
}
*/ 