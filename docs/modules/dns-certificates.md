# Guía Maestra: Módulo de DNS y Certificados

## Descripción General
Este módulo gestiona la infraestructura de DNS y certificados SSL/TLS para la plataforma, proporcionando una solución completa para la gestión de dominios, certificados y registros de email.

## Componentes Principales

### 1. Gestión de Dominios (Route 53)
#### Configuración de Zonas DNS
- **Zonas Públicas**:
  - Creación automática de zonas en Route 53
  - Soporte para múltiples dominios
  - Gestión de subdominios
  - Delegación de DNS

#### Registros DNS
- **Registros A**:
  - Punto a ALB
  - Configuración de alias
  - Health checks integrados

- **Registros CNAME**:
  - Redirección www
  - Alias para servicios
  - Validación automática

### 2. Certificados SSL/TLS (ACM)
#### Gestión de Certificados
- **Certificados Wildcard**:
  - Soporte para *.dominio.com
  - Renovación automática
  - Validación DNS automática

- **Certificados Específicos**:
  - Por subdominio
  - Por servicio
  - Validación manual opcional

#### Configuraciones de Seguridad
- **Políticas de Cifrado**:
  - TLS 1.2+
  - Cipher suites modernos
  - Perfect Forward Secrecy

### 3. Registros de Email
#### Configuración MX
- **Servidores de Correo**:
  - Registros MX prioritarios
  - Fallback servers
  - TTL configurables

#### Autenticación de Email
- **SPF**:
  - Políticas de envío
  - Servidores autorizados
  - Registros TXT

- **DMARC**:
  - Políticas de rechazo
  - Reportes de análisis
  - Configuración gradual

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

variable "domain_name" {
  description = "Dominio principal"
  type        = string
}

variable "enable_wildcard_cert" {
  description = "Habilitar certificado wildcard"
  type        = bool
  default     = true
}

variable "email_config" {
  description = "Configuración de email"
  type = object({
    mx_records = list(string)
    spf_policy = string
    dmarc_policy = string
  })
}
```

## Outputs Principales

```hcl
output "dns_zone_id" {
  description = "ID de la zona DNS"
  value       = aws_route53_zone.main.zone_id
}

output "certificate_arn" {
  description = "ARN del certificado SSL"
  value       = aws_acm_certificate.main.arn
}

output "health_check_arn" {
  description = "ARN del health check"
  value       = aws_route53_health_check.main.arn
}
```

## Uso del Módulo

```hcl
module "dns_certificates" {
  source = "./modules/dns-certificates"

  project_name = "mi-proyecto"
  environment  = "prod"
  domain_name  = "ejemplo.com"

  enable_wildcard_cert = true

  email_config = {
    mx_records = ["10 mail.ejemplo.com"]
    spf_policy = "v=spf1 include:_spf.ejemplo.com -all"
    dmarc_policy = "v=DMARC1; p=reject; rua=mailto:dmarc@ejemplo.com"
  }
}
```

## Mejores Prácticas

### 1. Gestión de Dominios
- Usar nombres descriptivos para las zonas
- Implementar health checks para servicios críticos
- Mantener TTLs apropiados para cada tipo de registro

### 2. Certificados
- Renovar certificados antes de su expiración
- Usar certificados wildcard cuando sea posible
- Implementar validación DNS automática

### 3. Email
- Configurar SPF y DMARC gradualmente
- Monitorear reportes DMARC regularmente
- Mantener registros MX actualizados

## Monitoreo y Mantenimiento

### 1. Health Checks
- Monitorear estado de health checks
- Configurar alarmas para fallos
- Revisar logs de validación

### 2. Certificados
- Monitorear fechas de expiración
- Revisar estado de validación
- Verificar renovaciones automáticas

### 3. Email
- Analizar reportes DMARC
- Monitorear entregas de correo
- Verificar registros DNS

## Troubleshooting

### Problemas Comunes
1. **Certificados no validados**:
   - Verificar registros DNS
   - Comprobar permisos ACM
   - Revisar logs de validación

2. **Health Checks fallidos**:
   - Verificar endpoints
   - Comprobar firewalls
   - Revisar logs de Route 53

3. **Problemas de Email**:
   - Validar registros MX
   - Verificar políticas SPF
   - Revisar reportes DMARC

## Seguridad

### 1. Protección de Dominios
- Registrar dominios con bloqueo
- Implementar DNSSEC
- Monitorear cambios DNS

### 2. Certificados
- Usar certificados de confianza
- Implementar HSTS
- Rotar certificados regularmente

### 3. Email
- Configurar políticas DMARC estrictas
- Implementar SPF y DKIM
- Monitorear actividad sospechosa

## Costos y Optimización

### 1. Route 53
- Optimizar número de health checks
- Usar alias records cuando sea posible
- Revisar costos de consultas

### 2. ACM
- Renovar certificados a tiempo
- Usar certificados wildcard
- Minimizar certificados específicos

### 3. Email
- Optimizar políticas DMARC
- Revisar costos de reportes
- Mantener registros limpios 