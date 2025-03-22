# Guía Maestra: Módulo de Backup

## Descripción General
Este módulo implementa una infraestructura de respaldo utilizando AWS Backup y servicios relacionados, permitiendo la gestión centralizada de copias de seguridad para múltiples recursos AWS.

## Componentes Principales

### 1. AWS Backup
- **Configuración**:
  - Backup vaults
  - Backup plans
  - Recovery points
  - Cross-region backup

### 2. Backup Selection
- **Configuración**:
  - Resource selection
  - Tag-based selection
  - Service-based selection
  - Cross-account backup

### 3. Backup Rules
- **Configuración**:
  - Schedule rules
  - Lifecycle rules
  - Retention rules
  - Copy rules

### 4. Recovery
- **Configuración**:
  - Recovery points
  - Restore testing
  - Cross-region recovery
  - Point-in-time recovery

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

variable "backup_vault_config" {
  description = "Configuración de los Backup Vaults"
  type = map(object({
    name                = string
    kms_key_arn        = string
    force_destroy      = bool
    tags               = map(string)
  }))
}

variable "backup_plan_config" {
  description = "Configuración de los Backup Plans"
  type = map(object({
    name = string
    rules = list(object({
      rule_name                = string
      target_vault_name       = string
      schedule                = string
      start_window           = number
      completion_window      = number
      recovery_point_tags    = map(string)
      lifecycle = object({
        cold_storage_after = number
        delete_after      = number
      })
      copy_actions = list(object({
        destination_vault_arn = string
        lifecycle = object({
          cold_storage_after = number
          delete_after      = number
        })
      }))
    }))
    advanced_backup_settings = list(object({
      resource_type = string
      backup_options = map(string)
    }))
    tags = map(string)
  }))
}

variable "backup_selection_config" {
  description = "Configuración de las selecciones de backup"
  type = map(object({
    name                = string
    iam_role_arn       = string
    plan_id            = string
    resources          = list(string)
    selection_tags     = list(object({
      type  = string
      key   = string
      value = string
    }))
    conditions = object({
      string_equals = list(object({
        key   = string
        value = string
      }))
      string_like = list(object({
        key   = string
        value = string
      }))
      string_not_equals = list(object({
        key   = string
        value = string
      }))
      string_not_like = list(object({
        key   = string
        value = string
      }))
    })
    not_resources = list(string)
  }))
}

variable "restore_testing_config" {
  description = "Configuración de pruebas de restauración"
  type = map(object({
    name                = string
    backup_vault_name   = string
    recovery_point_arn  = string
    resource_type      = string
    target_account     = string
    target_region      = string
    metadata           = map(string)
    iam_role_arn      = string
  }))
}

variable "notification_config" {
  description = "Configuración de notificaciones"
  type = object({
    sns_topic_arn = string
    events        = list(string)
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
output "backup_vault_arns" {
  description = "ARNs de los Backup Vaults"
  value       = { for k, v in aws_backup_vault.vaults : k => v.arn }
}

output "backup_vault_names" {
  description = "Nombres de los Backup Vaults"
  value       = { for k, v in aws_backup_vault.vaults : k => v.name }
}

output "backup_plan_arns" {
  description = "ARNs de los Backup Plans"
  value       = { for k, v in aws_backup_plan.plans : k => v.arn }
}

output "backup_plan_versions" {
  description = "Versiones de los Backup Plans"
  value       = { for k, v in aws_backup_plan.plans : k => v.version }
}

output "backup_selection_ids" {
  description = "IDs de las selecciones de backup"
  value       = { for k, v in aws_backup_selection.selections : k => v.id }
}

output "restore_test_results" {
  description = "Resultados de las pruebas de restauración"
  value       = { for k, v in aws_backup_restore_testing.tests : k => v.status }
}
```

## Uso del Módulo

```hcl
module "backup" {
  source = "./modules/backup"

  project_name = "mi-proyecto"
  environment  = "prod"

  backup_vault_config = {
    "principal" = {
      name           = "vault-principal"
      kms_key_arn   = "arn:aws:kms:region:account:key/123"
      force_destroy = false
      tags          = {
        Environment = "prod"
        Backup     = "principal"
      }
    }
    "secundario" = {
      name           = "vault-dr"
      kms_key_arn   = "arn:aws:kms:region:account:key/456"
      force_destroy = false
      tags          = {
        Environment = "prod"
        Backup     = "dr"
      }
    }
  }

  backup_plan_config = {
    "plan-principal" = {
      name = "plan-backup-principal"
      rules = [
        {
          rule_name           = "backup-diario"
          target_vault_name  = "vault-principal"
          schedule           = "cron(0 5 ? * * *)"
          start_window      = 60
          completion_window = 120
          recovery_point_tags = {
            Type = "Daily"
          }
          lifecycle = {
            cold_storage_after = 30
            delete_after      = 90
          }
          copy_actions = [
            {
              destination_vault_arn = "arn:aws:backup:region:account:backup-vault/vault-dr"
              lifecycle = {
                cold_storage_after = 30
                delete_after      = 90
              }
            }
          ]
        },
        {
          rule_name           = "backup-semanal"
          target_vault_name  = "vault-principal"
          schedule           = "cron(0 5 ? * SAT *)"
          start_window      = 60
          completion_window = 120
          recovery_point_tags = {
            Type = "Weekly"
          }
          lifecycle = {
            cold_storage_after = 90
            delete_after      = 180
          }
          copy_actions = []
        }
      ]
      advanced_backup_settings = [
        {
          resource_type  = "EC2"
          backup_options = {
            WindowsVSS = "enabled"
          }
        }
      ]
      tags = {
        Environment = "prod"
        Plan       = "principal"
      }
    }
  }

  backup_selection_config = {
    "produccion" = {
      name          = "recursos-produccion"
      iam_role_arn = "arn:aws:iam::account:role/BackupRole"
      plan_id      = "plan-principal"
      resources    = [
        "arn:aws:ec2:region:account:instance/*",
        "arn:aws:rds:region:account:db/*"
      ]
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = "prod"
        }
      ]
      conditions = {
        string_equals = [
          {
            key   = "aws:ResourceTag/Backup"
            value = "true"
          }
        ]
        string_like = []
        string_not_equals = []
        string_not_like = []
      }
      not_resources = [
        "arn:aws:ec2:region:account:instance/excluded-instance"
      ]
    }
  }

  restore_testing_config = {
    "test-mensual" = {
      name               = "prueba-restauracion-mensual"
      backup_vault_name  = "vault-principal"
      recovery_point_arn = "arn:aws:backup:region:account:recovery-point/1234"
      resource_type     = "EC2"
      target_account    = "account"
      target_region     = "region"
      metadata         = {
        "OriginalInstanceId" = "i-1234567890abcdef0"
      }
      iam_role_arn     = "arn:aws:iam::account:role/BackupRestoreRole"
    }
  }

  notification_config = {
    sns_topic_arn = "arn:aws:sns:region:account:backup-notifications"
    events        = [
      "BACKUP_JOB_STARTED",
      "BACKUP_JOB_COMPLETED",
      "BACKUP_JOB_FAILED",
      "RESTORE_JOB_STARTED",
      "RESTORE_JOB_COMPLETED",
      "RESTORE_JOB_FAILED"
    ]
  }

  tags = {
    Environment = "prod"
    Project     = "mi-proyecto"
    Backup     = "enabled"
  }
}
```

## Mejores Prácticas

### 1. Planificación
- Estrategia de retención
- Frecuencia de backups
- Selección de recursos
- Pruebas de restauración

### 2. Seguridad
- Encriptación
- Control de acceso
- Auditoría
- Monitoreo

### 3. Recuperación
- RPO/RTO
- Pruebas periódicas
- Documentación
- Procedimientos

### 4. Optimización
- Costos
- Almacenamiento
- Performance
- Automatización

## Monitoreo y Mantenimiento

### 1. Métricas
- Success rate
- Completion time
- Storage usage
- Recovery time

### 2. Logs
- Backup logs
- Restore logs
- Audit logs
- Error logs

### 3. Alertas
- Backup failures
- Storage limits
- Policy violations
- Restore status

## Troubleshooting

### Problemas Comunes
1. **Backup**:
   - Job failures
   - Permission issues
   - Storage limits
   - Timeout errors

2. **Restore**:
   - Recovery failures
   - Compatibility issues
   - Network problems
   - Resource conflicts

3. **Performance**:
   - Slow backups
   - Resource constraints
   - Network bottlenecks
   - Storage latency

## Seguridad

### 1. Acceso
- IAM roles
- KMS encryption
- Network access
- Cross-account

### 2. Datos
- Encryption at rest
- Encryption in transit
- Secure deletion
- Access logging

### 3. Compliance
- Retention policies
- Audit trails
- Regulatory compliance
- Documentation

## Costos y Optimización

### 1. Storage
- Lifecycle policies
- Storage classes
- Retention periods
- Compression

### 2. Operations
- Backup windows
- Resource selection
- Frequency optimization
- Cross-region costs

### 3. Recovery
- Test environments
- Recovery validation
- Resource cleanup
- Cost monitoring 