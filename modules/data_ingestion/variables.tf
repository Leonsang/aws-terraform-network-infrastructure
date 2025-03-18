# Variables para el módulo de ingesta de datos

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, test, prod)"
  type        = string
}

variable "raw_bucket_name" {
  description = "Nombre del bucket S3 para datos raw"
  type        = string
}

variable "raw_bucket_arn" {
  description = "ARN del bucket S3 para datos raw"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN del rol IAM para la función Lambda"
  type        = string
}

variable "kaggle_username" {
  description = "Nombre de usuario de Kaggle"
  type        = string
  sensitive   = true
}

variable "kaggle_key" {
  description = "API key de Kaggle"
  type        = string
  sensitive   = true
}

variable "download_schedule" {
  description = "Expresión cron para la programación de descarga de datos"
  type        = string
  default     = "cron(0 0 1 * ? *)"  # Por defecto, el primer día de cada mes a medianoche
}

variable "log_retention_days" {
  description = "Número de días para retener los logs"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags adicionales para los recursos"
  type        = map(string)
  default     = {}
} 