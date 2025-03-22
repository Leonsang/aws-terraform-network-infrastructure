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

variable "domain_name" {
  description = "Nombre de dominio principal"
  type        = string
}

variable "create_zone" {
  description = "Si se debe crear una nueva zona DNS"
  type        = bool
  default     = true
}

variable "hosted_zone_id" {
  description = "ID de la zona DNS existente si no se crea una nueva"
  type        = string
  default     = ""
}

variable "create_alb_record" {
  description = "Si se debe crear el registro A para el ALB"
  type        = bool
  default     = true
}

variable "alb_dns_name" {
  description = "DNS name del ALB"
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "Zone ID del ALB"
  type        = string
  default     = ""
}

variable "create_www_record" {
  description = "Si se debe crear el registro CNAME para www"
  type        = bool
  default     = true
}

variable "create_mx_records" {
  description = "Si se deben crear registros MX"
  type        = bool
  default     = false
}

variable "mx_records" {
  description = "Lista de registros MX"
  type        = list(string)
  default     = []
}

variable "create_spf_record" {
  description = "Si se debe crear el registro SPF"
  type        = bool
  default     = false
}

variable "spf_records" {
  description = "Lista de registros SPF"
  type        = list(string)
  default     = ["include:_spf.google.com"]
}

variable "create_dmarc_record" {
  description = "Si se debe crear el registro DMARC"
  type        = bool
  default     = false
}

variable "dmarc_policy" {
  description = "Política DMARC (none, quarantine, reject)"
  type        = string
  default     = "none"
}

variable "dmarc_report_email" {
  description = "Email para reportes DMARC"
  type        = string
  default     = ""
}

variable "create_health_check" {
  description = "Si se debe crear un health check para el dominio"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Path para el health check"
  type        = string
  default     = "/"
}

variable "alarm_actions" {
  description = "Lista de ARNs de acciones para las alarmas"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
} 