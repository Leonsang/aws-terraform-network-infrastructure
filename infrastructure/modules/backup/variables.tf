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

variable "kms_key_arn" {
  description = "ARN de la llave KMS para encriptar los backups"
  type        = string
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

variable "daily_backup_schedule" {
  description = "Expresión cron para respaldos diarios"
  type        = string
  default     = "cron(0 1 ? * * *)"  # 1 AM UTC todos los días
}

variable "weekly_backup_schedule" {
  description = "Expresión cron para respaldos semanales"
  type        = string
  default     = "cron(0 2 ? * SUN *)"  # 2 AM UTC todos los domingos
}

variable "monthly_backup_schedule" {
  description = "Expresión cron para respaldos mensuales"
  type        = string
  default     = "cron(0 3 1 * ? *)"  # 3 AM UTC el primer día de cada mes
}

variable "daily_retention_days" {
  description = "Días de retención para respaldos diarios"
  type        = number
  default     = 7
}

variable "weekly_retention_days" {
  description = "Días de retención para respaldos semanales"
  type        = number
  default     = 30
}

variable "monthly_retention_days" {
  description = "Días de retención para respaldos mensuales"
  type        = number
  default     = 365
}

variable "dr_region" {
  description = "Región para disaster recovery"
  type        = string
  default     = "us-west-2"  # Región alternativa por defecto
}

variable "dr_vault_arn" {
  description = "ARN del vault de DR en otra región para copias de backups mensuales"
  type        = string
}

variable "backup_alert_emails" {
  description = "Lista de correos electrónicos para alertas de respaldo"
  type        = list(string)
  default     = []
}

variable "enable_cross_region_backup" {
  description = "Habilitar respaldo entre regiones"
  type        = bool
  default     = true
}

variable "backup_resources" {
  description = "Lista de ARNs de recursos para respaldar"
  type        = list(string)
  default     = []
}

variable "backup_selection_tags" {
  description = "Tags adicionales para selección de recursos a respaldar"
  type        = map(string)
  default     = {}
}

variable "allowed_principal_arns" {
  description = "Lista de ARNs de principales permitidos para eliminar puntos de recuperación"
  type        = list(string)
  default     = []
}

variable "notification_emails" {
  description = "Lista de correos electrónicos para notificaciones de backup"
  type        = list(string)
} 