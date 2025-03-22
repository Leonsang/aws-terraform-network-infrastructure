# Guía Maestra: Módulo de Monitoreo y Observabilidad

## Descripción General
Este módulo proporciona una solución completa de monitoreo y observabilidad, integrando CloudWatch, X-Ray y métricas personalizadas para obtener una visión completa de la infraestructura y aplicaciones.

## Componentes Principales

### 1. CloudWatch Logs
#### Grupos de Logs
- **Configuración Centralizada**:
  - Retención configurable
  - Encriptación automática
  - Tags y categorización

- **Exportación**:
  - S3 para almacenamiento
  - Kinesis para streaming
  - Firehose para procesamiento

#### Métricas de Logs
- **Filtros**:
  - Patrones personalizados
  - Alertas basadas en contenido
  - Agregación de datos

### 2. X-Ray
#### Trazabilidad
- **Sampling Rules**:
  - Reglas personalizadas
  - Priorización de servicios
  - Control de costos

- **Mapas de Servicio**:
  - Visualización de dependencias
  - Análisis de latencia
  - Detección de cuellos de botella

#### Análisis
- **Insights**:
  - Detección de anomalías
  - Análisis de errores
  - Optimización de rendimiento

### 3. Métricas y Alarmas
#### Métricas Personalizadas
- **Definición**:
  - Métricas de negocio
  - KPIs técnicos
  - Agregaciones personalizadas

- **Visualización**:
  - Dashboards dinámicos
  - Widgets personalizados
  - Análisis temporal

#### Alarmas
- **Configuración**:
  - Umbrales dinámicos
  - Períodos de evaluación
  - Acciones automáticas

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

variable "log_config" {
  description = "Configuración de logs"
  type = object({
    retention_days = number
    export_to_s3 = bool
    enable_streaming = bool
  })
}

variable "xray_config" {
  description = "Configuración de X-Ray"
  type = object({
    sampling_rate = number
    sampling_rules = list(object({
      name = string
      priority = number
      reservoir_size = number
      fixed_rate = number
      host = string
      http_method = string
      url_path = string
    }))
  })
}

variable "alarm_config" {
  description = "Configuración de alarmas"
  type = object({
    lambda_error_threshold = number
    api_latency_threshold = number
    alarm_actions = list(string)
  })
}
```

## Outputs Principales

```hcl
output "log_group_name" {
  description = "Nombre del grupo de logs"
  value       = aws_cloudwatch_log_group.main.name
}

output "log_group_arn" {
  description = "ARN del grupo de logs"
  value       = aws_cloudwatch_log_group.main.arn
}

output "xray_sampling_rule_name" {
  description = "Nombre de la regla de sampling"
  value       = aws_xray_sampling_rule.main.name
}

output "xray_sampling_rule_arn" {
  description = "ARN de la regla de sampling"
  value       = aws_xray_sampling_rule.main.arn
}

output "metric_stream_name" {
  description = "Nombre del stream de métricas"
  value       = aws_cloudwatch_metric_stream.main.name
}

output "metric_stream_arn" {
  description = "ARN del stream de métricas"
  value       = aws_cloudwatch_metric_stream.main.arn
}

output "dashboard_name" {
  description = "Nombre del dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
```

## Uso del Módulo

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  project_name = "mi-proyecto"
  environment  = "prod"

  log_config = {
    retention_days = 30
    export_to_s3 = true
    enable_streaming = true
  }

  xray_config = {
    sampling_rate = 0.1
    sampling_rules = [
      {
        name = "api-sampling"
        priority = 1
        reservoir_size = 1
        fixed_rate = 0.1
        host = "api.ejemplo.com"
        http_method = "*"
        url_path = "*"
      }
    ]
  }

  alarm_config = {
    lambda_error_threshold = 5
    api_latency_threshold = 1000
    alarm_actions = ["arn:aws:sns:region:account:topic"]
  }
}
```

## Mejores Prácticas

### 1. Logs
- Implementar estructura de logs consistente
- Usar niveles de log apropiados
- Configurar retención adecuada
- Implementar filtros efectivos

### 2. X-Ray
- Ajustar sampling rate según necesidades
- Definir reglas de sampling específicas
- Monitorear costos de tracing
- Analizar mapas de servicio regularmente

### 3. Métricas
- Definir métricas de negocio claras
- Implementar alarmas significativas
- Mantener dashboards actualizados
- Revisar tendencias regularmente

## Monitoreo y Mantenimiento

### 1. Logs
- Monitorear uso de almacenamiento
- Revisar patrones de error
- Analizar tendencias
- Limpiar logs antiguos

### 2. X-Ray
- Monitorear costos de tracing
- Analizar patrones de latencia
- Revisar errores y excepciones
- Optimizar reglas de sampling

### 3. Métricas
- Revisar precisión de métricas
- Ajustar umbrales de alarmas
- Actualizar dashboards
- Analizar tendencias

## Troubleshooting

### Problemas Comunes
1. **Logs**:
   - Problemas de retención
   - Errores de exportación
   - Costos excesivos
   - Filtros ineficientes

2. **X-Ray**:
   - Costos elevados
   - Sampling inadecuado
   - Errores de tracing
   - Latencia excesiva

3. **Métricas**:
   - Alarmas falsas
   - Métricas incorrectas
   - Dashboards desactualizados
   - Umbrales inadecuados

## Seguridad

### 1. Logs
- Encriptación en reposo
- Control de acceso
- Auditoría de operaciones
- Retención segura

### 2. X-Ray
- Control de acceso
- Encriptación de datos
- Auditoría de uso
- Seguridad de endpoints

### 3. Métricas
- Protección de datos
- Control de acceso
- Auditoría de cambios
- Seguridad de dashboards

## Costos y Optimización

### 1. Logs
- Optimizar retención
- Implementar filtros eficientes
- Usar almacenamiento apropiado
- Revisar costos regularmente

### 2. X-Ray
- Ajustar sampling rate
- Optimizar reglas
- Monitorear costos
- Limpiar datos antiguos

### 3. Métricas
- Optimizar almacenamiento
- Revisar costos de alarmas
- Limpiar métricas no utilizadas
- Ajustar granularidad 