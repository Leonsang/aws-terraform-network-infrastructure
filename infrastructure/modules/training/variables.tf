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

variable "feature_store_bucket_name" {
  description = "Nombre del bucket que contiene las features"
  type        = string
}

variable "feature_store_bucket_arn" {
  description = "ARN del bucket que contiene las features"
  type        = string
}

variable "model_artifacts_bucket_name" {
  description = "Nombre del bucket para artefactos del modelo"
  type        = string
}

variable "model_artifacts_bucket_arn" {
  description = "ARN del bucket para artefactos del modelo"
  type        = string
}

variable "training_instance_type" {
  description = "Tipo de instancia para el entrenamiento"
  type        = string
  default     = "ml.m5.xlarge"
}

variable "training_instance_count" {
  description = "Número de instancias para el entrenamiento"
  type        = number
  default     = 1
}

variable "endpoint_instance_type" {
  description = "Tipo de instancia para el endpoint"
  type        = string
  default     = "ml.t2.medium"
}

variable "endpoint_instance_count" {
  description = "Número de instancias para el endpoint"
  type        = number
  default     = 1
}

variable "training_schedule" {
  description = "Expresión cron para programar el entrenamiento"
  type        = string
  default     = "cron(0 0 1 * ? *)"  # Primer día de cada mes a las 00:00 UTC
}

variable "training_image" {
  description = "URI de la imagen de entrenamiento de SageMaker"
  type        = string
}

variable "alarm_actions" {
  description = "Lista de ARNs para acciones de alarma"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
} 