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

variable "monthly_budget_amount" {
  description = "Monto máximo mensual en USD para el presupuesto general"
  type        = number
}

variable "sagemaker_budget_amount" {
  description = "Monto máximo mensual en USD para el presupuesto de SageMaker"
  type        = number
}

variable "daily_cost_threshold" {
  description = "Umbral diario en USD para alertas de costos"
  type        = number
}

variable "alert_emails" {
  description = "Lista de correos electrónicos para recibir alertas de costos"
  type        = list(string)
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
} 