# Variables para el módulo de almacenamiento

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Entorno (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "Región de AWS"
  type        = string
}

# Variables para nombres de buckets
variable "raw_bucket_suffix" {
  description = "Sufijo para el bucket de la zona raw"
  type        = string
  default     = "raw"
}

variable "processed_bucket_suffix" {
  description = "Sufijo para el bucket de la zona processed"
  type        = string
  default     = "processed"
}

variable "analytics_bucket_suffix" {
  description = "Sufijo para el bucket de la zona analytics"
  type        = string
  default     = "analytics"
}

# Variables para ciclo de vida del bucket raw
variable "raw_transition_ia_days" {
  description = "Días antes de transicionar objetos a IA en el bucket raw"
  type        = number
  default     = 30
}

variable "raw_transition_glacier_days" {
  description = "Días antes de transicionar objetos a Glacier en el bucket raw"
  type        = number
  default     = 90
}

variable "raw_expiration_days" {
  description = "Días antes de eliminar objetos en el bucket raw"
  type        = number
  default     = 365
}

# Variables para ciclo de vida del bucket processed
variable "processed_transition_ia_days" {
  description = "Días antes de transicionar objetos a IA en el bucket processed"
  type        = number
  default     = 60
}

variable "processed_transition_glacier_days" {
  description = "Días antes de transicionar objetos a Glacier en el bucket processed"
  type        = number
  default     = 180
}

variable "processed_expiration_days" {
  description = "Días antes de eliminar objetos en el bucket processed"
  type        = number
  default     = 730
}

variable "force_destroy" {
  description = "Permitir la eliminación del bucket incluso si contiene objetos"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

variable "import_existing_buckets" {
  description = "Si es true, importa buckets existentes en lugar de crearlos"
  type        = bool
  default     = false
} 