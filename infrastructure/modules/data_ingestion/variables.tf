variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
}

variable "account_id" {
  description = "ID de la cuenta de AWS"
  type        = string
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

variable "kaggle_username" {
  description = "Nombre de usuario de Kaggle"
  type        = string
}

variable "kaggle_key" {
  description = "Clave de API de Kaggle"
  type        = string
}

variable "raw_bucket_name" {
  description = "Nombre del bucket S3 para datos raw"
  type        = string
}

variable "download_schedule" {
  description = "Expresión cron para la programación de descargas"
  type        = string
  default     = "cron(0 0 * * ? *)"  # Diariamente a medianoche UTC
}

variable "log_retention_days" {
  description = "Días de retención de logs"
  type        = number
  default     = 30
}

variable "alert_email" {
  description = "Correo electrónico para alertas"
  type        = string
} 