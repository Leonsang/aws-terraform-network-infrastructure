# Variables para el módulo de seguridad

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)"
  type        = string
}

# Variables para buckets S3
variable "raw_bucket_arn" {
  description = "ARN del bucket S3 para la zona Raw"
  type        = string
}

variable "proc_bucket_arn" {
  description = "ARN del bucket S3 para la zona Processed"
  type        = string
}

variable "analy_bucket_arn" {
  description = "ARN del bucket S3 para la zona Analytics"
  type        = string
}

# Variables para el backend de Terraform
variable "terraform_state_bucket_arn" {
  description = "ARN del bucket S3 para el estado de Terraform"
  type        = string
}

variable "terraform_state_lock_table_arn" {
  description = "ARN de la tabla DynamoDB para el bloqueo de estado"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegarán los servicios"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de subredes donde se desplegarán los servicios"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "Lista de bloques CIDR permitidos para acceder a los servicios"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_vpc_endpoints" {
  description = "Habilitar endpoints de VPC para los servicios"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags adicionales para los recursos"
  type        = map(string)
  default     = {}
} 