variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "athena_database_bucket" {
  description = "Bucket S3 para la base de datos de Athena"
  type        = string
}

variable "athena_output_bucket" {
  description = "Bucket S3 para los resultados de las consultas"
  type        = string
}

variable "processed_bucket" {
  description = "Bucket S3 con los datos procesados"
  type        = string
}

variable "failed_queries_threshold" {
  description = "Umbral para alarmas de consultas fallidas"
  type        = number
  default     = 5
}

variable "alarm_actions" {
  description = "Acciones para las alarmas de CloudWatch"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
} 