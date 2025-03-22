variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
}

variable "log_retention_days" {
  description = "Días de retención para los logs en CloudWatch"
  type        = number
  default     = 30
}

variable "metrics_transition_days" {
  description = "Días antes de transicionar las métricas a IA"
  type        = number
  default     = 30
}

variable "metrics_retention_days" {
  description = "Días de retención para las métricas"
  type        = number
  default     = 90
}

variable "lambda_error_threshold" {
  description = "Umbral de errores para las funciones Lambda"
  type        = number
  default     = 5
}

variable "api_latency_threshold" {
  description = "Umbral de latencia (ms) para API Gateway"
  type        = number
  default     = 1000
}

variable "monitoring_bucket_name" {
  description = "Nombre del bucket para datos de monitoreo"
  type        = string
}

variable "monitoring_bucket_arn" {
  description = "ARN del bucket para datos de monitoreo"
  type        = string
}

variable "endpoint_name" {
  description = "Nombre del endpoint de SageMaker a monitorear (opcional)"
  type        = string
  default     = ""
}

variable "monitoring_schedule" {
  description = "Expresión cron para programar el monitoreo"
  type        = string
  default     = "cron(0 * ? * * *)"  # Cada hora
}

variable "drift_threshold" {
  description = "Umbral para alertas de drift"
  type        = number
  default     = 0.3  # 30% de drift
}

variable "alarm_actions" {
  description = "Lista de ARNs para las acciones de alarma"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
}

variable "create_metrics_bucket" {
  description = "Si se debe crear el bucket de métricas o no"
  type        = bool
  default     = false
}

variable "existing_metrics_bucket_arn" {
  description = "ARN del bucket de métricas existente cuando create_metrics_bucket es false"
  type        = string
  default     = ""
} 