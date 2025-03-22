# Outputs del proyecto de Detección de Fraude Financiero

# Outputs de Networking
output "vpc_id" {
  description = "ID de la VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs de las subredes públicas"
  value       = module.networking.public_subnet_ids
}

# Outputs de Storage
output "raw_bucket_name" {
  description = "Nombre del bucket de datos crudos"
  value       = module.storage.raw_bucket_name
}

output "processed_bucket_name" {
  description = "Nombre del bucket de datos procesados"
  value       = module.storage.processed_bucket_name
}

output "analytics_bucket_name" {
  description = "Nombre del bucket de analytics"
  value       = module.storage.analytics_bucket_name
}

# Outputs de Processing
output "glue_database_name" {
  description = "Nombre de la base de datos de Glue"
  value       = module.processing.glue_database_name
}

output "glue_job_names" {
  description = "Nombres de los jobs de Glue"
  value       = module.processing.glue_job_names
}

# Outputs del módulo de analítica
output "redshift_cluster_endpoint" {
  description = "Endpoint del cluster de Redshift"
  sensitive   = true
  value       = module.analytics.redshift_cluster_endpoint
}

output "redshift_cluster_id" {
  description = "ID del cluster de Redshift"
  value       = module.analytics.redshift_cluster_id
}

# Outputs del módulo de monitoreo
output "sns_topic_arn" {
  description = "ARN del topic SNS para notificaciones"
  value       = module.monitoring.sns_topic_arn
}

# Outputs del módulo de seguridad
output "kms_key_arn" {
  description = "ARN de la clave KMS"
  value       = module.security.kms_key_arn
}

output "lambda_role_arn" {
  description = "ARN del rol IAM para funciones Lambda"
  value       = module.security.lambda_role_arn
}

output "glue_role_arn" {
  description = "ARN del rol IAM para trabajos de Glue"
  value       = module.security.glue_role_arn
}

output "redshift_role_arn" {
  description = "ARN del rol IAM para Redshift"
  value       = module.security.redshift_role_arn
}

# Outputs del módulo de ingesta de datos
output "kaggle_downloader_function_name" {
  description = "Nombre de la función Lambda para descargar datos de Kaggle"
  value       = module.data_ingestion.lambda_function_name
}

# Outputs del módulo de logging
output "log_group_name" {
  description = "Nombre del grupo de logs"
  value       = module.logging.log_group_name
}

output "firehose_stream_name" {
  description = "Nombre del stream de Firehose"
  value       = module.logging.firehose_stream_name
}

# Outputs del módulo de compliance
output "guardduty_detector_id" {
  description = "ID del detector de GuardDuty"
  value       = module.compliance.guardduty_detector_id
}

# Outputs del módulo de documentación
output "documentation_bucket_name" {
  description = "Nombre del bucket de documentación"
  value       = module.documentation.documentation_bucket_name
}

# Outputs del módulo de API
output "api_gateway_url" {
  description = "URL del API Gateway"
  value       = module.api.api_gateway_url
} 