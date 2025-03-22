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

variable "force_destroy_bucket" {
  description = "Permitir la eliminación del bucket incluso si contiene objetos"
  type        = bool
  default     = false
}

variable "transition_ia_days" {
  description = "Días antes de transicionar a IA"
  type        = number
  default     = 30
}

variable "transition_glacier_days" {
  description = "Días antes de transicionar a Glacier"
  type        = number
  default     = 90
}

variable "expiration_days" {
  description = "Días antes de eliminar los logs"
  type        = number
  default     = 365
}

variable "log_retention_days" {
  description = "Días de retención de logs en CloudWatch"
  type        = number
  default     = 30
}

variable "error_threshold" {
  description = "Umbral de errores para las alarmas"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "ARN de la llave KMS para encriptar los logs"
  type        = string
}

variable "logs_bucket_arn" {
  description = "ARN del bucket S3 para almacenar los logs"
  type        = string
}

variable "firehose_buffer_size" {
  description = "Tamaño del buffer de Kinesis Firehose en MB"
  type        = number
  default     = 5
}

variable "firehose_buffer_interval" {
  description = "Intervalo del buffer de Kinesis Firehose en segundos"
  type        = number
  default     = 300
}

variable "filter_pattern" {
  description = "Patrón de filtro para los logs"
  type        = string
  default     = ""
}

variable "alarm_actions" {
  description = "Lista de ARNs de acciones de alarma (SNS Topics)"
  type        = list(string)
  default     = []
}

variable "enable_log_shipping" {
  description = "Habilitar el envío de logs a S3"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Habilitar encriptación de logs"
  type        = bool
  default     = true
}

variable "log_groups_to_monitor" {
  description = "Lista de nombres de grupos de logs a monitorear"
  type        = list(string)
  default     = []
}

variable "alert_email" {
  description = "Email para alertas de logs"
  type        = string
} 