# Guía Maestra: Módulo de Scaling

## Descripción General
Este módulo implementa escalado automático utilizando AWS Auto Scaling Groups (ASG) y políticas de escalado dinámico, con integración a múltiples servicios y métricas personalizadas.

## Componentes Principales

### 1. Auto Scaling Groups
- **Configuración**:
  - Launch templates
  - Instance distribution
  - Capacity settings
  - Update policies

### 2. Scaling Policies
- **Tipos**:
  - Target tracking
  - Step scaling
  - Simple scaling
  - Predictive scaling

### 3. Launch Templates
- **Configuración**:
  - Instance types
  - AMI selection
  - User data
  - Instance profile

### 4. Mixed Instances Policy
- **Estrategias**:
  - Spot instances
  - Instance distribution
  - Capacity optimization
  - Override settings

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

variable "asg_config" {
  description = "Configuración del Auto Scaling Group"
  type = object({
    min_size                  = number
    max_size                  = number
    desired_capacity         = number
    health_check_type        = string
    health_check_grace_period = number
    force_delete             = bool
    termination_policies     = list(string)
    suspended_processes      = list(string)
    placement_group          = string
    enabled_metrics         = list(string)
    service_linked_role_arn = string
  })
}

variable "launch_template_config" {
  description = "Configuración del Launch Template"
  type = object({
    instance_type           = string
    image_id               = string
    key_name              = string
    user_data             = string
    security_groups       = list(string)
    iam_instance_profile = string
    ebs_optimized        = bool
    monitoring           = bool
    metadata_options    = map(string)
  })
}

variable "mixed_instances_config" {
  description = "Configuración de instancias mixtas"
  type = object({
    override = list(object({
      instance_type     = string
      weighted_capacity = number
    }))
    spot_allocation_strategy = string
    spot_instance_pools     = number
    spot_max_price         = string
    on_demand_percentage   = number
    on_demand_base_capacity = number
  })
}

variable "scaling_policies" {
  description = "Configuración de políticas de escalado"
  type = object({
    target_tracking = list(object({
      name                   = string
      target_value          = number
      predefined_metric     = string
      scale_in_cooldown    = number
      scale_out_cooldown   = number
      disable_scale_in     = bool
    }))
    step_scaling = list(object({
      name                = string
      adjustment_type     = string
      metric_aggregation = string
      steps              = list(object({
        lower_bound = number
        upper_bound = number
        adjustment  = number
      }))
    }))
  })
}

variable "lifecycle_hooks" {
  description = "Configuración de lifecycle hooks"
  type = list(object({
    name                    = string
    lifecycle_transition   = string
    default_result        = string
    heartbeat_timeout     = number
    notification_target_arn = string
    role_arn              = string
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
output "asg_id" {
  description = "ID del Auto Scaling Group"
  value       = aws_autoscaling_group.main.id
}

output "asg_arn" {
  description = "ARN del Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "asg_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "launch_template_id" {
  description = "ID del Launch Template"
  value       = aws_launch_template.main.id
}

output "launch_template_latest_version" {
  description = "Última versión del Launch Template"
  value       = aws_launch_template.main.latest_version
}

output "scaling_policy_arns" {
  description = "ARNs de las políticas de escalado"
  value       = aws_autoscaling_policy.target_tracking[*].arn
}
```

## Uso del Módulo

```hcl
module "scaling" {
  source = "./modules/scaling"

  project_name = "mi-proyecto"
  environment  = "prod"

  asg_config = {
    min_size                  = 2
    max_size                  = 10
    desired_capacity         = 2
    health_check_type        = "ELB"
    health_check_grace_period = 300
    force_delete             = false
    termination_policies     = ["OldestInstance", "Default"]
    suspended_processes      = []
    placement_group          = null
    enabled_metrics         = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity"]
    service_linked_role_arn = null
  }

  launch_template_config = {
    instance_type           = "t3.micro"
    image_id               = "ami-12345678"
    key_name              = "mi-key"
    user_data             = base64encode("#!/bin/bash\necho 'Hello, World!'")
    security_groups       = ["sg-12345678"]
    iam_instance_profile = "MiInstanceProfile"
    ebs_optimized        = true
    monitoring           = true
    metadata_options    = {
      http_endpoint = "enabled"
      http_tokens   = "required"
    }
  }

  mixed_instances_config = {
    override = [
      {
        instance_type     = "t3.small"
        weighted_capacity = 2
      },
      {
        instance_type     = "t3.medium"
        weighted_capacity = 4
      }
    ]
    spot_allocation_strategy = "capacity-optimized"
    spot_instance_pools     = 2
    spot_max_price         = ""
    on_demand_percentage   = 20
    on_demand_base_capacity = 1
  }

  scaling_policies = {
    target_tracking = [
      {
        name                = "cpu-policy"
        target_value       = 70.0
        predefined_metric  = "ASGAverageCPUUtilization"
        scale_in_cooldown  = 300
        scale_out_cooldown = 300
        disable_scale_in   = false
      }
    ]
    step_scaling = [
      {
        name                = "memory-policy"
        adjustment_type     = "ChangeInCapacity"
        metric_aggregation = "Average"
        steps = [
          {
            lower_bound = 0
            upper_bound = 60
            adjustment  = -1
          },
          {
            lower_bound = 60
            upper_bound = null
            adjustment  = 1
          }
        ]
      }
    ]
  }

  lifecycle_hooks = [
    {
      name                    = "startup-hook"
      lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 300
      notification_target_arn = "arn:aws:sns:region:account:topic"
      role_arn              = "arn:aws:iam::account:role/AutoScalingNotification"
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "mi-proyecto"
  }
}
```

## Mejores Prácticas

### 1. Capacidad
- Dimensionar correctamente
- Usar múltiples tipos
- Implementar Spot
- Balancear costos

### 2. Políticas
- Combinar estrategias
- Configurar cooldowns
- Usar step scaling
- Monitorear efectividad

### 3. Resiliencia
- Multi-AZ deployment
- Health checks
- Lifecycle hooks
- Instance refresh

### 4. Performance
- Instance types
- Launch templates
- Monitoring
- Optimización

## Monitoreo y Mantenimiento

### 1. Métricas
- CPU utilization
- Memory usage
- Network I/O
- Custom metrics

### 2. Logs
- Instance logs
- Activity history
- Scaling events
- Health status

### 3. Alertas
- Capacity changes
- Failed launches
- Health check failures
- Cost thresholds

## Troubleshooting

### Problemas Comunes
1. **Capacidad**:
   - Launch failures
   - Scaling delays
   - Capacity constraints
   - Instance health

2. **Performance**:
   - Resource utilization
   - Network issues
   - Storage bottlenecks
   - Application errors

3. **Costos**:
   - Spot interruptions
   - Over-provisioning
   - Under-utilization
   - Reserved capacity

## Seguridad

### 1. Instance
- Security groups
- IAM roles
- User data
- Metadata options

### 2. Network
- VPC configuration
- Subnet placement
- NACL rules
- Security groups

### 3. Compliance
- Instance tagging
- Resource monitoring
- Audit logging
- Policy enforcement

## Costos y Optimización

### 1. Instance Strategy
- Spot instances
- Reserved instances
- Instance types
- Capacity optimization

### 2. Scaling
- Right-sizing
- Schedule scaling
- Predictive scaling
- Target tracking

### 3. Monitoring
- Cost allocation
- Usage patterns
- Performance metrics
- Optimization recommendations 