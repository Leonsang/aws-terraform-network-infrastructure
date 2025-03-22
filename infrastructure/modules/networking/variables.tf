variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
}

variable "public_subnets" {
  description = "Lista de CIDR blocks para las subnets públicas"
  type        = list(string)
}

variable "private_subnets" {
  description = "Lista de CIDR blocks para las subnets privadas"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway para las subnets privadas"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Habilitar VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Días de retención para VPC Flow Logs"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
} 