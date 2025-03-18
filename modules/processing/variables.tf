# Variables para el módulo de procesamiento

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "Región de AWS donde se crearán los recursos"
  type        = string
}

# Variables para buckets
variable "raw_bucket_name" {
  description = "Nombre del bucket S3 para datos raw"
  type        = string
}

variable "proc_bucket_name" {
  description = "Nombre del bucket S3 para datos procesados"
  type        = string
}

variable "analy_bucket_name" {
  description = "Nombre del bucket S3 para datos analíticos"
  type        = string
}

# Variables para Glue
variable "glue_worker_type" {
  description = "Tipo de worker para el job de Glue"
  type        = string
  default     = "G.1X"
}

variable "glue_number_of_workers" {
  description = "Número de workers para el job de Glue"
  type        = number
  default     = 2
}

variable "glue_timeout" {
  description = "Tiempo máximo de ejecución para el job de Glue en minutos"
  type        = number
  default     = 60
}

variable "glue_role_arn" {
  description = "ARN del rol IAM para Glue"
  type        = string
}

# Variables para Kinesis
variable "kinesis_shard_count" {
  description = "Número de shards para el stream de Kinesis"
  type        = number
  default     = 1
}

variable "kinesis_retention_period" {
  description = "Período de retención en horas para el stream de Kinesis"
  type        = number
  default     = 24
}

# Variables para DynamoDB
variable "dynamodb_read_capacity" {
  description = "Capacidad de lectura para la tabla DynamoDB"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "Capacidad de escritura para la tabla DynamoDB"
  type        = number
  default     = 5
}

# Variables para Lambda
variable "lambda_memory_size" {
  description = "Memoria asignada para las funciones Lambda en MB"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Tiempo máximo de ejecución para las funciones Lambda en segundos"
  type        = number
  default     = 300
}

variable "lambda_role_arn" {
  description = "ARN del rol IAM para Lambda"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN de la clave KMS para encriptación"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegarán las funciones Lambda"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subredes privadas para las funciones Lambda"
  type        = list(string)
}

variable "crawler_schedule" {
  description = "Programación del crawler de Glue en formato cron"
  type        = string
  default     = "cron(0 */6 * * ? *)"  # Cada 6 horas
}

variable "alert_email" {
  description = "Correo electrónico para recibir alertas"
  type        = string
}

variable "log_retention_days" {
  description = "Número de días para retener los logs en CloudWatch"
  type        = number
  default     = 30
}

# Tags
variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
} 