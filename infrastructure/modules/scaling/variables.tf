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

variable "ami_id" {
  description = "ID de la AMI a utilizar para las instancias"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
}

variable "root_volume_size" {
  description = "Tamaño del volumen raíz en GB"
  type        = number
  default     = 30
}

variable "security_group_ids" {
  description = "Lista de IDs de Security Groups"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets donde desplegar las instancias"
  type        = list(string)
}

variable "target_group_arns" {
  description = "Lista de ARNs de Target Groups para el ASG"
  type        = list(string)
  default     = []
}

variable "desired_capacity" {
  description = "Capacidad deseada del ASG"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Tamaño mínimo del ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Tamaño máximo del ASG"
  type        = number
  default     = 4
}

variable "cpu_target_value" {
  description = "Valor objetivo de CPU para el escalado automático"
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Valor objetivo de memoria para el escalado automático"
  type        = number
  default     = 70
}

variable "cpu_high_threshold" {
  description = "Umbral de CPU alto para las alarmas"
  type        = number
  default     = 80
}

variable "memory_high_threshold" {
  description = "Umbral de memoria alta para las alarmas"
  type        = number
  default     = 80
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