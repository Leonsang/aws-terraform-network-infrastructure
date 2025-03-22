output "api_id" {
  description = "ID de la API Gateway"
  value       = aws_api_gateway_rest_api.fraud_api.id
}

output "api_arn" {
  description = "ARN de la API Gateway"
  value       = aws_api_gateway_rest_api.fraud_api.execution_arn
}

output "api_endpoint" {
  description = "URL del endpoint de la API"
  value       = "${aws_api_gateway_stage.api_stage.invoke_url}/"
}

output "api_stage_name" {
  description = "Nombre del stage de la API"
  value       = aws_api_gateway_stage.api_stage.stage_name
}

output "waf_web_acl_id" {
  description = "ID del Web ACL de WAF"
  value       = aws_wafv2_web_acl.api_waf.id
}

output "waf_web_acl_arn" {
  description = "ARN del Web ACL de WAF"
  value       = aws_wafv2_web_acl.api_waf.arn
}

output "auth_table_name" {
  description = "Nombre de la tabla DynamoDB de autenticación"
  value       = aws_dynamodb_table.auth.id
}

output "auth_table_arn" {
  description = "ARN de la tabla DynamoDB de autenticación"
  value       = aws_dynamodb_table.auth.arn
}

output "authorizer_lambda_arn" {
  description = "ARN de la función Lambda autorizadora"
  value       = aws_lambda_function.authorizer.arn
}

output "predict_lambda_arn" {
  description = "ARN de la función Lambda de predicción"
  value       = aws_lambda_function.predict.arn
}

output "api_log_group_name" {
  description = "Nombre del grupo de logs de CloudWatch"
  value       = aws_cloudwatch_log_group.api_logs.name
}

output "api_log_group_arn" {
  description = "ARN del grupo de logs de CloudWatch"
  value       = aws_cloudwatch_log_group.api_logs.arn
}

output "api_dashboard_name" {
  description = "Nombre del dashboard de CloudWatch"
  value       = aws_cloudwatch_dashboard.api_dashboard.dashboard_name
}

output "api_dashboard_url" {
  description = "URL del dashboard de CloudWatch"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.api_dashboard.dashboard_name}"
}

output "api_alarm_arn" {
  description = "ARN de la alarma de CloudWatch"
  value       = aws_cloudwatch_metric_alarm.api_errors.arn
}

output "api_usage_plan_id" {
  description = "ID del plan de uso de la API"
  value       = aws_api_gateway_usage_plan.api_usage_plan.id
}

output "api_usage_plan_arn" {
  description = "ARN del plan de uso de la API"
  value       = aws_api_gateway_usage_plan.api_usage_plan.arn
}

output "lambda_role_arn" {
  description = "ARN del rol IAM para Lambda"
  value       = aws_iam_role.lambda_role.arn
}

output "authorizer_role_arn" {
  description = "ARN del rol IAM para el autorizador"
  value       = aws_iam_role.authorizer_role.arn
}

output "api_configuration" {
  description = "Configuración actual de la API"
  value = {
    endpoint_type           = var.endpoint_type
    enable_xray            = var.enable_xray
    enable_caching         = var.enable_caching
    cache_ttl             = var.cache_ttl
    enable_compression     = var.enable_compression
    enable_cors           = var.enable_cors
    enable_waf_logging     = var.enable_waf_logging
    enable_api_key        = var.enable_api_key
    enable_usage_plans     = var.enable_usage_plans
    enable_custom_domain   = var.enable_custom_domain
  }
}

output "api_limits" {
  description = "Límites configurados para la API"
  value = {
    rate_limit           = var.rate_limit
    quota_limit          = var.quota_limit
    quota_period         = var.quota_period
    throttle_burst_limit = var.throttle_burst_limit
    throttle_rate_limit  = var.throttle_rate_limit
  }
}

output "api_endpoints" {
  description = "Endpoints disponibles en la API"
  value = {
    predict = "${aws_api_gateway_stage.api_stage.invoke_url}/predict"
  }
}

output "api_monitoring" {
  description = "Configuración de monitoreo de la API"
  value = {
    log_level           = var.log_level
    log_retention_days  = var.log_retention_days
    error_threshold     = var.error_threshold
  }
}

output "api_gateway_url" {
  description = "The URL of the API Gateway endpoint"
  value       = aws_api_gateway_stage.api_stage.invoke_url
} 