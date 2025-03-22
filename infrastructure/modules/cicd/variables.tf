variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "branch_name" {
  description = "Nombre de la rama a desplegar"
  type        = string
  default     = "main"
}

variable "terraform_version" {
  description = "Versión de Terraform a utilizar"
  type        = string
  default     = "1.5.0"
}

variable "pipeline_alert_emails" {
  description = "Lista de correos electrónicos para alertas del pipeline"
  type        = list(string)
}

variable "build_timeout" {
  description = "Tiempo máximo de construcción en minutos"
  type        = number
  default     = 30
}

variable "build_compute_type" {
  description = "Tipo de instancia para construcción"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
  description = "Imagen de Docker para construcción"
  type        = string
  default     = "aws/codebuild/standard:5.0"
}

variable "enable_auto_rollback" {
  description = "Habilitar rollback automático en caso de fallo"
  type        = bool
  default     = true
}

variable "deployment_config" {
  description = "Configuración de despliegue (BLUE_GREEN o IN_PLACE)"
  type        = string
  default     = "BLUE_GREEN"
}

variable "termination_wait_time" {
  description = "Tiempo de espera antes de terminar instancias antiguas (minutos)"
  type        = number
  default     = 5
}

variable "enable_notifications" {
  description = "Habilitar notificaciones de pipeline"
  type        = bool
  default     = true
}

variable "artifacts_retention_days" {
  description = "Días de retención de artefactos en S3"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

variable "repository_name" {
  description = "Nombre del repositorio en CodeCommit"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN de la llave KMS para encriptar artefactos"
  type        = string
}

variable "notification_arn" {
  description = "ARN del tema SNS para notificaciones"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  type        = string
}

variable "ecs_service_name" {
  description = "Nombre del servicio ECS"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN del listener del Application Load Balancer"
  type        = string
}

variable "target_group_name" {
  description = "Nombre del grupo objetivo del ALB"
  type        = string
}

variable "test_listener_arn" {
  description = "ARN del listener de prueba del Application Load Balancer"
  type        = string
} 