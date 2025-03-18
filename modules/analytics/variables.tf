# Variables generales
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "Región de AWS donde se crearán los recursos"
  type        = string
}

# Variables para Redshift
variable "create_redshift" {
  description = "Si se debe crear el cluster de Redshift"
  type        = bool
  default     = false
}

variable "redshift_username" {
  description = "Usuario administrador para Redshift"
  type        = string
  sensitive   = true
}

variable "redshift_password" {
  description = "Contraseña para el usuario maestro de Redshift"
  type        = string
  sensitive   = true
}

variable "redshift_node_type" {
  description = "Tipo de nodo para el cluster de Redshift"
  type        = string
  default     = "dc2.large"
}

variable "redshift_node_count" {
  description = "Número de nodos para el cluster de Redshift"
  type        = number
  default     = 1
}

# Variables de red
variable "vpc_id" {
  description = "ID de la VPC donde se desplegará Redshift"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "IDs de las subredes donde se desplegará Redshift"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "IDs de los grupos de seguridad para Redshift"
  type        = list(string)
  default     = []
}

variable "redshift_allowed_cidr_blocks" {
  description = "Bloques CIDR permitidos para conectarse a Redshift"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Cambiar en producción
}

# Variables para buckets
variable "processed_bucket_name" {
  description = "Nombre del bucket S3 para datos procesados"
  type        = string
}

variable "analytics_bucket_name" {
  description = "Nombre del bucket S3 para resultados analíticos"
  type        = string
}

variable "logging_bucket_name" {
  description = "Nombre del bucket S3 para almacenar los logs de Redshift"
  type        = string
  default     = null
}

# Variables para Glue/Athena
variable "glue_role_arn" {
  description = "ARN del rol IAM para el crawler de Glue"
  type        = string
}

# Tags
variable "tags" {
  description = "Tags adicionales para los recursos"
  type        = map(string)
  default     = {}
} 