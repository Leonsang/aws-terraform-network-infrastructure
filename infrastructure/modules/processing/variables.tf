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

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "IDs of security groups"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  type        = string
}

# Variables para buckets
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

# Variables para Kaggle
variable "kaggle_layer_arn" {
  description = "ARN of the Kaggle Lambda layer"
  type        = string
}

variable "raw_data_path" {
  description = "Path to raw data in S3"
  type        = string
}

# Variables para IAM
variable "glue_role_arn" {
  description = "ARN of the Glue IAM role"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  type        = string
}

# Variables para Kinesis
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

# Variables para Lambda
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

variable "app_cpu" {
  description = "CPU units for the app container"
  type        = number
  default     = 256
}

variable "app_memory" {
  description = "Memory for the app container"
  type        = number
  default     = 512
}

variable "app_image" {
  description = "Docker image for the app container"
  type        = string
  default     = "nginx:latest"
}

variable "app_desired_count" {
  description = "Desired number of app containers"
  type        = number
  default     = 2
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN del topic SNS para notificaciones"
  type        = string
}

# Variables para Glue
variable "glue_version" {
  description = "Versión de AWS Glue"
  type        = string
  default     = "3.0"
}

variable "glue_python_version" {
  description = "Versión de Python para Glue"
  type        = string
  default     = "3"
}

variable "worker_type" {
  description = "Tipo de worker para Glue"
  type        = string
  default     = "G.1X"
}

variable "number_of_workers" {
  description = "Número de workers para Glue"
  type        = number
  default     = 2
}

variable "glue_jobs" {
  description = "Mapa de jobs de Glue a crear"
  type = map(object({
    script_path         = string
    max_concurrent_runs = number
    max_retries        = number
    timeout_minutes    = number
    arguments          = map(string)
  }))
  default = {}
}

variable "default_arguments" {
  description = "Argumentos por defecto para todos los jobs de Glue"
  type        = map(string)
  default = {
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--enable-spark-ui"                 = "true"
    "--enable-job-insights"            = "true"
    "--job-bookmark-option"           = "job-bookmark-enable"
  }
} 