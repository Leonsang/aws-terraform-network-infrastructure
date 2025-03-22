output "lambda_function_name" {
  description = "Nombre de la función Lambda de descarga"
  value       = aws_lambda_function.kaggle_downloader.function_name
}

output "lambda_function_arn" {
  description = "ARN de la función Lambda de descarga"
  value       = aws_lambda_function.kaggle_downloader.arn
}

output "lambda_layer_arn" {
  description = "ARN de la capa Lambda de Kaggle"
  value       = aws_lambda_layer_version.kaggle_layer.arn
}

output "cloudwatch_log_group_name" {
  description = "Nombre del grupo de logs en CloudWatch"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "event_rule_name" {
  description = "Nombre de la regla de EventBridge"
  value       = aws_cloudwatch_event_rule.schedule.name
}

output "kaggle_layer_arn" {
  description = "ARN de la capa Lambda de Kaggle"
  value       = aws_lambda_layer_version.kaggle_layer.arn
}

output "raw_data_path" {
  description = "Ruta de los datos crudos"
  value       = "s3://${var.raw_bucket_name}/raw-data"
}

output "kaggle_downloader_function_name" {
  description = "Nombre de la función Lambda de descarga de Kaggle"
  value       = aws_lambda_function.kaggle_downloader.function_name
}

output "kaggle_download_status" {
  description = "Estado de la última descarga de Kaggle"
  value       = "Pending"  # Este valor debería ser actualizado dinámicamente
}

output "cloudwatch_event_rule_name" {
  description = "Name of the CloudWatch Event rule for data ingestion"
  value       = aws_cloudwatch_event_rule.schedule.name
}

output "log_group_name" {
  description = "Name of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.data_ingestion.name
} 