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

variable "vpc_id" {
  description = "ID del VPC donde se desplegará ElastiCache"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets para ElastiCache"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Lista de IDs de Security Groups para ElastiCache"
  type        = list(string)
}

variable "node_type" {
  description = "Tipo de nodo para Redis"
  type        = string
  default     = "cache.t3.medium"
}

variable "number_cache_clusters" {
  description = "Número de nodos en el cluster de Redis"
  type        = number
  default     = 2
}

variable "engine_version" {
  description = "Versión del motor de Redis"
  type        = string
  default     = "6.x"
}

variable "automatic_failover_enabled" {
  description = "Habilitar failover automático"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Habilitar despliegue Multi-AZ"
  type        = bool
  default     = true
}

variable "maintenance_window" {
  description = "Ventana de mantenimiento (UTC)"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "snapshot_window" {
  description = "Ventana para snapshots (UTC)"
  type        = string
  default     = "04:00-05:00"
}

variable "snapshot_retention_days" {
  description = "Días de retención de snapshots"
  type        = number
  default     = 7
}

variable "apply_immediately" {
  description = "Aplicar cambios inmediatamente"
  type        = bool
  default     = false
}

variable "notification_topic_arn" {
  description = "ARN del topic SNS para notificaciones"
  type        = string
  default     = ""
}

variable "cpu_threshold" {
  description = "Umbral de CPU para alarmas (%)"
  type        = number
  default     = 75
}

variable "memory_threshold" {
  description = "Umbral de memoria libre para alarmas (bytes)"
  type        = number
  default     = 104857600 # 100MB
}

variable "connections_threshold" {
  description = "Umbral de conexiones para alarmas"
  type        = number
  default     = 1000
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