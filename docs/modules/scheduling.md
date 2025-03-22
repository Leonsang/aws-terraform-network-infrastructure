# Guía Maestra: Módulo de Scheduling

## Descripción General
Este módulo implementa una infraestructura de programación de tareas utilizando AWS EventBridge Scheduler y servicios relacionados, permitiendo la ejecución automatizada de tareas programadas y eventos recurrentes.

## Componentes Principales

### 1. EventBridge Scheduler
- **Configuración**:
  - Schedules
  - Schedule groups
  - Flexible time windows
  - Target invocations

### 2. Targets
- **Configuración**:
  - Lambda functions
  - ECS tasks
  - Step Functions
  - API destinations

### 3. Retry Policies
- **Configuración**:
  - Retry attempts
  - Backoff strategies
  - Dead-letter queues
  - Error handling

### 4. Monitoreo
- **Configuración**:
  - CloudWatch metrics
  - CloudWatch logs
  - Event history
  - Health checks

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

variable "schedule_group_config" {
  description = "Configuración de grupos de programación"
  type = map(object({
    name        = string
    description = optional(string)
    tags        = map(string)
  }))
}

variable "schedule_config" {
  description = "Configuración de programaciones"
  type = map(object({
    name                = string
    description         = optional(string)
    group_name         = string
    schedule_expression = string
    flexible_time_window = object({
      mode                      = string
      maximum_window_in_minutes = optional(number)
    })
    target = object({
      arn      = string
      role_arn = string
      input    = optional(string)
      retry_policy = optional(object({
        maximum_retry_attempts       = number
        maximum_event_age_in_seconds = number
      }))
      dead_letter_config = optional(object({
        arn = string
      }))
      ecs_parameters = optional(object({
        task_definition_arn = string
        task_count         = number
        launch_type        = string
        network_configuration = optional(object({
          subnets          = list(string)
          security_groups  = list(string)
          assign_public_ip = bool
        }))
      }))
      input_transformer = optional(object({
        input_paths    = map(string)
        input_template = string
      }))
    })
    state = optional(string)
    tags  = map(string)
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
output "schedule_group_arns" {
  description = "ARNs de los grupos de programación"
  value       = { for k, v in aws_scheduler_schedule_group.groups : k => v.arn }
}

output "schedule_arns" {
  description = "ARNs de las programaciones"
  value       = { for k, v in aws_scheduler_schedule.schedules : k => v.arn }
}

output "schedule_states" {
  description = "Estados de las programaciones"
  value       = { for k, v in aws_scheduler_schedule.schedules : k => v.state }
}
```

## Uso del Módulo

```hcl
module "scheduling" {
  source = "./modules/scheduling"

  project_name = "mi-proyecto"
  environment  = "prod"

  schedule_group_config = {
    "batch-jobs" = {
      name        = "batch-jobs-group"
      description = "Grupo para trabajos batch"
      tags = {
        Environment = "prod"
        Service    = "batch"
      }
    }
  }

  schedule_config = {
    "daily-backup" = {
      name                = "daily-backup-schedule"
      description         = "Programación diaria de respaldos"
      group_name         = "batch-jobs-group"
      schedule_expression = "cron(0 2 * * ? *)"
      flexible_time_window = {
        mode                      = "FLEXIBLE"
        maximum_window_in_minutes = 30
      }
      target = {
        arn      = "arn:aws:lambda:region:account:function:backup-function"
        role_arn = "arn:aws:iam::account:role/EventBridgeSchedulerRole"
        input    = jsonencode({
          operation = "backup"
          type     = "full"
        })
        retry_policy = {
          maximum_retry_attempts       = 3
          maximum_event_age_in_seconds = 3600
        }
        dead_letter_config = {
          arn = "arn:aws:sqs:region:account:scheduler-dlq"
        }
      }
      state = "ENABLED"
      tags = {
        Environment = "prod"
        Service    = "backup"
      }
    },
    "weekly-maintenance" = {
      name                = "weekly-maintenance-schedule"
      description         = "Programación semanal de mantenimiento"
      group_name         = "batch-jobs-group"
      schedule_expression = "cron(0 0 ? * SUN *)"
      flexible_time_window = {
        mode                      = "FLEXIBLE"
        maximum_window_in_minutes = 60
      }
      target = {
        arn      = "arn:aws:ecs:region:account:task-definition/maintenance:1"
        role_arn = "arn:aws:iam::account:role/EventBridgeSchedulerRole"
        ecs_parameters = {
          task_definition_arn = "arn:aws:ecs:region:account:task-definition/maintenance:1"
          task_count         = 1
          launch_type        = "FARGATE"
          network_configuration = {
            subnets          = ["subnet-12345678"]
            security_groups  = ["sg-12345678"]
            assign_public_ip = false
          }
        }
        retry_policy = {
          maximum_retry_attempts       = 2
          maximum_event_age_in_seconds = 7200
        }
      }
      state = "ENABLED"
      tags = {
        Environment = "prod"
        Service    = "maintenance"
      }
    }
  }

  notification_config = {
    sns_topic_arn = "arn:aws:sns:region:account:scheduler-notifications"
    events        = [
      "SCHEDULE_START",
      "SCHEDULE_COMPLETE",
      "SCHEDULE_FAILED"
    ]
  }

  tags = {
    Environment = "prod"
    Project     = "mi-proyecto"
    Scheduling = "enabled"
  }
}
```

## Mejores Prácticas

### 1. Diseño
- Agrupación de tareas
- Ventanas de tiempo
- Dependencias
- Idempotencia

### 2. Seguridad
- IAM roles
- Permisos mínimos
- Encriptación
- Auditoría

### 3. Rendimiento
- Concurrencia
- Timeouts
- Recursos
- Escalabilidad

### 4. Operaciones
- Monitoreo
- Logging
- Alertas
- Mantenimiento

## Monitoreo y Mantenimiento

### 1. Métricas
- Execution success rate
- Duration
- Throttling
- Error rate

### 2. Logs
- Execution logs
- Error logs
- Audit logs
- Performance logs

### 3. Alertas
- Failed executions
- Long running tasks
- Resource constraints
- Policy violations

## Troubleshooting

### Problemas Comunes
1. **Ejecución**:
   - Task failures
   - Permission issues
   - Resource constraints
   - Timeout errors

2. **Programación**:
   - Timing issues
   - Concurrency limits
   - Dependencies
   - State conflicts

3. **Performance**:
   - Long durations
   - Resource usage
   - Network issues
   - Throttling

## Seguridad

### 1. Acceso
- IAM roles
- Resource policies
- Network access
- API authentication

### 2. Datos
- Input validation
- Output handling
- Sensitive data
- Logging control

### 3. Compliance
- Audit trails
- Policy enforcement
- Regulatory compliance
- Documentation

## Costos y Optimización

### 1. Ejecución
- Schedule optimization
- Resource utilization
- Concurrency management
- Duration control

### 2. Operaciones
- Monitoring costs
- Log retention
- Resource cleanup
- Automation

### 3. Mantenimiento
- Schedule review
- Resource scaling
- Cost allocation
- Performance tuning 