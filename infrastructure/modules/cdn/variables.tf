variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
}

variable "origin_domain_name" {
  description = "Nombre de dominio del origen (ALB o S3)"
  type        = string
}

variable "cloudfront_price_class" {
  description = "Clase de precio de CloudFront (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
}

variable "min_ttl" {
  description = "Tiempo mínimo de vida en caché (segundos)"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Tiempo de vida por defecto en caché (segundos)"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Tiempo máximo de vida en caché (segundos)"
  type        = number
  default     = 86400
}

variable "rate_limit" {
  description = "Límite de solicitudes por IP en 5 minutos"
  type        = number
  default     = 2000
}

variable "blocked_ips" {
  description = "Lista de IPs a bloquear"
  type        = list(string)
  default     = []
}

variable "custom_error_responses" {
  description = "Configuración de respuestas de error personalizadas"
  type = list(object({
    error_code            = number
    response_code         = number
    response_page_path    = string
    error_caching_min_ttl = number
  }))
  default = []
}

variable "geo_restriction_type" {
  description = "Tipo de restricción geográfica (none, whitelist, blacklist)"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "Lista de códigos de país para restricción geográfica"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN del certificado ACM para HTTPS (opcional)"
  type        = string
  default     = null
}

variable "blocked_requests_threshold" {
  description = "Umbral de solicitudes bloqueadas para alarma"
  type        = number
  default     = 100
}

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