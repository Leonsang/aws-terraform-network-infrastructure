# Outputs del módulo de procesamiento

output "glue_database_name" {
  description = "Nombre de la base de datos de Glue"
  value       = aws_glue_catalog_database.fraud_db.name
}

output "glue_crawler_name" {
  description = "Nombre del crawler de Glue"
  value       = aws_glue_crawler.raw_crawler.name
}

output "glue_job_name" {
  description = "Nombre del job de ETL en Glue"
  value       = aws_glue_job.etl_job.name
}

output "glue_role_arn" {
  description = "ARN del rol IAM para Glue"
  value       = aws_iam_role.glue_role.arn
}

output "kinesis_stream_name" {
  description = "Nombre del stream de Kinesis"
  value       = aws_kinesis_stream.transaction_stream.name
}

output "kinesis_stream_arn" {
  description = "ARN del stream de Kinesis"
  value       = aws_kinesis_stream.transaction_stream.arn
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB"
  value       = aws_dynamodb_table.card_stats.name
}

output "dynamodb_table_arn" {
  description = "ARN de la tabla DynamoDB"
  value       = aws_dynamodb_table.card_stats.arn
}

output "data_validation_lambda_name" {
  description = "Nombre de la función Lambda de validación de datos"
  value       = aws_lambda_function.data_validation.function_name
}

output "data_validation_lambda_arn" {
  description = "ARN de la función Lambda de validación de datos"
  value       = aws_lambda_function.data_validation.arn
}

output "realtime_processing_lambda_name" {
  description = "Nombre de la función Lambda de procesamiento en tiempo real"
  value       = aws_lambda_function.realtime_processing.function_name
}

output "realtime_processing_lambda_arn" {
  description = "ARN de la función Lambda de procesamiento en tiempo real"
  value       = aws_lambda_function.realtime_processing.arn
}

output "fraud_alerts_topic_arn" {
  description = "ARN del topic SNS para alertas de fraude"
  value       = aws_sns_topic.fraud_alerts.arn
}

output "processing_success_topic_arn" {
  description = "ARN del topic SNS para notificaciones de éxito en el procesamiento"
  value       = aws_sns_topic.processing_success.arn
}

output "lambda_security_group_id" {
  description = "ID del grupo de seguridad para las funciones Lambda"
  value       = aws_security_group.lambda.id
}

output "cloudwatch_log_groups" {
  description = "Nombres de los grupos de logs en CloudWatch"
  value = {
    data_validation     = aws_cloudwatch_log_group.data_validation.name
    realtime_processing = aws_cloudwatch_log_group.realtime_processing.name
  }
}

output "cloudwatch_alarms" {
  description = "Nombres de las alarmas en CloudWatch"
  value = {
    lambda_errors      = aws_cloudwatch_metric_alarm.lambda_errors.alarm_name
    kinesis_iterator   = aws_cloudwatch_metric_alarm.kinesis_iterator_age.alarm_name
  }
} 