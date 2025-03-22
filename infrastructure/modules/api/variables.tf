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

variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

variable "endpoint_type" {
  description = "Tipo de endpoint para API Gateway (EDGE, REGIONAL, PRIVATE)"
  type        = string
  default     = "REGIONAL"
}

variable "kms_key_arn" {
  description = "ARN de la llave KMS para encriptación"
  type        = string
}

variable "model_bucket" {
  description = "Nombre del bucket S3 que contiene el modelo"
  type        = string
}

variable "model_bucket_arn" {
  description = "ARN del bucket S3 que contiene el modelo"
  type        = string
}

variable "model_key" {
  description = "Ruta del modelo en el bucket S3"
  type        = string
}

variable "lambda_timeout" {
  description = "Timeout para funciones Lambda (segundos)"
  type        = number
  default     = 30
}

variable "lambda_memory" {
  description = "Memoria asignada a funciones Lambda (MB)"
  type        = number
  default     = 512
}

variable "log_level" {
  description = "Nivel de logging (DEBUG, INFO, WARN, ERROR)"
  type        = string
  default     = "INFO"
}

variable "log_retention_days" {
  description = "Días de retención de logs"
  type        = number
  default     = 30
}

variable "log_format" {
  description = "Formato para logs de acceso de API Gateway"
  type        = string
  default     = <<EOF
{
  "requestId": "$context.requestId",
  "ip": "$context.identity.sourceIp",
  "caller": "$context.identity.caller",
  "user": "$context.identity.user",
  "requestTime": "$context.requestTime",
  "httpMethod": "$context.httpMethod",
  "resourcePath": "$context.resourcePath",
  "status": "$context.status",
  "protocol": "$context.protocol",
  "responseLength": "$context.responseLength"
}
EOF
}

variable "rate_limit" {
  description = "Límite de tasa para WAF (requests por 5 minutos)"
  type        = number
  default     = 2000
}

variable "blocked_ips" {
  description = "Lista de IPs a bloquear"
  type        = list(string)
  default     = []
}

variable "quota_limit" {
  description = "Límite de cuota para el plan de uso"
  type        = number
  default     = 10000
}

variable "quota_period" {
  description = "Periodo para la cuota (DAY, WEEK, MONTH)"
  type        = string
  default     = "MONTH"
}

variable "throttle_burst_limit" {
  description = "Límite de ráfaga para throttling"
  type        = number
  default     = 100
}

variable "throttle_rate_limit" {
  description = "Límite de tasa para throttling"
  type        = number
  default     = 50
}

variable "error_threshold" {
  description = "Umbral de errores para alarmas"
  type        = number
  default     = 10
}

variable "alarm_actions" {
  description = "Lista de ARNs para acciones de alarma"
  type        = list(string)
}

variable "enable_xray" {
  description = "Habilitar trazado con X-Ray"
  type        = bool
  default     = true
}

variable "enable_caching" {
  description = "Habilitar caché en API Gateway"
  type        = bool
  default     = false
}

variable "cache_ttl" {
  description = "TTL para caché en segundos"
  type        = number
  default     = 300
}

variable "enable_compression" {
  description = "Habilitar compresión de respuestas"
  type        = bool
  default     = true
}

variable "minimum_compression_size" {
  description = "Tamaño mínimo para compresión en bytes"
  type        = number
  default     = 1024
}

variable "enable_cors" {
  description = "Habilitar CORS"
  type        = bool
  default     = false
}

variable "allowed_origins" {
  description = "Orígenes permitidos para CORS"
  type        = list(string)
  default     = ["*"]
}

variable "allowed_methods" {
  description = "Métodos permitidos para CORS"
  type        = list(string)
  default     = ["GET", "POST", "OPTIONS"]
}

variable "allowed_headers" {
  description = "Headers permitidos para CORS"
  type        = list(string)
  default     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key"]
}

variable "enable_waf_logging" {
  description = "Habilitar logging de WAF"
  type        = bool
  default     = true
}

variable "waf_log_retention_days" {
  description = "Días de retención para logs de WAF"
  type        = number
  default     = 30
}

variable "enable_request_validation" {
  description = "Habilitar validación de requests"
  type        = bool
  default     = true
}

variable "enable_response_validation" {
  description = "Habilitar validación de responses"
  type        = bool
  default     = true
}

variable "enable_api_key" {
  description = "Habilitar autenticación por API Key"
  type        = bool
  default     = true
}

variable "enable_usage_plans" {
  description = "Habilitar planes de uso"
  type        = bool
  default     = true
}

variable "enable_custom_domain" {
  description = "Habilitar dominio personalizado"
  type        = bool
  default     = false
}

variable "custom_domain_name" {
  description = "Nombre de dominio personalizado"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN del certificado ACM para dominio personalizado"
  type        = string
  default     = ""
}

variable "sagemaker_endpoint_arn" {
  description = "ARN del endpoint de SageMaker"
  type        = string
}

variable "endpoint_name" {
  description = "Nombre del endpoint de SageMaker"
  type        = string
}

variable "malicious_ips" {
  description = "Lista de IPs maliciosas para bloquear"
  type        = list(string)
  default     = []
} 