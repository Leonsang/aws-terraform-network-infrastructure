output "glue_job_names" {
  description = "Names of the Glue jobs"
  value       = [module.batch.glue_job_name]
}

output "glue_database_name" {
  description = "Name of the Glue database"
  value       = module.batch.glue_database_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.batch.ecs_cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.batch.ecs_service_name
}

output "kinesis_stream_name" {
  description = "Name of the Kinesis stream"
  value       = module.batch.kinesis_stream_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.batch.dynamodb_table_name
}

output "glue_crawler_names" {
  description = "Names of the Glue crawlers"
  value       = [module.batch.glue_crawler_name]
}

output "log_group_name" {
  description = "Nombre del grupo de logs de CloudWatch"
  value       = aws_cloudwatch_log_group.processing.name
} 