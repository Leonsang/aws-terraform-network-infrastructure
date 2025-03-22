# Guía Maestra: Módulo de CDN

## Descripción General
Este módulo implementa una red de distribución de contenido utilizando Amazon CloudFront, con configuraciones de caché, SSL/TLS, WAF y logs detallados.

## Componentes Principales

### 1. CloudFront Distribution
- **Configuración**:
  - Origins
  - Behaviors
  - Cache policies
  - SSL/TLS

### 2. Origin Access Identity
- **Seguridad**:
  - S3 access
  - Custom origins
  - IAM policies
  - Security headers

### 3. WAF Integration
- **Protección**:
  - Rule groups
  - IP filtering
  - Rate limiting
  - Geo restrictions

### 4. Logging
- **Análisis**:
  - Access logs
  - Real-time logs
  - Error logs
  - Cache statistics

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

variable "distribution_config" {
  description = "Configuración de la distribución CloudFront"
  type = object({
    enabled             = bool
    price_class         = string
    default_root_object = string
    aliases            = list(string)
    comment            = string
    http_version       = string
    ipv6_enabled       = bool
  })
}

variable "origin_config" {
  description = "Configuración de origins"
  type = object({
    s3_origins = list(object({
      bucket_name = string
      origin_path = string
      origin_id   = string
    }))
    custom_origins = list(object({
      domain_name = string
      origin_path = string
      origin_id   = string
      http_port   = number
      https_port  = number
      protocol_policy = string
    }))
  })
}

variable "cache_config" {
  description = "Configuración de caché"
  type = object({
    default_ttl        = number
    max_ttl           = number
    min_ttl           = number
    compress          = bool
    query_string      = bool
    cookies          = list(string)
    headers          = list(string)
  })
}

variable "ssl_config" {
  description = "Configuración SSL/TLS"
  type = object({
    acm_certificate_arn = string
    minimum_protocol_version = string
    ssl_support_method = string
  })
}

variable "waf_config" {
  description = "Configuración de WAF"
  type = object({
    enabled           = bool
    web_acl_id       = string
    ip_rate_limit    = number
    geo_restrictions = list(string)
  })
}

variable "logging_config" {
  description = "Configuración de logs"
  type = object({
    bucket           = string
    prefix           = string
    include_cookies  = bool
    realtime_logging = bool
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
output "distribution_id" {
  description = "ID de la distribución CloudFront"
  value       = aws_cloudfront_distribution.main.id
}

output "distribution_domain_name" {
  description = "Dominio de la distribución CloudFront"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "distribution_arn" {
  description = "ARN de la distribución CloudFront"
  value       = aws_cloudfront_distribution.main.arn
}

output "origin_access_identity_id" {
  description = "ID del Origin Access Identity"
  value       = aws_cloudfront_origin_access_identity.main.id
}

output "origin_access_identity_path" {
  description = "Path del Origin Access Identity"
  value       = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
}

output "waf_web_acl_id" {
  description = "ID del Web ACL de WAF"
  value       = var.waf_config.enabled ? var.waf_config.web_acl_id : null
}
```

## Uso del Módulo

```hcl
module "cdn" {
  source = "./modules/cdn"

  project_name = "mi-proyecto"
  environment  = "prod"

  distribution_config = {
    enabled             = true
    price_class         = "PriceClass_100"
    default_root_object = "index.html"
    aliases            = ["www.ejemplo.com"]
    comment            = "Distribución principal"
    http_version       = "http2"
    ipv6_enabled       = true
  }

  origin_config = {
    s3_origins = [{
      bucket_name = "mi-bucket"
      origin_path = "/contenido"
      origin_id   = "S3-Principal"
    }]
    custom_origins = [{
      domain_name     = "api.ejemplo.com"
      origin_path     = ""
      origin_id       = "API-Principal"
      http_port       = 80
      https_port      = 443
      protocol_policy = "https-only"
    }]
  }

  cache_config = {
    default_ttl   = 3600
    max_ttl      = 86400
    min_ttl      = 0
    compress     = true
    query_string = true
    cookies      = ["*"]
    headers      = ["Origin", "Access-Control-Request-Method"]
  }

  ssl_config = {
    acm_certificate_arn     = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method      = "sni-only"
  }

  waf_config = {
    enabled          = true
    web_acl_id       = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/ejemplo/abc123"
    ip_rate_limit    = 2000
    geo_restrictions = ["US", "CA", "MX"]
  }

  logging_config = {
    bucket           = "mi-bucket-logs"
    prefix           = "cdn/"
    include_cookies  = true
    realtime_logging = false
  }

  tags = {
    Environment = "prod"
    Project     = "mi-proyecto"
  }
}
```

## Mejores Prácticas

### 1. Performance
- Optimizar cache TTL
- Comprimir contenido
- Configurar origins
- Implementar HTTP/2

### 2. Seguridad
- Implementar HTTPS
- Configurar WAF
- Restringir acceso
- Monitorear logs

### 3. Disponibilidad
- Multiple origins
- Origin failover
- Error pages
- Health checks

### 4. Costos
- Optimizar price class
- Monitorear uso
- Configurar cache
- Analizar patrones

## Monitoreo y Mantenimiento

### 1. Métricas
- Request count
- Cache hit ratio
- Error rates
- Bandwidth usage

### 2. Logs
- Access logs
- Error logs
- Cache behavior
- Security events

### 3. Alertas
- Error spikes
- Cache misses
- Security incidents
- Cost thresholds

## Troubleshooting

### Problemas Comunes
1. **Cache**:
   - Cache misses
   - TTL issues
   - Invalidation delays
   - Origin errors

2. **SSL/TLS**:
   - Certificate errors
   - Protocol issues
   - SNI problems
   - Origin compatibility

3. **Performance**:
   - Origin latency
   - Cache efficiency
   - Compression issues
   - Routing problems

## Seguridad

### 1. SSL/TLS
- Certificados ACM
- Versiones TLS
- HSTS
- Custom SSL

### 2. WAF
- Rule sets
- Rate limiting
- IP blocking
- Geo blocking

### 3. Access Control
- Origin access
- Signed URLs
- Signed cookies
- Referer checking

## Costos y Optimización

### 1. Traffic
- Price class
- Regional restrictions
- Cache optimization
- Origin selection

### 2. Features
- SSL certificates
- WAF rules
- Real-time logs
- Field-level encryption

### 3. Monitoring
- Usage patterns
- Cost allocation
- Traffic analysis
- Optimization opportunities 