# Guía Maestra: Módulo de Networking

## Descripción General
Este módulo implementa la infraestructura de red base en AWS, incluyendo VPC, subredes, gateways y configuraciones de enrutamiento.

## Componentes Principales

### 1. VPC (Virtual Private Cloud)
- **Configuración Principal**:
  - CIDR blocks personalizables
  - DNS hostnames habilitados
  - Tenancy configurables
  - Tags para organización

### 2. Subredes
- **Públicas**:
  - Auto-asignación de IPs públicas
  - Rutas a Internet Gateway
  - Zonas de disponibilidad múltiples

- **Privadas**:
  - NAT Gateway para salida a internet
  - Aislamiento de recursos internos
  - Zonas de disponibilidad múltiples

### 3. Gateways
- **Internet Gateway**:
  - Conectividad a Internet
  - IPv4 e IPv6 habilitados
  - Altamente disponible

- **NAT Gateway**:
  - IPs elásticas asignadas
  - Por zona de disponibilidad
  - Failover configurado

### 4. Tablas de Ruteo
- **Rutas Públicas**:
  - Rutas a Internet Gateway
  - Rutas entre subredes
  - Rutas personalizadas

- **Rutas Privadas**:
  - Rutas a NAT Gateway
  - Rutas entre subredes
  - Rutas personalizadas

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

variable "vpc_config" {
  description = "Configuración de la VPC"
  type = object({
    cidr_block           = string
    enable_dns_hostnames = bool
    enable_dns_support   = bool
    instance_tenancy     = string
  })
}

variable "public_subnets" {
  description = "Configuración de subredes públicas"
  type = list(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_subnets" {
  description = "Configuración de subredes privadas"
  type = list(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "nat_gateway_config" {
  description = "Configuración de NAT Gateways"
  type = object({
    enable_per_az = bool
    eip_allocation = string
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
output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block de la VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs de las subredes públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs de los NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "public_route_table_id" {
  description = "ID de la tabla de ruteo pública"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs de las tablas de ruteo privadas"
  value       = aws_route_table.private[*].id
}
```

## Uso del Módulo

```hcl
module "networking" {
  source = "./modules/networking"

  project_name = "mi-proyecto"
  environment  = "prod"

  vpc_config = {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"
  }

  public_subnets = [
    {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
    },
    {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
    }
  ]

  private_subnets = [
    {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "us-east-1a"
    },
    {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "us-east-1b"
    }
  ]

  nat_gateway_config = {
    enable_per_az  = true
    eip_allocation = "standard"
  }

  tags = {
    Environment = "prod"
    Project     = "mi-proyecto"
  }
}
```

## Mejores Prácticas

### 1. Diseño de VPC
- Usar rangos CIDR no solapados
- Planificar para crecimiento futuro
- Implementar múltiples AZs
- Documentar asignaciones de IPs

### 2. Subredes
- Balancear entre AZs
- Reservar espacio para expansión
- Etiquetar apropiadamente
- Mantener consistencia en naming

### 3. NAT Gateways
- Uno por AZ para alta disponibilidad
- Monitorear costos
- Configurar failover
- Optimizar rutas

### 4. Seguridad
- Implementar NACLs
- Configurar Security Groups
- Auditar accesos
- Monitorear tráfico

## Monitoreo y Mantenimiento

### 1. VPC Flow Logs
- Habilitar logging
- Analizar patrones
- Detectar anomalías
- Retener históricos

### 2. Métricas
- Monitorear NAT Gateway
- Revisar utilización
- Analizar latencia
- Verificar conectividad

### 3. Alertas
- Configurar umbrales
- Notificar problemas
- Escalar incidentes
- Documentar respuestas

## Troubleshooting

### Problemas Comunes
1. **Conectividad**:
   - Tablas de ruteo incorrectas
   - NACLs bloqueantes
   - Security Groups restrictivos
   - NAT Gateway fallido

2. **Rendimiento**:
   - Saturación de NAT Gateway
   - Latencia entre AZs
   - Límites de VPC alcanzados
   - Problemas de DNS

3. **Seguridad**:
   - Accesos no autorizados
   - Exposición no intencional
   - Configuraciones inseguras
   - Logs incompletos

## Seguridad

### 1. Control de Acceso
- Implementar least privilege
- Auditar cambios
- Documentar accesos
- Revisar periódicamente

### 2. Encriptación
- Habilitar VPC endpoints
- Usar TLS/SSL
- Implementar VPN
- Configurar Direct Connect

### 3. Monitoreo
- Revisar Flow Logs
- Analizar tráfico
- Detectar amenazas
- Responder incidentes

## Costos y Optimización

### 1. NAT Gateway
- Optimizar uso
- Consolidar tráfico
- Monitorear transferencia
- Evaluar alternativas

### 2. VPC Endpoints
- Reducir tráfico NAT
- Optimizar latencia
- Evaluar costos
- Implementar según necesidad

### 3. Transferencia de Datos
- Monitorear uso
- Optimizar rutas
- Reducir costos
- Planificar capacidad 