# Guía Maestra: Módulo de Cache

## Descripción General
Este módulo implementa una capa de caché utilizando Amazon ElastiCache con soporte para Redis y Memcached, incluyendo configuraciones de alta disponibilidad, replicación y seguridad.

## Componentes Principales

### 1. ElastiCache Redis
- **Cluster**:
  - Multi-AZ
  - Read replicas
  - Auto failover
  - Backup/restore

### 2. ElastiCache Memcached
- **Cluster**:
  - Auto discovery
  - Node management
  - Memory management
  - Cache invalidation

### 3. Parameter Groups
- **Configuraciones**:
  - Memory settings
  - Connection settings
  - Eviction policies
  - Security settings

### 4. Subnet Groups
- **Network**:
  - Multi-AZ placement
  - VPC configuration
  - Security groups
  - Network ACLs

## Variables Principales

```hcl
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "redis_config" {
  description = "Configuración de Redis"
  type = object({
    engine_version        = string
    node_type            = string
    num_cache_nodes      = number
    parameter_group_family = string
    port                 = number
    multi_az            = bool
    automatic_failover  = bool
    snapshot_retention  = number
    maintenance_window  = string
  })
}

variable "memcached_config" {
  description = "Configuración de Memcached"
  type = object({
    engine_version       = string
    node_type           = string
    num_cache_nodes     = number
    parameter_group_family = string
    port                = number
    az_mode             = string
  })
}

variable "network_config" {
  description = "Configuración de red"
  type = object({
    vpc_id             = string
    subnet_ids         = list(string)
    allowed_cidr_blocks = list(string)
  })
}

variable "parameter_group_config" {
  description = "Configuración de parameter groups"
  type = object({
    redis_params     = map(string)
    memcached_params = map(string)
  })
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}
```

## Outputs Principales

```hcl
output "redis_cluster_id" {
  description = "ID del cluster Redis"
  value       = aws_elasticache_cluster.redis.cluster_id
}

output "redis_endpoint" {
  description = "Endpoint del cluster Redis"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "Puerto del cluster Redis"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}

output "memcached_cluster_id" {
  description = "ID del cluster Memcached"
  value       = aws_elasticache_cluster.memcached.cluster_id
}

output "memcached_endpoint" {
  description = "Endpoint del cluster Memcached"
  value       = aws_elasticache_cluster.memcached.configuration_endpoint
}

output "security_group_id" {
  description = "ID del grupo de seguridad"
  value       = aws_security_group.cache.id
}

output "subnet_group_name" {
  description = "Nombre del grupo de subredes"
  value       = aws_elasticache_subnet_group.main.name
}
```

## Uso del Módulo

```hcl
module "cache" {
  source = "./modules/cache"

  project_name = "mi-proyecto"
  environment  = "prod"

  redis_config = {
    engine_version        = "6.x"
    node_type            = "cache.t3.medium"
    num_cache_nodes      = 2
    parameter_group_family = "redis6.x"
    port                 = 6379
    multi_az            = true
    automatic_failover  = true
    snapshot_retention  = 7
    maintenance_window  = "sun:05:00-sun:09:00"
  }

  memcached_config = {
    engine_version       = "1.6.6"
    node_type           = "cache.t3.medium"
    num_cache_nodes     = 2
    parameter_group_family = "memcached1.6"
    port                = 11211
    az_mode             = "cross-az"
  }

  network_config = {
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-a1b2c3d4", "subnet-e5f6g7h8"]
    allowed_cidr_blocks = ["10.0.0.0/16"]
  }

  parameter_group_config = {
    redis_params = {
      "maxmemory-policy" = "volatile-lru"
      "timeout"          = "300"
    }
    memcached_params = {
      "max_item_size" = "10485760"
    }
  }

  tags = {
    Environment = "prod"
    Project     = "mi-proyecto"
  }
}
```

## Mejores Prácticas

### 1. Alta Disponibilidad
- Implementar Multi-AZ
- Configurar auto failover
- Distribuir nodos
- Planificar backups

### 2. Performance
- Dimensionar correctamente
- Monitorear métricas
- Optimizar memoria
- Configurar eviction

### 3. Seguridad
- Implementar encryption
- Configurar auth
- Restringir acceso
- Auditar cambios

### 4. Mantenimiento
- Planificar ventanas
- Actualizar versiones
- Monitorear logs
- Gestionar backups

## Monitoreo y Mantenimiento

### 1. Métricas
- CPU utilization
- Memory usage
- Cache hits/misses
- Network throughput

### 2. Logs
- Connection logs
- Error logs
- Slow logs
- Auth logs

### 3. Alertas
- Memory pressure
- Connection issues
- Eviction rates
- Failover events

## Troubleshooting

### Problemas Comunes
1. **Performance**:
   - Memory pressure
   - Network latency
   - Connection limits
   - Eviction rates

2. **Conectividad**:
   - Security groups
   - Network ACLs
   - DNS resolution
   - Auth failures

3. **Escalabilidad**:
   - Memory limits
   - Connection limits
   - Network bandwidth
   - CPU constraints

## Seguridad

### 1. Network
- Security groups
- NACLs
- VPC endpoints
- Subnet isolation

### 2. Authentication
- Password policies
- IAM auth
- SSL/TLS
- Network encryption

### 3. Monitoring
- CloudWatch logs
- CloudTrail
- VPC flow logs
- Auth logging

## Costos y Optimización

### 1. Instancias
- Dimensionar correctamente
- Reserved instances
- Monitorear uso
- Ajustar capacidad

### 2. Network
- Optimizar tráfico
- Reducir latencia
- Monitorear transferencia
- Evaluar costos

### 3. Mantenimiento
- Limpiar datos
- Optimizar TTL
- Gestionar backups
- Monitorear costos 