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

variable "account_id" {
  description = "ID de la cuenta de AWS"
  type        = string
}

variable "processed_data_bucket_arn" {
  description = "ARN del bucket S3 con datos procesados"
  type        = string
}

variable "athena_output_bucket_arn" {
  description = "ARN del bucket S3 para resultados de Athena"
  type        = string
}

variable "glue_database_name" {
  description = "Nombre de la base de datos en Glue"
  type        = string
}

variable "athena_data_source_arn" {
  description = "ARN del origen de datos de Athena"
  type        = string
}

variable "quicksight_principal_arn" {
  description = "ARN del principal de QuickSight (usuario o grupo)"
  type        = string
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
} 