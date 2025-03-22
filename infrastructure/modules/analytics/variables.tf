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

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subredes privadas"
  type        = list(string)
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

variable "processed_bucket_name" {
  description = "Nombre del bucket de datos procesados"
  type        = string
}

variable "analytics_bucket_name" {
  description = "Nombre del bucket de analytics"
  type        = string
}

variable "redshift_username" {
  description = "Usuario para el cluster de Redshift"
  type        = string
}

variable "redshift_password" {
  description = "Contraseña para el cluster de Redshift"
  type        = string
  sensitive   = true
}

variable "redshift_node_type" {
  description = "Tipo de nodo para el cluster de Redshift"
  type        = string
}

variable "redshift_node_count" {
  description = "Número de nodos para el cluster de Redshift"
  type        = number
}

variable "glue_role_arn" {
  description = "ARN del rol de IAM para Glue"
  type        = string
}

variable "redshift_role_arn" {
  description = "ARN del rol de IAM para Redshift"
  type        = string
}

variable "glue_job_names" {
  description = "Nombres de los trabajos de Glue"
  type        = list(string)
}

variable "glue_database_name" {
  description = "Nombre de la base de datos de Glue"
  type        = string
}

variable "redshift_master_username" {
  description = "Nombre de usuario maestro para el cluster de Redshift"
  type        = string
  default     = "admin"
}

variable "redshift_master_password" {
  description = "Contraseña maestra para el cluster de Redshift"
  type        = string
  sensitive   = true
}

variable "security_group_ids" {
  description = "IDs de los grupos de seguridad para el cluster de Redshift"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs de las subredes privadas para el cluster de Redshift"
  type        = list(string)
} 