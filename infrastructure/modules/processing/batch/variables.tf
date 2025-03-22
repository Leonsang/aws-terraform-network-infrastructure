variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

# Buckets
variable "raw_bucket_arn" {
  description = "ARN of the raw data bucket"
  type        = string
}

variable "raw_bucket_name" {
  description = "Name of the raw data bucket"
  type        = string
}

variable "processed_bucket_name" {
  description = "Name of the processed data bucket"
  type        = string
}

variable "processed_bucket_arn" {
  description = "ARN of the processed data bucket"
  type        = string
}

variable "feature_store_bucket_name" {
  description = "Name of the feature store bucket"
  type        = string
}

variable "feature_store_bucket_arn" {
  description = "ARN of the feature store bucket"
  type        = string
}

variable "scripts_bucket" {
  description = "Name of the scripts bucket"
  type        = string
}

# Seguridad
variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  type        = string
}

variable "security_group_ids" {
  description = "IDs of security groups"
  type        = list(string)
}

# IAM
variable "glue_role_arn" {
  description = "ARN of the Glue IAM role"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  type        = string
}

# Kinesis
variable "kinesis_shard_count" {
  description = "Number of shards for the Kinesis stream"
  type        = number
  default     = 1
}

variable "kinesis_retention_period" {
  description = "Retention period for Kinesis records (hours)"
  type        = number
  default     = 24
}

# Lambda
variable "lambda_runtime" {
  description = "Runtime for Lambda functions"
  type        = string
  default     = "python3.9"
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions (seconds)"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Memory allocated to Lambda functions (MB)"
  type        = number
  default     = 512
}

# Variables para configuración de Glue
variable "glue_job_timeout" {
  description = "Tiempo máximo de ejecución para jobs de Glue (minutos)"
  type        = number
  default     = 60
}

variable "glue_job_bookmarks" {
  description = "Habilitar bookmarks para jobs de Glue"
  type        = bool
  default     = true
}

variable "glue_worker_type" {
  description = "Tipo de worker para jobs de Glue"
  type        = string
  default     = "G.1X"
}

variable "glue_number_of_workers" {
  description = "Número de workers para jobs de Glue"
  type        = number
  default     = 2
}

# Variables para Step Functions
variable "schedule_expression" {
  description = "Expresión cron para la programación del pipeline ETL"
  type        = string
  default     = "cron(0 0 * * ? *)" # Diariamente a medianoche
}

variable "retry_attempts" {
  description = "Número de intentos de reintento para tareas fallidas"
  type        = number
  default     = 2
}

variable "retry_interval" {
  description = "Intervalo entre reintentos (segundos)"
  type        = number
  default     = 60
}

variable "private_subnet_ids" {
  description = "IDs of private subnets"
  type        = list(string)
}

variable "create_iam_roles" {
  description = "Si se deben crear los roles IAM"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "ARN del topic SNS para notificaciones"
  type        = string
} 