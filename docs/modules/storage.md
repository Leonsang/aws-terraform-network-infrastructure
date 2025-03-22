# Guía Maestra: Módulo de Storage

## Descripción General
Este módulo gestiona la infraestructura de almacenamiento, proporcionando soluciones para almacenamiento de objetos (S3) y sistema de archivos elástico (EFS), incluyendo backup, recuperación y monitoreo.

## Componentes Principales

### 1. Amazon S3
#### Configuración del Bucket
- **Versionamiento**:
  - Control de versiones
  - Historial de cambios
  - Recuperación de versiones

- **Encriptación**:
  - AES-256 por defecto
  - KMS opcional
  - Encriptación en tránsito

#### Políticas de Ciclo de Vida
- **Transiciones**:
  - IA Storage Class
  - Glacier
  - Expiración configurable

- **Optimización**:
  - Limpieza automática
  - Costos optimizados
  - Retención flexible

### 2. Amazon EFS
#### Sistema de Archivos
- **Configuración**:
  - Multi-AZ
  - Encriptación en reposo
  - Performance modes

- **Mount Targets**:
  - Distribución AZ
  - Security Groups
  - Subnets dedicadas

#### Optimización
- **Throughput**:
  - Bursting
  - Provisioned
  - Auto-scaling

- **Storage Classes**:
  - Standard
  - IA
  - One Zone IA

### 3. Backup y Recuperación
#### AWS Backup
- **Planes de Backup**:
  - Programación automática
  - Retención configurable
  - Cross-region

- **Vaults**:
  - Encriptación
  - Acceso controlado
  - Auditoría

#### Recuperación
- **Puntos de Recuperación**:
  - Consistentes
  - Incrementales
  - Cross-region

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

variable "s3_config" {
  description = "Configuración de S3"
  type = object({
    versioning = bool
    encryption = bool
    lifecycle_rules = list(object({
      enabled = bool
      transitions = list(object({
        days = number
        storage_class = string
      }))
      expiration_days = number
    }))
  })
}

variable "efs_config" {
  description = "Configuración de EFS"
  type = object({
    create_efs = bool
    performance_mode = string
    throughput_mode = string
    transition_to_ia = number
    enable_backup = bool
  })
}
```

## Outputs Principales

```hcl
output "s3_bucket_id" {
  description = "ID del bucket S3"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.main.arn
}

output "efs_id" {
  description = "ID del sistema de archivos EFS"
  value       = var.efs_config.create_efs ? aws_efs_file_system.main[0].id : null
}

output "efs_arn" {
  description = "ARN del sistema de archivos EFS"
  value       = var.efs_config.create_efs ? aws_efs_file_system.main[0].arn : null
}

output "backup_vault_arn" {
  description = "ARN del vault de backup"
  value       = var.efs_config.create_efs && var.efs_config.enable_backup ? aws_backup_vault.main[0].arn : null
}
```

## Uso del Módulo

```hcl
module "storage" {
  source = "./modules/storage"

  project_name = "mi-proyecto"
  environment  = "prod"

  s3_config = {
    versioning = true
    encryption = true
    lifecycle_rules = [
      {
        enabled = true
        transitions = [
          {
            days = 90
            storage_class = "STANDARD_IA"
          },
          {
            days = 180
            storage_class = "GLACIER"
          }
        ]
        expiration_days = 365
      }
    ]
  }

  efs_config = {
    create_efs = true
    performance_mode = "generalPurpose"
    throughput_mode = "bursting"
    transition_to_ia = 90
    enable_backup = true
  }
}
```

## Mejores Prácticas

### 1. S3
- Implementar versionamiento para datos críticos
- Usar lifecycle rules para optimizar costos
- Configurar encriptación por defecto
- Implementar políticas de acceso granular

### 2. EFS
- Distribuir mount targets en múltiples AZs
- Usar security groups restrictivos
- Implementar backup automático
- Monitorear uso y rendimiento

### 3. Backup
- Mantener copias en múltiples regiones
- Implementar retención apropiada
- Probar recuperación regularmente
- Documentar procedimientos

## Monitoreo y Mantenimiento

### 1. Métricas
- Monitorear uso de almacenamiento
- Seguimiento de operaciones
- Latencia y throughput
- Errores y excepciones

### 2. Alarmas
- Uso de capacidad
- Errores de operación
- Latencia excesiva
- Fallos de backup

### 3. Logs
- Auditoría de acceso
- Operaciones de backup
- Errores y excepciones
- Cambios de configuración

## Troubleshooting

### Problemas Comunes
1. **S3**:
   - Problemas de permisos
   - Errores de lifecycle
   - Latencia excesiva
   - Costos inesperados

2. **EFS**:
   - Problemas de conectividad
   - Rendimiento degradado
   - Errores de mount
   - Backup fallidos

3. **Backup**:
   - Fallos de programación
   - Errores de retención
   - Problemas de espacio
   - Recuperación fallida

## Seguridad

### 1. S3
- Políticas de bucket
- Encriptación en reposo
- Encriptación en tránsito
- Auditoría de acceso

### 2. EFS
- Security groups
- Encriptación
- Control de acceso
- Auditoría de operaciones

### 3. Backup
- Encriptación de datos
- Control de acceso
- Auditoría de operaciones
- Seguridad física

## Costos y Optimización

### 1. S3
- Optimizar lifecycle rules
- Usar storage classes apropiadas
- Minimizar operaciones
- Revisar costos regularmente

### 2. EFS
- Optimizar throughput
- Usar storage classes IA
- Monitorear uso
- Ajustar configuración

### 3. Backup
- Optimizar retención
- Revisar costos de almacenamiento
- Limpiar backups antiguos
- Monitorear uso 