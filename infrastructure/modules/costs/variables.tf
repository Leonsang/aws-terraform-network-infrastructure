variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "Región de AWS"
  type        = string
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

variable "monthly_budget_amount" {
  description = "Monto del presupuesto mensual en USD"
  type        = number
}

variable "budget_alert_threshold" {
  description = "Porcentaje del presupuesto para alertas (ej: 80)"
  type        = number
  default     = 80
}

variable "alert_emails" {
  description = "Lista de correos electrónicos para alertas de costos"
  type        = list(string)
}

variable "cost_alert_emails" {
  description = "List of email addresses to receive cost alerts"
  type        = list(string)
  default     = ["admin@example.com"]
}

variable "service_budget_amounts" {
  description = "Mapa de presupuestos por servicio (ej: {'EC2' = 100, 'RDS' = 50})"
  type        = map(number)
  default     = {}
}

variable "cost_report_bucket_name" {
  description = "Nombre del bucket S3 para reportes de costos"
  type        = string
}

variable "anomaly_threshold" {
  description = "Umbral para detección de anomalías en costos (USD)"
  type        = number
  default     = 100
}

variable "savings_threshold" {
  description = "Umbral para recomendaciones de Savings Plans (USD)"
  type        = number
  default     = 1000
}

variable "alarm_actions" {
  description = "Lista de ARNs para acciones de alarma"
  type        = list(string)
  default     = []
}

variable "enable_cost_explorer" {
  description = "Habilitar Cost Explorer"
  type        = bool
  default     = true
}

variable "enable_savings_plans" {
  description = "Habilitar recomendaciones de Savings Plans"
  type        = bool
  default     = true
}

variable "cost_allocation_tags" {
  description = "Lista de tags para asignación de costos"
  type        = list(string)
  default     = ["Environment", "Project", "CostCenter"]
}

variable "report_frequency" {
  description = "Frecuencia de generación de reportes (DAILY, MONTHLY)"
  type        = string
  default     = "DAILY"
}

variable "report_versioning" {
  description = "Versionamiento de reportes (CREATE_NEW_REPORT, OVERWRITE_REPORT)"
  type        = string
  default     = "OVERWRITE_REPORT"
}

variable "budget_time_unit" {
  description = "Unidad de tiempo para presupuestos (MONTHLY, QUARTERLY, ANNUALLY)"
  type        = string
  default     = "MONTHLY"
}

variable "enable_detailed_monitoring" {
  description = "Habilitar monitoreo detallado de costos"
  type        = bool
  default     = true
} 