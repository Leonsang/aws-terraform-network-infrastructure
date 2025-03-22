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

variable "vpc_id" {
  description = "ID del VPC donde se desplegará el ALB"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets para el ALB"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Lista de IDs de Security Groups para el ALB"
  type        = list(string)
}

variable "internal" {
  description = "Si el ALB es interno o público"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Habilitar protección contra eliminación del ALB"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Tiempo de espera de inactividad en segundos"
  type        = number
  default     = 60
}

variable "access_logs_bucket" {
  description = "Nombre del bucket S3 para los logs de acceso"
  type        = string
}

variable "ssl_policy" {
  description = "Política SSL para el listener HTTPS"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "certificate_arn" {
  description = "ARN del certificado SSL/TLS"
  type        = string
}

variable "target_port" {
  description = "Puerto del target group"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path para el health check"
  type        = string
  default     = "/"
}

variable "enable_stickiness" {
  description = "Habilitar sticky sessions"
  type        = bool
  default     = false
}

variable "latency_threshold" {
  description = "Umbral de latencia en segundos para las alarmas"
  type        = number
  default     = 5
}

variable "error_threshold" {
  description = "Umbral de errores 5XX para las alarmas"
  type        = number
  default     = 10
}

variable "alarm_actions" {
  description = "Lista de ARNs de acciones para las alarmas"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
} 