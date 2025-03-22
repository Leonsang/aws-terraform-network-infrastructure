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
  default     = null
}

variable "glue_database_name" {
  description = "Nombre de la base de datos en Glue"
  type        = string
  default     = null
}

variable "sagemaker_endpoint_name" {
  description = "Nombre del endpoint de SageMaker"
  type        = string
  default     = null
}

variable "api_gateway_url" {
  description = "URL del API Gateway"
  type        = string
  default     = null
}

variable "notification_topic_arn" {
  description = "ARN del tema SNS para notificaciones"
  type        = string
  default     = null
}

variable "repository_name" {
  description = "Nombre del repositorio CodeCommit"
  type        = string
  default     = null
}

variable "repository_arn" {
  description = "ARN del repositorio CodeCommit"
  type        = string
  default     = null
}

variable "allowed_ips" {
  description = "Lista de IPs permitidas para acceder a la documentación"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "docs_alert_emails" {
  description = "Lista de correos electrónicos para alertas de documentación"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Días de retención para los logs de Lambda"
  type        = number
  default     = 30
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

variable "repository_url" {
  description = "URL del repositorio de GitHub"
  type        = string
}

variable "docs_compute_type" {
  description = "Tipo de instancia para generación de documentación"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "docs_update_schedule" {
  description = "Expresión cron para actualización automática de documentación"
  type        = string
  default     = "cron(0 1 ? * MON-FRI *)"  # 1 AM UTC de lunes a viernes
}

variable "docs_notification_emails" {
  description = "Lista de correos electrónicos para notificaciones de documentación"
  type        = list(string)
}

variable "docs_retention_days" {
  description = "Días de retención para documentación antigua"
  type        = number
  default     = 30
}

variable "enable_api_documentation" {
  description = "Habilitar generación de documentación de API"
  type        = bool
  default     = true
}

variable "enable_infrastructure_documentation" {
  description = "Habilitar generación de documentación de infraestructura"
  type        = bool
  default     = true
}

variable "enable_code_documentation" {
  description = "Habilitar generación de documentación de código"
  type        = bool
  default     = true
}

variable "docs_format" {
  description = "Formato de salida para la documentación (HTML, PDF, MARKDOWN)"
  type        = string
  default     = "HTML"
}

variable "docs_template" {
  description = "Plantilla a usar para la documentación"
  type        = string
  default     = "default"
}

variable "docs_language" {
  description = "Idioma principal de la documentación"
  type        = string
  default     = "es"
}

variable "enable_versioning" {
  description = "Habilitar versionado de documentación"
  type        = bool
  default     = true
}

variable "enable_search" {
  description = "Habilitar búsqueda en la documentación"
  type        = bool
  default     = true
}

variable "enable_feedback" {
  description = "Habilitar sistema de feedback en la documentación"
  type        = bool
  default     = true
}

variable "docs_build_timeout" {
  description = "Tiempo máximo de construcción en minutos"
  type        = number
  default     = 30
}

variable "docs_concurrent_builds" {
  description = "Número máximo de construcciones concurrentes"
  type        = number
  default     = 1
}

variable "enable_diagrams" {
  description = "Habilitar generación de diagramas"
  type        = bool
  default     = true
}

variable "diagram_type" {
  description = "Tipo de diagramas a generar (mermaid, plantuml)"
  type        = string
  default     = "mermaid"
}

variable "enable_pdf_export" {
  description = "Habilitar exportación a PDF"
  type        = bool
  default     = true
}

variable "enable_code_examples" {
  description = "Habilitar ejemplos de código en la documentación"
  type        = bool
  default     = true
}

variable "code_example_languages" {
  description = "Lenguajes a incluir en los ejemplos de código"
  type        = list(string)
  default     = ["python", "javascript", "bash"]
}

variable "enable_changelog" {
  description = "Habilitar generación automática de changelog"
  type        = bool
  default     = true
}

variable "changelog_sections" {
  description = "Secciones a incluir en el changelog"
  type        = list(string)
  default     = ["Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"]
} 