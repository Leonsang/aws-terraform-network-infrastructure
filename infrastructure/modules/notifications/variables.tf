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

variable "slack_webhook_url" {
  description = "URL del webhook de Slack para notificaciones"
  type        = string
}

variable "email_subscribers" {
  description = "Lista de direcciones de correo para notificaciones"
  type        = list(string)
  default     = []
}

variable "high_risk_threshold" {
  description = "Umbral para alertas de alto riesgo en 5 minutos"
  type        = number
  default     = 10
}

# Variables para SNS
variable "email_subscriptions" {
  description = "Lista de direcciones de correo electrónico para suscripciones"
  type        = list(string)
  default     = []
}

variable "sms_subscriptions" {
  description = "Lista de números telefónicos para suscripciones SMS"
  type        = list(string)
  default     = []
}

# Variables para SQS
variable "sqs_delay_seconds" {
  description = "Tiempo de retraso para mensajes en segundos"
  type        = number
  default     = 0
}

variable "sqs_max_message_size" {
  description = "Tamaño máximo de mensaje en bytes"
  type        = number
  default     = 262144
}

variable "sqs_message_retention_seconds" {
  description = "Tiempo de retención de mensajes en segundos"
  type        = number
  default     = 345600
}

variable "sqs_visibility_timeout_seconds" {
  description = "Tiempo de visibilidad del mensaje en segundos"
  type        = number
  default     = 30
}

variable "sqs_max_receive_count" {
  description = "Número máximo de intentos de procesamiento antes de enviar a DLQ"
  type        = number
  default     = 3
}

# Variables para Webhooks
variable "enable_webhooks" {
  description = "Habilitar integración con webhooks"
  type        = bool
  default     = false
}

variable "webhook_urls" {
  description = "Lista de URLs de webhooks para notificaciones"
  type        = list(string)
  default     = []
}

# Variables para Alarmas
variable "dlq_messages_threshold" {
  description = "Umbral de mensajes en DLQ para alarma"
  type        = number
  default     = 1
}

variable "failed_notifications_threshold" {
  description = "Umbral de notificaciones fallidas para alarma"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
} 