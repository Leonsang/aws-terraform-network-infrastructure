# Guía Maestra: Módulo de Notificaciones

## Descripción General
Este módulo implementa un sistema centralizado de notificaciones utilizando SNS, SQS y EventBridge para gestionar alertas, mensajes y eventos de la infraestructura.

## Componentes Principales

### 1. Sistema de Mensajería
#### SNS (Simple Notification Service)
- **Topic Principal**:
  - Distribución de mensajes
  - Suscripciones múltiples
  - Políticas de acceso

- **Suscripciones**:
  - Email
  - SMS
  - SQS
  - Webhooks

#### SQS (Simple Queue Service)
- **Cola Principal**:
  - Procesamiento asíncrono
  - Retardo configurable
  - Retención de mensajes

- **Dead Letter Queue (DLQ)**:
  - Manejo de errores
  - Reintentos fallidos
  - Monitoreo de fallos

### 2. EventBridge
#### Reglas de Eventos
- **Patrones**:
  - Eventos de AWS
  - Eventos personalizados
  - Eventos de salud

- **Targets**:
  - SNS Topics
  - SQS Queues
  - Lambda Functions

#### Transformación
- **Input Transformer**:
  - Formato de mensajes
  - Filtrado de datos
  - Enriquecimiento

### 3. Webhooks e Integraciones
#### Lambda Handler
- **Procesamiento**:
  - Validación de mensajes
  - Transformación de datos
  - Manejo de errores

- **Integración**:
  - Múltiples endpoints
  - Reintentos configurables
  - Monitoreo de estado

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

variable "email_subscriptions" {
  description = "Lista de suscripciones por email"
  type        = list(string)
  default     = []
}

variable "sms_subscriptions" {
  description = "Lista de suscripciones por SMS"
  type        = list(string)
  default     = []
}

variable "sqs_config" {
  description = "Configuración de SQS"
  type = object({
    delay_seconds = number
    max_message_size = number
    message_retention_seconds = number
    visibility_timeout_seconds = number
    max_receive_count = number
  })
}

variable "webhook_config" {
  description = "Configuración de webhooks"
  type = object({
    enable_webhooks = bool
    webhook_urls = list(string)
  })
}

variable "alarm_config" {
  description = "Configuración de alarmas"
  type = object({
    dlq_messages_threshold = number
    failed_notifications_threshold = number
    alarm_actions = list(string)
  })
}
```

## Outputs Principales

```hcl
output "sns_topic_arn" {
  description = "ARN del topic SNS"
  value       = aws_sns_topic.main.arn
}

output "sns_topic_name" {
  description = "Nombre del topic SNS"
  value       = aws_sns_topic.main.name
}

output "sqs_queue_url" {
  description = "URL de la cola SQS"
  value       = aws_sqs_queue.main.url
}

output "sqs_queue_arn" {
  description = "ARN de la cola SQS"
  value       = aws_sqs_queue.main.arn
}

output "dlq_url" {
  description = "URL de la cola de mensajes muertos"
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN de la cola de mensajes muertos"
  value       = aws_sqs_queue.dlq.arn
}

output "webhook_function_arn" {
  description = "ARN de la función Lambda para webhooks"
  value       = var.webhook_config.enable_webhooks ? aws_lambda_function.webhook_handler[0].arn : null
}

output "service_health_rule_arn" {
  description = "ARN de la regla EventBridge para salud del servicio"
  value       = aws_cloudwatch_event_rule.service_health.arn
}
```

## Uso del Módulo

```hcl
module "notifications" {
  source = "./modules/notifications"

  project_name = "mi-proyecto"
  environment  = "prod"

  email_subscriptions = ["admin@ejemplo.com"]
  sms_subscriptions = ["+1234567890"]

  sqs_config = {
    delay_seconds = 0
    max_message_size = 262144
    message_retention_seconds = 345600
    visibility_timeout_seconds = 30
    max_receive_count = 3
  }

  webhook_config = {
    enable_webhooks = true
    webhook_urls = ["https://api.ejemplo.com/webhook"]
  }

  alarm_config = {
    dlq_messages_threshold = 1
    failed_notifications_threshold = 5
    alarm_actions = ["arn:aws:sns:region:account:topic"]
  }
}
```

## Mejores Prácticas

### 1. SNS
- Usar topics específicos por propósito
- Implementar políticas de acceso
- Monitorear suscripciones
- Validar endpoints

### 2. SQS
- Configurar DLQ apropiadamente
- Ajustar timeouts según necesidad
- Monitorear colas
- Limpiar mensajes antiguos

### 3. EventBridge
- Definir patrones claros
- Implementar transformaciones
- Monitorear reglas
- Documentar eventos

## Monitoreo y Mantenimiento

### 1. SNS
- Monitorear entregas
- Revisar fallos
- Analizar latencia
- Verificar suscripciones

### 2. SQS
- Monitorear colas
- Revisar DLQ
- Analizar latencia
- Verificar mensajes

### 3. EventBridge
- Monitorear reglas
- Revisar targets
- Analizar eventos
- Verificar transformaciones

## Troubleshooting

### Problemas Comunes
1. **SNS**:
   - Entregas fallidas
   - Suscripciones inválidas
   - Políticas incorrectas
   - Latencia excesiva

2. **SQS**:
   - Mensajes en DLQ
   - Timeouts excesivos
   - Colas bloqueadas
   - Costos inesperados

3. **EventBridge**:
   - Reglas no disparadas
   - Targets fallidos
   - Transformaciones incorrectas
   - Eventos perdidos

## Seguridad

### 1. SNS
- Proteger topics
- Validar endpoints
- Implementar políticas
- Auditar accesos

### 2. SQS
- Proteger colas
- Encriptar mensajes
- Implementar políticas
- Auditar operaciones

### 3. EventBridge
- Proteger reglas
- Validar eventos
- Implementar filtros
- Auditar cambios

## Costos y Optimización

### 1. SNS
- Optimizar suscripciones
- Revisar entregas
- Limpiar endpoints
- Monitorear costos

### 2. SQS
- Optimizar colas
- Revisar mensajes
- Limpiar DLQ
- Monitorear costos

### 3. EventBridge
- Optimizar reglas
- Revisar eventos
- Limpiar targets
- Monitorear costos 