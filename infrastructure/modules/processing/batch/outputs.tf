output "glue_job_name" {
  description = "Name of the Glue job"
  value       = aws_glue_job.processing.name
}

output "glue_database_name" {
  description = "Name of the Glue database"
  value       = aws_glue_catalog_database.main.name
}

output "glue_crawler_name" {
  description = "Name of the Glue crawler"
  value       = aws_glue_crawler.main.name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "kinesis_stream_name" {
  description = "Name of the Kinesis stream"
  value       = aws_kinesis_stream.main.name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.main.name
} 