# Guía Maestra: Módulo de Containers

## Descripción General
Este módulo implementa una infraestructura de contenedores utilizando Amazon ECS/EKS, con soporte para orquestación, escalado automático, balanceo de carga y monitoreo integrado.

## Componentes Principales

### 1. Amazon ECS/EKS
- **Configuración**:
  - Cluster management
  - Task definitions
  - Service discovery
  - Capacity providers

### 2. Container Registry
- **Configuración**:
  - ECR repositories
  - Image scanning
  - Lifecycle policies
  - Cross-account access

### 3. Networking
- **Configuración**:
  - VPC configuration
  - Load balancing
  - Service mesh
  - Security groups

### 4. Scaling
- **Configuración**:
  - Auto scaling
  - Capacity providers
  - Spot instances
  - Reserved capacity

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

variable "cluster_config" {
  description = "Configuración del cluster de contenedores"
  type = object({
    engine_type = string  # "ECS" o "EKS"
    version     = string
    vpc_config  = object({
      vpc_id          = string
      subnet_ids      = list(string)
      security_groups = list(string)
    })
    logging_config = object({
      log_driver     = string
      log_options    = map(string)
    })
    monitoring_config = object({
      metrics_enabled     = bool
      logs_enabled       = bool
      traces_enabled     = bool
    })
  })
}

variable "task_definitions" {
  description = "Definiciones de tareas de contenedores"
  type = map(object({
    family                = string
    cpu                  = number
    memory               = number
    network_mode         = string
    execution_role_arn   = string
    task_role_arn        = string
    container_definitions = list(object({
      name               = string
      image              = string
      cpu                = number
      memory             = number
      essential          = bool
      port_mappings      = list(object({
        container_port   = number
        host_port        = number
        protocol         = string
      }))
      environment        = list(object({
        name  = string
        value = string
      }))
      secrets           = list(object({
        name      = string
        valueFrom = string
      }))
      mount_points      = list(object({
        sourceVolume  = string
        containerPath = string
        readOnly     = bool
      }))
      log_configuration = object({
        logDriver = string
        options   = map(string)
      })
    }))
  }))
}

variable "service_config" {
  description = "Configuración de servicios de contenedores"
  type = map(object({
    name                = string
    task_definition    = string
    desired_count      = number
    launch_type        = string
    platform_version   = string
    scheduling_strategy = string
    deployment_config  = object({
      maximum_percent         = number
      minimum_healthy_percent = number
      deployment_circuit_breaker = object({
        enable   = bool
        rollback = bool
      })
    })
    network_config     = object({
      assign_public_ip = bool
      security_groups  = list(string)
      subnets         = list(string)
    })
    load_balancer     = object({
      target_group_arn = string
      container_name   = string
      container_port   = number
    })
    service_discovery = object({
      namespace_id = string
      dns_config   = object({
        dns_records = list(object({
          type = string
          ttl  = number
        }))
      })
    })
    auto_scaling     = object({
      min_capacity = number
      max_capacity = number
      policies     = list(object({
        name               = string
        policy_type       = string
        target_value      = number
        scale_in_cooldown = number
        scale_out_cooldown = number
        metric_type       = string
      }))
    })
  }))
}

variable "registry_config" {
  description = "Configuración del registro de contenedores"
  type = map(object({
    name                 = string
    scan_on_push        = bool
    image_tag_mutability = string
    encryption_configuration = object({
      encryption_type = string
      kms_key        = string
    })
    lifecycle_policy    = object({
      rules = list(object({
        rulePriority = number
        description  = string
        selection    = object({
          tagStatus   = string
          countType   = string
          countNumber = number
        })
        action      = object({
          type = string
        })
      }))
    })
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
output "cluster_id" {
  description = "ID del cluster de contenedores"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN del cluster de contenedores"
  value       = aws_ecs_cluster.main.arn
}

output "task_definition_arns" {
  description = "ARNs de las definiciones de tareas"
  value       = { for k, v in aws_ecs_task_definition.tasks : k => v.arn }
}

output "service_arns" {
  description = "ARNs de los servicios"
  value       = { for k, v in aws_ecs_service.services : k => v.arn }
}

output "registry_urls" {
  description = "URLs de los registros de contenedores"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.repository_url }
}

output "load_balancer_dns" {
  description = "DNS del balanceador de carga"
  value       = aws_lb.main.dns_name
}
```

## Uso del Módulo

```hcl
module "containers" {
  source = "./modules/containers"

  project_name = "mi-proyecto"
  environment  = "prod"

  cluster_config = {
    engine_type = "ECS"
    version     = "1.21"
    vpc_config  = {
      vpc_id          = "vpc-123"
      subnet_ids      = ["subnet-123", "subnet-456"]
      security_groups = ["sg-789"]
    }
    logging_config = {
      log_driver  = "awslogs"
      log_options = {
        awslogs-group         = "/ecs/mi-proyecto"
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "ecs"
      }
    }
    monitoring_config = {
      metrics_enabled = true
      logs_enabled    = true
      traces_enabled  = true
    }
  }

  task_definitions = {
    "api" = {
      family              = "api"
      cpu                = 256
      memory             = 512
      network_mode       = "awsvpc"
      execution_role_arn = "arn:aws:iam::account:role/ecsTaskExecutionRole"
      task_role_arn      = "arn:aws:iam::account:role/ecsTaskRole"
      container_definitions = [
        {
          name     = "api"
          image    = "account.dkr.ecr.region.amazonaws.com/api:latest"
          cpu      = 256
          memory   = 512
          essential = true
          port_mappings = [
            {
              container_port = 8080
              host_port     = 8080
              protocol      = "tcp"
            }
          ]
          environment = [
            {
              name  = "ENV"
              value = "prod"
            }
          ]
          secrets = [
            {
              name      = "DB_PASSWORD"
              valueFrom = "arn:aws:ssm:region:account:parameter/db-password"
            }
          ]
          mount_points = []
          log_configuration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = "/ecs/mi-proyecto"
              awslogs-region        = "us-west-2"
              awslogs-stream-prefix = "api"
            }
          }
        }
      ]
    }
  }

  service_config = {
    "api" = {
      name               = "api"
      task_definition   = "api"
      desired_count     = 2
      launch_type       = "FARGATE"
      platform_version  = "1.4.0"
      scheduling_strategy = "REPLICA"
      deployment_config = {
        maximum_percent         = 200
        minimum_healthy_percent = 100
        deployment_circuit_breaker = {
          enable   = true
          rollback = true
        }
      }
      network_config = {
        assign_public_ip = false
        security_groups  = ["sg-789"]
        subnets         = ["subnet-123", "subnet-456"]
      }
      load_balancer = {
        target_group_arn = "arn:aws:elasticloadbalancing:region:account:targetgroup/api/123"
        container_name   = "api"
        container_port   = 8080
      }
      service_discovery = {
        namespace_id = "ns-123"
        dns_config = {
          dns_records = [
            {
              type = "A"
              ttl  = 60
            }
          ]
        }
      }
      auto_scaling = {
        min_capacity = 2
        max_capacity = 10
        policies = [
          {
            name               = "cpu-policy"
            policy_type       = "TargetTrackingScaling"
            target_value      = 70
            scale_in_cooldown = 300
            scale_out_cooldown = 300
            metric_type       = "ECSServiceAverageCPUUtilization"
          }
        ]
      }
    }
  }

  registry_config = {
    "api" = {
      name                 = "api"
      scan_on_push        = true
      image_tag_mutability = "MUTABLE"
      encryption_configuration = {
        encryption_type = "KMS"
        kms_key        = "arn:aws:kms:region:account:key/123"
      }
      lifecycle_policy = {
        rules = [
          {
            rulePriority = 1
            description  = "Keep last 30 images"
            selection = {
              tagStatus   = "untagged"
              countType   = "imageCountMoreThan"
              countNumber = 30
            }
            action = {
              type = "expire"
            }
          }
        ]
      }
    }
  }

  tags = {
    Environment = "prod"
    Project     = "mi-proyecto"
  }
}
```

## Mejores Prácticas

### 1. Cluster
- Multi-AZ deployment
- Capacity management
- Instance diversity
- Resource optimization

### 2. Contenedores
- Image optimization
- Security scanning
- Resource limits
- Health checks

### 3. Networking
- VPC design
- Load balancing
- Service discovery
- Security groups

### 4. Escalado
- Auto scaling
- Capacity providers
- Spot instances
- Reserved capacity

## Monitoreo y Mantenimiento

### 1. Métricas
- CPU/Memory usage
- Container health
- Service metrics
- Custom metrics

### 2. Logs
- Container logs
- Application logs
- Audit logs
- Performance logs

### 3. Alertas
- Resource utilization
- Service health
- Deployment status
- Cost thresholds

## Troubleshooting

### Problemas Comunes
1. **Despliegue**:
   - Task placement
   - Resource constraints
   - Network issues
   - Image pulls

2. **Performance**:
   - Resource utilization
   - Network latency
   - Memory leaks
   - CPU throttling

3. **Escalado**:
   - Capacity issues
   - Scaling delays
   - Instance availability
   - Cost optimization

## Seguridad

### 1. Contenedor
- Image scanning
- Runtime security
- Secret management
- Resource isolation

### 2. Red
- VPC security
- Load balancer
- Service mesh
- Network policies

### 3. Compliance
- Image compliance
- Access control
- Audit logging
- Resource tagging

## Costos y Optimización

### 1. Compute
- Instance selection
- Spot usage
- Reserved capacity
- Right-sizing

### 2. Networking
- Data transfer
- Load balancer
- NAT gateway
- VPC endpoints

### 3. Storage
- Image storage
- Volume management
- Backup retention
- Lifecycle policies 