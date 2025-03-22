output "monthly_budget_arn" {
  description = "ARN del presupuesto mensual"
  value       = aws_budgets_budget.monthly.arn
}

output "service_budget_arns" {
  description = "ARNs de los presupuestos por servicio"
  value       = { for k, v in aws_budgets_budget.service_budgets : k => v.arn }
}

output "cost_report_name" {
  description = "Nombre del reporte de costos"
  value       = aws_cur_report_definition.main.report_name
}

output "cost_report_bucket" {
  description = "Bucket donde se almacenan los reportes de costos"
  value       = aws_cur_report_definition.main.s3_bucket
}

output "anomaly_monitor_arn" {
  description = "ARN del monitor de anomalías"
  value       = aws_ce_anomaly_monitor.main.arn
}

output "anomaly_subscription_arn" {
  description = "ARN de la suscripción a anomalías"
  value       = aws_ce_anomaly_subscription.main.arn
}

output "cost_category_arn" {
  description = "ARN de la categoría de costos"
  value       = aws_ce_cost_category.environment.arn
}

output "dashboard_name" {
  description = "Nombre del dashboard de costos"
  value       = aws_cloudwatch_dashboard.costs.dashboard_name
}

output "monthly_budget_alarm_arn" {
  description = "ARN de la alarma de presupuesto mensual"
  value       = aws_cloudwatch_metric_alarm.monthly_budget.arn
}

output "dashboard_url" {
  description = "URL del dashboard de costos"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.costs.dashboard_name}"
}

output "cost_explorer_url" {
  description = "URL de Cost Explorer"
  value       = "https://console.aws.amazon.com/cost-management/home?region=${var.region}#/cost-explorer"
}

output "budgets_url" {
  description = "URL de la página de presupuestos"
  value       = "https://console.aws.amazon.com/billing/home?region=${var.region}#/budgets"
} 