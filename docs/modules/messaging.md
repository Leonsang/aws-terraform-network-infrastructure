# Guía Maestra: Módulo de Messaging

## Descripción General
Este módulo implementa una infraestructura de mensajería utilizando servicios AWS como SQS, SNS y EventBridge, permitiendo la comunicación asíncrona y el manejo de eventos entre diferentes componentes de la aplicación.

## Componentes Principales

### 1. Amazon SQS (Simple Queue Service)
- **Configuración**:
  - Standard queues
  - FIFO queues
  - Dead letter queues
  - Queue policies

### 2. Amazon SNS (Simple Notification Service)
- **Configuración**:
  - Topics
  - Subscriptions
  - Message filtering
  - Message attributes

### 3. Amazon EventBridge
- **Configuración**:
  - Event buses
  - Rules
  - Targets
  - Event patterns

### 4. Integración de Servicios
- **Configuración**:
  - Cross-service communication
  - Event routing
  - Message transformation
  - Error handling

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

variable "sqs_queue_config" {
  description = "Configuración de colas SQS"
  type = map(object({
    name                        = string
    fifo_queue                 = bool
    content_based_deduplication = optional(bool)
    delay_seconds              = optional(number)
    max_message_size          = optional(number)
    message_retention_seconds  = optional(number)
    receive_wait_time_seconds = optional(number)
    visibility_timeout_seconds = optional(number)
    redrive_policy = optional(object({
      deadLetterTargetArn = string
      maxReceiveCount     = number
    }))
    tags = map(string)
  }))
}

variable "sns_topic_config" {
  description = "Configuración de topics SNS"
  type = map(object({
    name                        = string
    fifo_topic                 = bool
    content_based_deduplication = optional(bool)
    delivery_policy = optional(object({
      http = object({
        defaultHealthyRetryPolicy = object({
          minDelayTarget     = number
          maxDelayTarget     = number
          numRetries         = number
          numMaxDelayRetries = number
          backoffFunction    = string
        })
        disableSubscriptionOverrides = bool
      })
    }))
    subscriptions = list(object({
      protocol = string
      endpoint = string
      filter_policy = optional(map(list(string)))
      raw_message_delivery = optional(bool)
    }))
    tags = map(string)
  }))
}

variable "eventbridge_config" {
  description = "Configuración de EventBridge"
  type = map(object({
    name        = string
    description = string
    event_pattern = object({
      source      = list(string)
      detail_type = list(string)
      detail      = map(any)
    })
    targets = list(object({
      target_id = string
      arn       = string
      input_path = optional(string)
      input_transformer = optional(object({
        input_paths    = map(string)
        input_template = string
      }))
      retry_policy = optional(object({
        maximum_event_age_in_seconds = number
        maximum_retry_attempts       = number
      }))
      dead_letter_config = optional(object({
        arn = string
      }))
    }))
    tags = map(string)
  }))
}

variable "dlq_config" {
  description = "Configuración de Dead Letter Queues"
  type = map(object({
    name                        = string
    message_retention_seconds  = optional(number)
    visibility_timeout_seconds = optional(number)
    tags                       = map(string)
  }))
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}
```

## Outputs Principales

```hcl
output "sqs_queue_arns" {
  description = "ARNs de las colas SQS"
  value       = { for k, v in aws_sqs_queue.queues : k => v.arn }
}

output "sqs_queue_urls" {
  description = "URLs de las colas SQS"
  value       = { for k, v in aws_sqs_queue.queues : k => v.url }
}

output "sns_topic_arns" {
  description = "ARNs de los topics SNS"
  value       = { for k, v in aws_sns_topic.topics : k => v.arn }
}

output "eventbridge_bus_arns" {
  description = "ARNs de los buses de eventos"
  value       = { for k, v in aws_cloudwatch_event_bus.buses : k => v.arn }
}

output "dlq_arns" {
  description = "ARNs de las Dead Letter Queues"
  value       = { for k, v in aws_sqs_queue.dlqs : k => v.arn }
}
```

## Uso del Módulo

```hcl
module "messaging" {
  source = "./modules/messaging"

  project_name = "mi-proyecto"
  environment  = "prod"

  sqs_queue_config = {
    "orders" = {
      name                      = "orders-queue"
      fifo_queue               = true
      content_based_deduplication = true
      delay_seconds            = 0
      max_message_size        = 262144
      message_retention_seconds = 345600
      receive_wait_time_seconds = 20
      visibility_timeout_seconds = 30
      redrive_policy = {
        deadLetterTargetArn = "arn:aws:sqs:region:account:orders-dlq.fifo"
        maxReceiveCount     = 3
      }
      tags = {
        Environment = "prod"
        Service    = "orders"
      }
    }
  }

  sns_topic_config = {
    "notifications" = {
      name                      = "notifications-topic"
      fifo_topic               = false
      delivery_policy = {
        http = {
          defaultHealthyRetryPolicy = {
            minDelayTarget     = 20
            maxDelayTarget     = 20
            numRetries         = 3
            numMaxDelayRetries = 0
            backoffFunction    = "linear"
          }
          disableSubscriptionOverrides = false
        }
      }
      subscriptions = [
        {
          protocol = "email"
          endpoint = "admin@example.com"
          filter_policy = {
            severity = ["ERROR", "CRITICAL"]
          }
        },
        {
          protocol = "sqs"
          endpoint = "arn:aws:sqs:region:account:notifications-queue"
          raw_message_delivery = true
        }
      ]
      tags = {
        Environment = "prod"
        Service    = "notifications"
      }
    }
  }

  eventbridge_config = {
    "order-events" = {
      name        = "order-events-bus"
      description = "Bus de eventos para órdenes"
      event_pattern = {
        source      = ["com.myapp.orders"]
        detail_type = ["order_created", "order_updated", "order_cancelled"]
        detail      = {
          status = ["PENDING", "PROCESSING", "COMPLETED", "CANCELLED"]
        }
      }
      targets = [
        {
          target_id = "process-order"
          arn       = "arn:aws:lambda:region:account:function:process-order"
          input_transformer = {
            input_paths = {
              orderId = "$.detail.orderId"
              status  = "$.detail.status"
            }
            input_template = "{ \"order\": { \"id\": <orderId>, \"status\": <status> }}"
          }
          retry_policy = {
            maximum_event_age_in_seconds = 86400
            maximum_retry_attempts       = 3
          }
          dead_letter_config = {
            arn = "arn:aws:sqs:region:account:events-dlq"
          }
        }
      ]
      tags = {
        Environment = "prod"
        Service    = "orders"
      }
    }
  }

  dlq_config = {
    "orders-dlq" = {
      name                      = "orders-dlq.fifo"
      message_retention_seconds = 1209600
      visibility_timeout_seconds = 30
      tags = {
        Environment = "prod"
        Service    = "orders"
      }
    }
  }

  tags = {
    Environment = "prod"
    Project     = "mi-proyecto"
    Messaging  = "enabled"
  }
}
```

## Mejores Prácticas

### 1. Diseño
- Patrones de mensajería
- Manejo de errores
- Escalabilidad
- Redundancia

### 2. Seguridad
- Encriptación
- Autenticación
- Autorización
- Auditoría

### 3. Rendimiento
- Throughput
- Latencia
- Concurrencia
- Batch processing

### 4. Operaciones
- Monitoreo
- Logging
- Alertas
- Mantenimiento

## Monitoreo y Mantenimiento

### 1. Métricas
- Queue depth
- Message age
- Delivery rate
- Error rate

### 2. Logs
- Message logs
- Error logs
- Audit logs
- Performance logs

### 3. Alertas
- Queue thresholds
- DLQ messages
- Delivery failures
- Latency issues

## Troubleshooting

### Problemas Comunes
1. **Mensajería**:
   - Message loss
   - Duplicate messages
   - Message delays
   - Queue overflow

2. **Integración**:
   - Connection issues
   - Transformation errors
   - Routing problems
   - Timeout errors

3. **Performance**:
   - High latency
   - Throttling
   - Backpressure
   - Resource constraints

## Seguridad

### 1. Acceso
- IAM roles
- Queue policies
- Topic policies
- API authentication

### 2. Datos
- Encryption at rest
- Encryption in transit
- Message security
- Access logging

### 3. Compliance
- Message retention
- Audit trails
- Data privacy
- Regulatory compliance

## Costos y Optimización

### 1. Mensajería
- Message pricing
- API calls
- Data transfer
- Storage costs

### 2. Operaciones
- Queue optimization
- Batch processing
- Auto-scaling
- Resource cleanup

### 3. Monitoreo
- CloudWatch costs
- Log retention
- Metric granularity
- Alert configuration 