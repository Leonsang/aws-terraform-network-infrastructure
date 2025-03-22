# Guía Maestra: Módulo de Serverless

## Descripción General
Este módulo implementa una arquitectura serverless utilizando AWS Lambda, API Gateway, DynamoDB y otros servicios serverless de AWS, permitiendo el despliegue de aplicaciones sin servidor altamente escalables y rentables.

## Componentes Principales

### 1. AWS Lambda
- **Configuración**:
  - Runtime environments
  - Memory allocation
  - Timeout settings
  - Concurrency limits
  - VPC configuration

### 2. API Gateway
- **Configuración**:
  - REST/HTTP APIs
  - WebSocket support
  - Custom domains
  - Stage deployments

### 3. DynamoDB
- **Configuración**:
  - Table design
  - Capacity mode
  - Indexes
  - Stream configuration

### 4. Event Sources
- **Tipos**:
  - SQS queues
  - SNS topics
  - S3 events
  - CloudWatch Events

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

variable "lambda_config" {
  description = "Configuración de funciones Lambda"
  type = map(object({
    runtime          = string
    handler         = string
    memory_size     = number
    timeout         = number
    environment     = map(string)
    vpc_config      = object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    })
    tracing_config  = string
    layers          = list(string)
    reserved_concurrent_executions = number
  }))
}

variable "api_gateway_config" {
  description = "Configuración de API Gateway"
  type = object({
    type                = string
    protocol_type      = string
    description        = string
    binary_media_types = list(string)
    cors_configuration = object({
      allow_origins     = list(string)
      allow_methods     = list(string)
      allow_headers     = list(string)
      expose_headers    = list(string)
      max_age          = number
    })
    domain_config     = object({
      domain_name     = string
      certificate_arn = string
    })
  })
}

variable "dynamodb_config" {
  description = "Configuración de tablas DynamoDB"
  type = map(object({
    billing_mode   = string
    hash_key      = string
    range_key     = string
    attributes    = list(object({
      name = string
      type = string
    }))
    global_secondary_indexes = list(object({
      name               = string
      hash_key          = string
      range_key         = string
      projection_type   = string
      non_key_attributes = list(string)
    }))
    stream_enabled = bool
    stream_view_type = string
    ttl_enabled    = bool
    ttl_attribute  = string
  }))
}

variable "event_source_config" {
  description = "Configuración de fuentes de eventos"
  type = map(object({
    type           = string
    batch_size    = number
    starting_position = string
    maximum_retry_attempts = number
    maximum_record_age_in_seconds = number
    bisect_batch_on_function_error = bool
    parallelization_factor = number
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
output "lambda_function_names" {
  description = "Nombres de las funciones Lambda"
  value       = { for k, v in aws_lambda_function.functions : k => v.function_name }
}

output "lambda_function_arns" {
  description = "ARNs de las funciones Lambda"
  value       = { for k, v in aws_lambda_function.functions : k => v.arn }
}

output "api_gateway_id" {
  description = "ID del API Gateway"
  value       = aws_apigatewayv2_api.main.id
}

output "api_gateway_endpoint" {
  description = "Endpoint del API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "dynamodb_table_names" {
  description = "Nombres de las tablas DynamoDB"
  value       = { for k, v in aws_dynamodb_table.tables : k => v.name }
}

output "dynamodb_table_arns" {
  description = "ARNs de las tablas DynamoDB"
  value       = { for k, v in aws_dynamodb_table.tables : k => v.arn }
}
```

## Uso del Módulo

```hcl
module "serverless" {
  source = "./modules/serverless"

  project_name = "mi-proyecto"
  environment  = "prod"

  lambda_config = {
    "api-handler" = {
      runtime          = "nodejs18.x"
      handler         = "index.handler"
      memory_size     = 256
      timeout         = 30
      environment     = {
        TABLE_NAME = "users"
        API_KEY    = "secret-key"
      }
      vpc_config      = {
        subnet_ids         = ["subnet-123", "subnet-456"]
        security_group_ids = ["sg-789"]
      }
      tracing_config  = "Active"
      layers          = []
      reserved_concurrent_executions = -1
    }
  }

  api_gateway_config = {
    type                = "HTTP"
    protocol_type      = "HTTP"
    description        = "API Principal"
    binary_media_types = ["application/json"]
    cors_configuration = {
      allow_origins     = ["*"]
      allow_methods     = ["GET", "POST", "PUT", "DELETE"]
      allow_headers     = ["*"]
      expose_headers    = []
      max_age          = 3600
    }
    domain_config     = {
      domain_name     = "api.ejemplo.com"
      certificate_arn = "arn:aws:acm:region:account:certificate/123"
    }
  }

  dynamodb_config = {
    "users" = {
      billing_mode   = "PAY_PER_REQUEST"
      hash_key      = "id"
      range_key     = "email"
      attributes    = [
        {
          name = "id"
          type = "S"
        },
        {
          name = "email"
          type = "S"
        }
      ]
      global_secondary_indexes = [
        {
          name               = "EmailIndex"
          hash_key          = "email"
          range_key         = null
          projection_type   = "ALL"
          non_key_attributes = []
        }
      ]
      stream_enabled = true
      stream_view_type = "NEW_AND_OLD_IMAGES"
      ttl_enabled    = true
      ttl_attribute  = "expirationTime"
    }
  }

  event_source_config = {
    "sqs-trigger" = {
      type           = "SQS"
      batch_size    = 10
      starting_position = null
      maximum_retry_attempts = 3
      maximum_record_age_in_seconds = 21600
      bisect_batch_on_function_error = true
      parallelization_factor = 10
    }
  }

  tags = {
    Environment = "prod"
    Project     = "mi-proyecto"
  }
}
```

## Mejores Prácticas

### 1. Lambda
- Optimizar memoria
- Manejar timeouts
- Implementar retries
- Usar layers

### 2. API Gateway
- Implementar caching
- Configurar throttling
- Usar custom domains
- Validar requests

### 3. DynamoDB
- Diseñar particiones
- Optimizar índices
- Gestionar capacidad
- Implementar TTL

### 4. Eventos
- Configurar DLQ
- Manejar errores
- Optimizar batch size
- Monitorear latencia

## Monitoreo y Mantenimiento

### 1. Métricas
- Invocaciones
- Duración
- Errores
- Throttling

### 2. Logs
- CloudWatch Logs
- X-Ray traces
- API access logs
- DynamoDB streams

### 3. Alertas
- Error rates
- Latencia
- Throttling
- Costos

## Troubleshooting

### Problemas Comunes
1. **Lambda**:
   - Cold starts
   - Memory leaks
   - Timeout issues
   - VPC connectivity

2. **API Gateway**:
   - CORS errors
   - Integration timeouts
   - Authorization issues
   - Rate limiting

3. **DynamoDB**:
   - Hot partitions
   - Capacity issues
   - Query performance
   - Consistency

## Seguridad

### 1. Autenticación
- IAM roles
- Cognito
- API keys
- Custom authorizers

### 2. Datos
- Encryption at rest
- Encryption in transit
- VPC endpoints
- Access patterns

### 3. Compliance
- Audit logging
- Resource policies
- Service limits
- Backup strategies

## Costos y Optimización

### 1. Lambda
- Memory sizing
- Concurrent executions
- Code optimization
- Layer usage

### 2. API Gateway
- Caching
- Request validation
- Usage plans
- Stage optimization

### 3. DynamoDB
- Capacity mode
- Auto scaling
- TTL cleanup
- Backup retention 