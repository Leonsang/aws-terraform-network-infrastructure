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

variable "sagemaker_endpoint_name" {
  description = "Nombre del endpoint de SageMaker"
  type        = string
}

variable "sagemaker_endpoint_arn" {
  description = "ARN del endpoint de SageMaker"
  type        = string
}

variable "api_gateway_url" {
  description = "URL del API Gateway"
  type        = string
}

variable "notification_topic_arn" {
  description = "ARN del tema SNS para notificaciones"
  type        = string
}

variable "test_data_location" {
  description = "Ubicación en S3 de los datos de prueba"
  type        = string
}

variable "test_schedule" {
  description = "Expresión cron para la ejecución programada de pruebas"
  type        = string
  default     = "cron(0 2 ? * MON-FRI *)"  # 2 AM UTC de lunes a viernes
}

variable "threshold_accuracy" {
  description = "Umbral mínimo de precisión del modelo"
  type        = number
  default     = 0.95
}

variable "threshold_precision" {
  description = "Umbral mínimo de precisión (precision) del modelo"
  type        = number
  default     = 0.90
}

variable "threshold_recall" {
  description = "Umbral mínimo de recall del modelo"
  type        = number
  default     = 0.90
}

variable "threshold_f1" {
  description = "Umbral mínimo de F1-score del modelo"
  type        = number
  default     = 0.90
}

variable "threshold_api_errors" {
  description = "Umbral máximo de tasa de errores de la API"
  type        = number
  default     = 0.01 # 1%
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "ID de la VPC donde se ejecutarán las pruebas"
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subnets donde se ejecutarán las pruebas"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN de la llave KMS para encriptación"
  type        = string
}

variable "repository_url" {
  description = "URL del repositorio de GitHub"
  type        = string
}

variable "test_compute_type" {
  description = "Tipo de instancia para ejecutar las pruebas"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "test_notification_emails" {
  description = "Lista de correos electrónicos para notificaciones de pruebas"
  type        = list(string)
}

variable "test_timeout" {
  description = "Tiempo máximo de ejecución para las pruebas en minutos"
  type        = number
  default     = 30
}

variable "enable_vulnerability_scanning" {
  description = "Habilitar escaneo de vulnerabilidades en las pruebas"
  type        = bool
  default     = true
}

variable "enable_static_analysis" {
  description = "Habilitar análisis estático de código"
  type        = bool
  default     = true
}

variable "enable_integration_tests" {
  description = "Habilitar pruebas de integración"
  type        = bool
  default     = true
}

variable "enable_load_tests" {
  description = "Habilitar pruebas de carga"
  type        = bool
  default     = false
}

variable "test_environment_variables" {
  description = "Variables de entorno adicionales para las pruebas"
  type        = map(string)
  default     = {}
}

variable "test_parallelization" {
  description = "Número de pruebas a ejecutar en paralelo"
  type        = number
  default     = 1
}

variable "test_retry_count" {
  description = "Número de reintentos para pruebas fallidas"
  type        = number
  default     = 2
}

variable "test_reports_retention_days" {
  description = "Días de retención para los reportes de pruebas"
  type        = number
  default     = 30
}

variable "test_failure_threshold" {
  description = "Porcentaje máximo de pruebas fallidas permitido"
  type        = number
  default     = 10
}

variable "enable_test_coverage" {
  description = "Habilitar reportes de cobertura de pruebas"
  type        = bool
  default     = true
}

variable "test_coverage_threshold" {
  description = "Porcentaje mínimo de cobertura de pruebas requerido"
  type        = number
  default     = 80
}

variable "enable_security_tests" {
  description = "Habilitar pruebas de seguridad"
  type        = bool
  default     = true
}

variable "enable_performance_tests" {
  description = "Habilitar pruebas de rendimiento"
  type        = bool
  default     = false
}

variable "test_notification_frequency" {
  description = "Frecuencia de notificaciones de pruebas (ALWAYS, ON_FAILURE, NEVER)"
  type        = string
  default     = "ON_FAILURE"
}

variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
} 