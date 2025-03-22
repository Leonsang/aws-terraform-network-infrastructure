variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "La región de AWS donde se desplegarán los recursos"
  type        = string
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

variable "raw_bucket_suffix" {
  description = "Sufijo para el bucket de datos crudos"
  type        = string
  default     = "raw"
}

variable "processed_bucket_suffix" {
  description = "Sufijo para el bucket de datos procesados"
  type        = string
  default     = "processed"
}

variable "analytics_bucket_suffix" {
  description = "Sufijo para el bucket de análisis"
  type        = string
  default     = "analytics"
}

variable "enable_versioning" {
  description = "Habilitar versionamiento en los buckets"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Habilitar encriptación en los buckets"
  type        = bool
  default     = true
}

variable "force_destroy_bucket" {
  description = "Permitir la eliminación del bucket incluso si contiene objetos"
  type        = bool
  default     = false
}

variable "enable_lifecycle_rules" {
  description = "Habilitar reglas de ciclo de vida en el bucket S3"
  type        = bool
  default     = true
}

variable "transition_ia_days" {
  description = "Días antes de transicionar a IA"
  type        = number
  default     = 30
}

variable "transition_glacier_days" {
  description = "Días antes de transicionar a Glacier"
  type        = number
  default     = 90
}

variable "alarm_actions" {
  description = "Lista de ARNs para las acciones de alarma"
  type        = list(string)
  default     = []
}

variable "bucket_size_threshold" {
  description = "Umbral de tamaño del bucket para activar la alarma"
  type        = number
  default     = 107374182400 # 100 GB
}

variable "create_efs" {
  description = "Crear sistema de archivos EFS"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "IDs de las subredes"
  type        = list(string)
  default     = []
}

variable "efs_transition_to_ia" {
  description = "Transición automática a IA para EFS"
  type        = bool
  default     = true
}

variable "efs_performance_mode" {
  description = "Modo de rendimiento para EFS"
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "Modo de rendimiento para EFS"
  type        = string
  default     = "bursting"
}

variable "efs_provisioned_throughput" {
  description = "Rendimiento aprovisionado para EFS"
  type        = number
  default     = 1024
}

variable "backup_schedule" {
  description = "Programación para respaldar EFS"
  type        = string
  default     = "cron(0 12 * * ? *)"
}

variable "backup_retention_days" {
  description = "Días para retener respaldos"
  type        = number
  default     = 30
}

variable "efs_storage_threshold" {
  description = "Umbral de almacenamiento EFS para activar la alarma"
  type        = number
  default     = 107374182400 # 100 GB
}

variable "create_metrics_bucket" {
  description = "Si se debe crear un bucket para métricas de monitoreo"
  type        = bool
  default     = false
}

variable "metrics_bucket_name" {
  description = "Nombre del bucket para métricas de monitoreo"
  type        = string
  default     = ""
}

variable "feature_definitions" {
  description = "Definiciones de características para el Feature Store"
  type = list(object({
    feature_name = string
    feature_type = string
  }))
  default = []
}

variable "processed_transition_ia_days" {
  description = "Días antes de transicionar objetos procesados a IA"
  type        = number
  default     = 30
}

variable "processed_transition_glacier_days" {
  description = "Días antes de transicionar objetos procesados a Glacier"
  type        = number
  default     = 90
}

variable "processed_expiration_days" {
  description = "Días antes de expirar objetos procesados"
  type        = number
  default     = 365
}

variable "expiration_days" {
  description = "Días antes de expirar objetos"
  type        = number
  default     = 365
}

variable "enable_efs_backup" {
  description = "Habilitar backup de EFS"
  type        = bool
  default     = false
} 