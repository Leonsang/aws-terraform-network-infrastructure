# Guía Maestra: Módulo de Seguridad y Cumplimiento

## Descripción General
Este módulo implementa una infraestructura de seguridad completa, incluyendo AWS Organizations, IAM, AWS Config y Security Hub para garantizar el cumplimiento y la seguridad de la plataforma.

## Componentes Principales

### 1. AWS Organizations
#### Estructura Organizacional
- **Cuentas**:
  - Cuenta maestra
  - Cuentas de servicio
  - Cuentas de desarrollo
  - Cuentas de producción

- **Organización**:
  - Unidades organizativas
  - Jerarquía de cuentas
  - Facturación consolidada

#### Service Control Policies (SCPs)
- **Políticas**:
  - Restricciones de servicio
  - Permisos por ambiente
  - Control de costos

- **Implementación**:
  - Políticas por OU
  - Herencia de permisos
  - Auditoría de cambios

### 2. IAM y Seguridad
#### Roles y Políticas
- **Roles**:
  - Roles de servicio
  - Roles de aplicación
  - Roles de administración

- **Políticas**:
  - Políticas basadas en recursos
  - Políticas de acceso condicional
  - Políticas de auditoría

#### Seguridad de Credenciales
- **Gestión**:
  - Rotación automática
  - Acceso temporal
  - MFA obligatorio

- **Monitoreo**:
  - Auditoría de acceso
  - Alertas de seguridad
  - Reportes de uso

### 3. AWS Config
#### Configuración
- **Reglas**:
  - Reglas de conformidad
  - Reglas de seguridad
  - Reglas de costos

- **Evaluación**:
  - Evaluación continua
  - Remediación automática
  - Reportes de estado

#### Recursos
- **Monitoreo**:
  - Cambios de configuración
  - Desviaciones de conformidad
  - Historial de cambios

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

variable "organization_config" {
  description = "Configuración de la organización"
  type = object({
    create_organization = bool
    additional_scp_statements = list(object({
      effect = string
      action = list(string)
      resource = list(string)
      condition = object({
        test = string
        variable = string
        values = list(string)
      })
    }))
  })
}

variable "security_config" {
  description = "Configuración de seguridad"
  type = object({
    minimum_password_length = number
    max_password_age = number
    password_reuse_prevention = number
    require_mfa = bool
    enable_security_hub = bool
  })
}

variable "config_rules" {
  description = "Reglas de AWS Config"
  type = list(object({
    name = string
    description = string
    source = object({
      owner = string
      source_identifier = string
    })
    input_parameters = string
    maximum_execution_frequency = string
  }))
}
```

## Outputs Principales

```hcl
output "organization_id" {
  description = "ID de la organización"
  value       = var.organization_config.create_organization ? aws_organizations_organization.main[0].id : null
}

output "organization_arn" {
  description = "ARN de la organización"
  value       = var.organization_config.create_organization ? aws_organizations_organization.main[0].arn : null
}

output "scp_id" {
  description = "ID de la política de control de servicio"
  value       = var.organization_config.create_organization ? aws_organizations_policy.main[0].id : null
}

output "scp_arn" {
  description = "ARN de la política de control de servicio"
  value       = var.organization_config.create_organization ? aws_organizations_policy.main[0].arn : null
}

output "config_recorder_id" {
  description = "ID del grabador de configuración"
  value       = aws_config_configuration_recorder.main.id
}

output "security_hub_id" {
  description = "ID de Security Hub"
  value       = var.security_config.enable_security_hub ? aws_securityhub_account.main[0].id : null
}
```

## Uso del Módulo

```hcl
module "security" {
  source = "./modules/security"

  project_name = "mi-proyecto"
  environment  = "prod"

  organization_config = {
    create_organization = true
    additional_scp_statements = [
      {
        effect = "Deny"
        action = ["*"]
        resource = ["*"]
        condition = {
          test = "StringNotEquals"
          variable = "aws:PrincipalType"
          values = ["IAMUser"]
        }
      }
    ]
  }

  security_config = {
    minimum_password_length = 14
    max_password_age = 90
    password_reuse_prevention = 24
    require_mfa = true
    enable_security_hub = true
  }

  config_rules = [
    {
      name = "s3-bucket-public-read-prohibited"
      description = "Prohíbe acceso público de lectura a buckets S3"
      source = {
        owner = "AWS"
        source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
      }
      input_parameters = "{}"
      maximum_execution_frequency = "One_Hour"
    }
  ]
}
```

## Mejores Prácticas

### 1. Organizations
- Implementar estructura jerárquica clara
- Usar SCPs para control de costos
- Mantener separación de ambientes
- Documentar políticas

### 2. IAM
- Seguir principio de mínimo privilegio
- Implementar MFA obligatorio
- Rotar credenciales regularmente
- Auditar accesos

### 3. Config
- Definir reglas de conformidad
- Implementar remediación automática
- Monitorear desviaciones
- Mantener documentación

## Monitoreo y Mantenimiento

### 1. Organizations
- Revisar estructura regularmente
- Actualizar SCPs según necesidades
- Monitorear costos por cuenta
- Auditar cambios

### 2. IAM
- Revisar roles y políticas
- Monitorear uso de credenciales
- Analizar reportes de auditoría
- Actualizar políticas

### 3. Config
- Monitorear conformidad
- Revisar reglas activas
- Analizar desviaciones
- Actualizar remediaciones

## Troubleshooting

### Problemas Comunes
1. **Organizations**:
   - Problemas de permisos
   - Conflictos de SCPs
   - Costos inesperados
   - Estructura incorrecta

2. **IAM**:
   - Accesos denegados
   - Credenciales expiradas
   - Políticas conflictivas
   - Auditoría incompleta

3. **Config**:
   - Reglas no evaluadas
   - Remediación fallida
   - Desviaciones no detectadas
   - Costos excesivos

## Seguridad

### 1. Organizations
- Proteger cuenta maestra
- Implementar SCPs restrictivas
- Monitorear cambios
- Auditar estructura

### 2. IAM
- Proteger credenciales
- Implementar MFA
- Rotar accesos
- Auditar cambios

### 3. Config
- Proteger configuración
- Implementar reglas
- Monitorear cambios
- Auditar conformidad

## Costos y Optimización

### 1. Organizations
- Optimizar estructura
- Revisar costos por cuenta
- Ajustar SCPs
- Monitorear uso

### 2. IAM
- Optimizar políticas
- Revisar roles
- Limpiar credenciales
- Monitorear costos

### 3. Config
- Optimizar reglas
- Revisar evaluaciones
- Limpiar recursos
- Monitorear costos 