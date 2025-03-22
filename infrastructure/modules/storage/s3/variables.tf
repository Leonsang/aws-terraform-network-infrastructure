variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
}

variable "force_destroy" {
  description = "Permitir el borrado de buckets no vacíos"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Reglas de ciclo de vida personalizadas para los buckets"
  type = map(object({
    enabled = bool
    transitions = list(object({
      days          = number
      storage_class = string
    }))
    expiration = optional(object({
      days = number
    }))
  }))
  default = {
    raw = {
      enabled = true
      transitions = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]
    }
    processed = {
      enabled = true
      transitions = [
        {
          days          = 60
          storage_class = "STANDARD_IA"
        }
      ]
    }
    analytics = {
      enabled = true
      transitions = []
    }
  }
}

variable "enable_versioning" {
  description = "Habilitar versionamiento en los buckets"
  type        = bool
  default     = true
}

variable "transition_glacier_days" {
  description = "Días antes de transicionar a Glacier"
  type        = number
  default     = 180
}

variable "transition_ia_days" {
  description = "Días antes de transicionar a IA"
  type        = number
  default     = 90
}

variable "expiration_days" {
  description = "Días antes de expirar los objetos"
  type        = number
  default     = 365
} 