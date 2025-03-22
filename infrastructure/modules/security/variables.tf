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

variable "waf_rate_limit" {
  description = "Límite de requests por IP en 5 minutos"
  type        = number
  default     = 2000
}

variable "blocked_ips" {
  description = "Lista de IPs a bloquear"
  type        = list(string)
  default     = []
}

variable "security_alert_emails" {
  description = "Lista de correos electrónicos para alertas de seguridad"
  type        = list(string)
}

variable "waf_blocked_requests_threshold" {
  description = "Umbral de requests bloqueados para alarma"
  type        = number
  default     = 100
}

# Variables para Organizations
variable "create_organization" {
  description = "Crear una nueva organización de AWS"
  type        = bool
  default     = false
}

variable "additional_scp_statements" {
  description = "Declaraciones adicionales para la Service Control Policy"
  type        = list(any)
  default     = []
}

# Variables para Security Hub
variable "enable_security_hub" {
  description = "Habilitar Security Hub"
  type        = bool
  default     = true
}

variable "security_findings_threshold" {
  description = "Umbral para alarmas de hallazgos de seguridad"
  type        = number
  default     = 10
}

# Variables para AWS Config
variable "force_destroy_bucket" {
  description = "Permitir la eliminación del bucket incluso si contiene objetos"
  type        = bool
  default     = false
}

# Variables para IAM Password Policy
variable "minimum_password_length" {
  description = "Longitud mínima para contraseñas"
  type        = number
  default     = 14
}

variable "max_password_age" {
  description = "Edad máxima de las contraseñas en días"
  type        = number
  default     = 90
}

variable "password_reuse_prevention" {
  description = "Número de contraseñas anteriores que no se pueden reutilizar"
  type        = number
  default     = 24
}

# Variables para Alarmas
variable "alarm_actions" {
  description = "Lista de ARNs para las acciones de alarma"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
} 