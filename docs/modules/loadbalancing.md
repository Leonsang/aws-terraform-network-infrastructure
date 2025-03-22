# Guía Maestra: Módulo de Load Balancing

## Descripción General
Este módulo implementa balanceo de carga utilizando AWS Elastic Load Balancing (ELB) con soporte para Application Load Balancer (ALB), Network Load Balancer (NLB) y Gateway Load Balancer (GWLB).

## Componentes Principales

### 1. Application Load Balancer
- **Configuración**:
  - Listeners HTTP/HTTPS
  - Target groups
  - SSL certificates
  - WAF integration

### 2. Network Load Balancer
- **Configuración**:
  - TCP/UDP listeners
  - Static IPs
  - Cross-zone balancing
  - TLS termination

### 3. Gateway Load Balancer
- **Configuración**:
  - GENEVE protocol
  - Virtual appliances
  - Health checks
  - Target groups

### 4. Target Groups
- **Configuración**:
  - Health checks
  - Stickiness
  - Deregistration delay
  - Load balancing algorithms

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

variable "alb_config" {
  description = "Configuración del Application Load Balancer"
  type = object({
    internal           = bool
    load_balancer_type = string
    security_groups    = list(string)
    subnets           = list(string)
    idle_timeout      = number
    enable_deletion_protection = bool
    enable_http2      = bool
    enable_waf        = bool
  })
}

variable "nlb_config" {
  description = "Configuración del Network Load Balancer"
  type = object({
    internal           = bool
    subnets           = list(string)
    enable_cross_zone = bool
    allocation_ids    = list(string)
    enable_deletion_protection = bool
  })
}

variable "gwlb_config" {
  description = "Configuración del Gateway Load Balancer"
  type = object({
    subnets           = list(string)
    enable_cross_zone = bool
    target_type      = string
  })
}

variable "listener_config" {
  description = "Configuración de listeners"
  type = object({
    alb_listeners = list(object({
      port               = number
      protocol           = string
      ssl_policy        = string
      certificate_arn   = string
      default_action    = map(any)
    }))
    nlb_listeners = list(object({
      port               = number
      protocol           = string
      certificate_arn   = string
      ssl_policy        = string
    }))
  })
}

variable "target_group_config" {
  description = "Configuración de target groups"
  type = object({
    port                = number
    protocol            = string
    target_type        = string
    deregistration_delay = number
    slow_start         = number
    health_check = object({
      enabled           = bool
      interval         = number
      path             = string
      port             = string
      healthy_threshold = number
      unhealthy_threshold = number
      timeout          = number
    })
    stickiness = object({
      enabled          = bool
      type            = string
      cookie_duration = number
    })
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
output "alb_id" {
  description = "ID del Application Load Balancer"
  value       = aws_lb.alb[0].id
}

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.alb[0].arn
}

output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = aws_lb.alb[0].dns_name
}

output "nlb_id" {
  description = "ID del Network Load Balancer"
  value       = aws_lb.nlb[0].id
}

output "nlb_arn" {
  description = "ARN del Network Load Balancer"
  value       = aws_lb.nlb[0].arn
}

output "nlb_dns_name" {
  description = "DNS name del Network Load Balancer"
  value       = aws_lb.nlb[0].dns_name
}

output "gwlb_id" {
  description = "ID del Gateway Load Balancer"
  value       = aws_lb.gwlb[0].id
}

output "target_group_arns" {
  description = "ARNs de los target groups"
  value       = aws_lb_target_group.main[*].arn
}
```

## Uso del Módulo

```hcl
module "loadbalancing" {
  source = "./modules/loadbalancing"

  project_name = "mi-proyecto"
  environment  = "prod"

  alb_config = {
    internal           = false
    load_balancer_type = "application"
    security_groups    = ["sg-12345678"]
    subnets           = ["subnet-a1b2c3d4", "subnet-e5f6g7h8"]
    idle_timeout      = 60
    enable_deletion_protection = true
    enable_http2      = true
    enable_waf        = true
  }

  nlb_config = {
    internal           = false
    subnets           = ["subnet-a1b2c3d4", "subnet-e5f6g7h8"]
    enable_cross_zone = true
    allocation_ids    = []
    enable_deletion_protection = true
  }

  gwlb_config = {
    subnets           = ["subnet-a1b2c3d4", "subnet-e5f6g7h8"]
    enable_cross_zone = true
    target_type      = "instance"
  }

  listener_config = {
    alb_listeners = [{
      port              = 443
      protocol          = "HTTPS"
      ssl_policy       = "ELBSecurityPolicy-2016-08"
      certificate_arn  = "arn:aws:acm:region:account:certificate/abc123"
      default_action   = {
        type = "forward"
        target_group_arn = "arn:aws:elasticloadbalancing:region:account:targetgroup/tg-name/abc123"
      }
    }]
    nlb_listeners = [{
      port              = 443
      protocol          = "TLS"
      certificate_arn  = "arn:aws:acm:region:account:certificate/abc123"
      ssl_policy       = "ELBSecurityPolicy-2016-08"
    }]
  }

  target_group_config = {
    port                = 80
    protocol            = "HTTP"
    target_type        = "instance"
    deregistration_delay = 300
    slow_start         = 0
    health_check = {
      enabled           = true
      interval         = 30
      path             = "/health"
      port             = "traffic-port"
      healthy_threshold = 3
      unhealthy_threshold = 3
      timeout          = 5
    }
    stickiness = {
      enabled          = true
      type            = "lb_cookie"
      cookie_duration = 86400
    }
  }

  tags = {
    Environment = "prod"
    Project     = "mi-proyecto"
  }
}
```

## Mejores Prácticas

### 1. Alta Disponibilidad
- Multi-AZ deployment
- Cross-zone balancing
- Health checks
- Failover configuration

### 2. Seguridad
- SSL/TLS termination
- Security groups
- WAF integration
- Access logging

### 3. Performance
- Connection draining
- Sticky sessions
- HTTP/2 support
- Buffer sizes

### 4. Monitoreo
- CloudWatch metrics
- Access logs
- Health check logs
- Flow logs

## Monitoreo y Mantenimiento

### 1. Métricas
- Request count
- Latency
- Error rates
- Healthy hosts

### 2. Logs
- Access logs
- Error logs
- Health check logs
- Flow logs

### 3. Alertas
- High latency
- Error spikes
- Unhealthy hosts
- Certificate expiration

## Troubleshooting

### Problemas Comunes
1. **Conectividad**:
   - Security groups
   - Health checks
   - Target registration
   - SSL/TLS issues

2. **Performance**:
   - Latency spikes
   - Connection limits
   - Buffer exhaustion
   - Timeout issues

3. **Escalabilidad**:
   - Target capacity
   - Connection draining
   - Sticky sessions
   - Cross-zone balancing

## Seguridad

### 1. SSL/TLS
- Certificate management
- Security policies
- HTTPS redirection
- Perfect forward secrecy

### 2. Network
- Security groups
- NACLs
- VPC endpoints
- WAF rules

### 3. Monitoring
- Access logging
- Flow logs
- CloudTrail
- CloudWatch

## Costos y Optimización

### 1. Capacity
- Right-sizing
- Auto scaling
- Cross-zone optimization
- Reserved capacity

### 2. Traffic
- Data transfer
- Request handling
- SSL/TLS offloading
- WAF rules

### 3. Monitoring
- Usage patterns
- Cost allocation
- Performance metrics
- Optimization opportunities 