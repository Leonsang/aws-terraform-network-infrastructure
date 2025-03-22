variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
}

variable "scripts_bucket_id" {
  description = "ID del bucket S3 donde se almacenarán los scripts"
  type        = string
}

variable "data_bucket_id" {
  description = "ID del bucket S3 donde se almacenarán los datos"
  type        = string
}

variable "glue_version" {
  description = "Versión de Glue a utilizar"
  type        = string
  default     = "3.0"
}

variable "glue_python_version" {
  description = "Versión de Python para los trabajos de Glue"
  type        = string
  default     = "3"
}

variable "worker_type" {
  description = "Tipo de worker para los trabajos de Glue"
  type        = string
  default     = "G.1X"
}

variable "number_of_workers" {
  description = "Número de workers para los trabajos de Glue"
  type        = number
  default     = 5
}

variable "job_timeout" {
  description = "Tiempo máximo de ejecución para trabajos de Glue (minutos)"
  type        = number
  default     = 120
}

variable "default_arguments" {
  description = "Argumentos por defecto para los trabajos de Glue"
  type        = map(string)
  default = {
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
  }
}

variable "alarm_actions" {
  description = "Lista de ARNs de acciones para las alarmas de CloudWatch"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
} 