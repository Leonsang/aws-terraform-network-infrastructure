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

variable "account_id" {
  description = "ID de la cuenta de AWS"
  type        = string
}

variable "log_retention_days" {
  description = "Días de retención para los logs de auditoría"
  type        = number
  default     = 365
}

variable "compliance_alert_emails" {
  description = "Lista de correos electrónicos para alertas de compliance"
  type        = list(string)
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "ARN de la llave KMS para encriptación"
  type        = string
}

variable "notification_topic_arn" {
  description = "ARN del topic SNS para notificaciones"
  type        = string
}

variable "guardduty_frequency" {
  description = "Frecuencia de publicación de hallazgos de GuardDuty (FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS)"
  type        = string
  default     = "ONE_HOUR"
}

variable "enable_security_hub" {
  description = "Habilitar Security Hub"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Habilitar GuardDuty"
  type        = bool
  default     = true
}

variable "enable_audit_manager" {
  description = "Habilitar Audit Manager"
  type        = bool
  default     = true
}

variable "config_rules" {
  description = "Lista de reglas de AWS Config a habilitar"
  type        = list(string)
  default     = [
    "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED",
    "S3_BUCKET_VERSIONING_ENABLED",
    "RDS_STORAGE_ENCRYPTED",
    "VPC_FLOW_LOGS_ENABLED"
  ]
}

variable "security_standards" {
  description = "Lista de estándares de seguridad a habilitar en Security Hub"
  type        = list(string)
  default     = [
    "CIS AWS Foundations Benchmark v1.4.0",
    "PCI DSS v3.2.1"
  ]
}

variable "audit_assessment_reports_destination" {
  description = "Destino para los reportes de evaluación de Audit Manager"
  type        = string
  default     = "S3"
}

variable "enable_config_aggregator" {
  description = "Habilitar agregador de AWS Config para múltiples cuentas/regiones"
  type        = bool
  default     = false
}

variable "enable_security_hub_aggregator" {
  description = "Habilitar agregador de Security Hub para múltiples cuentas/regiones"
  type        = bool
  default     = false
}

variable "compliance_notification_frequency" {
  description = "Frecuencia de notificaciones de compliance (en minutos)"
  type        = number
  default     = 60
}

variable "enable_continuous_monitoring" {
  description = "Habilitar monitoreo continuo de compliance"
  type        = bool
  default     = true
}

variable "enable_automated_remediation" {
  description = "Habilitar remediación automática de problemas de compliance"
  type        = bool
  default     = false
}

variable "remediation_concurrent_executions" {
  description = "Número máximo de ejecuciones concurrentes de remediación"
  type        = number
  default     = 10
}

variable "enable_findings_export" {
  description = "Habilitar exportación de hallazgos a S3"
  type        = bool
  default     = true
} 