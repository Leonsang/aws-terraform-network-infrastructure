# Guía Maestra: Módulo de Database

## Descripción General
Este módulo implementa y gestiona bases de datos en AWS, incluyendo RDS, Aurora, y DynamoDB, con configuraciones de alta disponibilidad, backup y seguridad.

## Componentes Principales

### 1. RDS (Relational Database Service)
- **Configuración Principal**:
  - Multi-AZ deployment
  - Read replicas
  - Automated backups
  - Performance insights

### 2. Aurora
- **Características**:
  - Serverless v2
  - Global database
  - Backtrack
  - Auto scaling

### 3. DynamoDB
- **Configuraciones**:
  - On-demand capacity
  - Auto scaling
  - Global tables
  - Point-in-time recovery

### 4. Seguridad
- **Características**:
  - Encryption at rest
  - Encryption in transit
  - IAM authentication
  - Security groups

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

variable "rds_config" {
  description = "Configuración de RDS"
  type = object({
    engine                = string
    engine_version       = string
    instance_class       = string
    allocated_storage    = number
    max_allocated_storage = number
    multi_az             = bool
    backup_retention_period = number
    deletion_protection  = bool
  })
}

variable "aurora_config" {
  description = "Configuración de Aurora"
  type = object({
    engine_mode          = string
    engine_version      = string
    instance_class      = string
    instances           = number
    min_capacity        = number
    max_capacity        = number
    enable_global       = bool
  })
}

variable "dynamodb_config" {
  description = "Configuración de DynamoDB"
  type = object({
    billing_mode        = string
    read_capacity      = number
    write_capacity     = number
    enable_autoscaling = bool
    enable_global      = bool
    enable_backup      = bool
  })
}

variable "security_config" {
  description = "Configuración de seguridad"
  type = object({
    enable_encryption = bool
    enable_iam_auth   = bool
    allowed_cidr_blocks = list(string)
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
output "rds_endpoint" {
  description = "Endpoint de RDS"
  value       = aws_db_instance.main.endpoint
}

output "rds_arn" {
  description = "ARN de RDS"
  value       = aws_db_instance.main.arn
}

output "aurora_cluster_endpoint" {
  description = "Endpoint del cluster Aurora"
  value       = aws_rds_cluster.aurora.endpoint
}

output "aurora_reader_endpoint" {
  description = "Endpoint de lectura de Aurora"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB"
  value       = aws_dynamodb_table.main.name
}

output "dynamodb_table_arn" {
  description = "ARN de la tabla DynamoDB"
  value       = aws_dynamodb_table.main.arn
}

output "security_group_id" {
  description = "ID del grupo de seguridad"
  value       = aws_security_group.database.id
}
```

## Uso del Módulo

```hcl
module "database" {
  source = "./modules/database"

  project_name = "mi-proyecto"
  environment  = "prod"

  rds_config = {
    engine                = "postgres"
    engine_version       = "14.7"
    instance_class       = "db.t3.medium"
    allocated_storage    = 100
    max_allocated_storage = 1000
    multi_az             = true
    backup_retention_period = 7
    deletion_protection  = true
  }

  aurora_config = {
    engine_mode     = "provisioned"
    engine_version = "5.7.mysql_aurora.2.11.2"
    instance_class = "db.r6g.large"
    instances      = 2
    min_capacity   = 2
    max_capacity   = 8
    enable_global  = false
  }

  dynamodb_config = {
    billing_mode        = "PAY_PER_REQUEST"
    read_capacity      = null
    write_capacity     = null
    enable_autoscaling = true
    enable_global      = false
    enable_backup      = true
  }

  security_config = {
    enable_encryption    = true
    enable_iam_auth      = true
    allowed_cidr_blocks = ["10.0.0.0/16"]
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
- Configurar read replicas
- Usar Auto Scaling
- Planificar failover

### 2. Rendimiento
- Monitorear métricas
- Optimizar consultas
- Configurar caching
- Ajustar capacidad

### 3. Backup y Recuperación
- Configurar backups automáticos
- Implementar point-in-time recovery
- Probar restauraciones
- Documentar procedimientos

### 4. Seguridad
- Encriptar datos
- Implementar IAM auth
- Configurar security groups
- Auditar accesos

## Monitoreo y Mantenimiento

### 1. CloudWatch
- Monitorear métricas
- Configurar alarmas
- Analizar logs
- Crear dashboards

### 2. Performance Insights
- Analizar queries
- Identificar cuellos de botella
- Optimizar rendimiento
- Monitorear recursos

### 3. Mantenimiento
- Planificar ventanas
- Aplicar parches
- Actualizar versiones
- Documentar cambios

## Troubleshooting

### Problemas Comunes
1. **Rendimiento**:
   - Queries lentas
   - CPU alta
   - Memoria insuficiente
   - I/O elevado

2. **Conectividad**:
   - Security groups
   - Credenciales
   - Timeouts
   - DNS

3. **Capacidad**:
   - Storage lleno
   - Conexiones máximas
   - Memory pressure
   - IOPS limitados

## Seguridad

### 1. Encriptación
- En reposo
- En tránsito
- Gestión de claves
- Rotación

### 2. Autenticación
- IAM roles
- Database users
- SSL/TLS
- Certificados

### 3. Network
- Security groups
- NACLs
- VPC endpoints
- Private subnets

## Costos y Optimización

### 1. Instancias
- Dimensionar correctamente
- Usar reserved instances
- Implementar auto scaling
- Monitorear uso

### 2. Storage
- Optimizar allocated storage
- Usar gp3 vs io1
- Implementar lifecycle
- Monitorear IOPS

### 3. Backup
- Optimizar retención
- Usar snapshots
- Implementar lifecycle
- Monitorear costos 