# Guía Maestra: Módulo de Data Processing

## Descripción General
Este módulo implementa una infraestructura de procesamiento de datos utilizando servicios AWS como AWS Glue, AWS Lambda, Step Functions, y Kinesis, permitiendo el procesamiento de datos en tiempo real y por lotes.

## Componentes Principales

### 1. AWS Glue
- **Configuración**:
  - ETL jobs
  - Crawlers
  - Data Catalog
  - Development endpoints

### 2. AWS Lambda
- **Configuración**:
  - Functions
  - Layers
  - Event sources
  - Destinations

### 3. Step Functions
- **Configuración**:
  - State machines
  - Task definitions
  - Error handling
  - Parallel execution

### 4. Kinesis
- **Configuración**:
  - Data Streams
  - Firehose
  - Analytics
  - Consumers

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

variable "glue_config" {
  description = "Configuración de AWS Glue"
  type = object({
    job_config = map(object({
      name                   = string
      description           = string
      role_arn             = string
      glue_version         = string
      worker_type          = string
      number_of_workers    = number
      max_retries          = number
      timeout              = number
      script_location      = string
      default_arguments    = map(string)
      connections          = list(string)
      max_concurrent_runs  = number
      notification_property = object({
        notify_delay_after = number
      })
      execution_property   = object({
        max_concurrent_runs = number
      })
    }))
    crawler_config = map(object({
      name                  = string
      role                 = string
      database_name        = string
      schedule            = string
      table_prefix        = string
      s3_target           = list(object({
        path              = string
        exclusions       = list(string)
      }))
      schema_change_policy = object({
        update_behavior = string
        delete_behavior = string
      })
      recrawl_policy      = object({
        recrawl_behavior = string
      })
    }))
    connection_config = map(object({
      name                = string
      connection_type    = string
      connection_properties = map(string)
      physical_connection_requirements = object({
        availability_zone      = string
        security_group_id_list = list(string)
        subnet_id              = string
      })
    }))
  })
}

variable "lambda_config" {
  description = "Configuración de AWS Lambda"
  type = map(object({
    function_name          = string
    description           = string
    handler               = string
    runtime               = string
    memory_size           = number
    timeout               = number
    role_arn             = string
    environment          = map(string)
    vpc_config           = object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    })
    dead_letter_config   = object({
      target_arn = string
    })
    tracing_config       = object({
      mode = string
    })
    layers               = list(string)
    tags                = map(string)
  }))
}

variable "step_functions_config" {
  description = "Configuración de Step Functions"
  type = map(object({
    name           = string
    role_arn      = string
    definition    = string
    type          = string
    logging_configuration = object({
      level               = string
      include_execution_data = bool
      destination        = string
    })
    tracing_configuration = object({
      enabled = bool
    })
    tags          = map(string)
  }))
}

variable "kinesis_config" {
  description = "Configuración de Kinesis"
  type = object({
    stream_config = map(object({
      name                      = string
      shard_count              = number
      retention_period         = number
      encryption_type         = string
      kms_key_id              = string
      enforce_consumer_deletion = bool
      tags                    = map(string)
    }))
    firehose_config = map(object({
      name                    = string
      destination            = string
      buffer_size            = number
      buffer_interval        = number
      compression_format     = string
      prefix                 = string
      error_output_prefix    = string
      s3_backup_mode        = string
      processing_configuration = object({
        enabled = bool
        processors = list(object({
          type = string
          parameters = list(object({
            parameter_name  = string
            parameter_value = string
          }))
        }))
      })
    }))
    analytics_config = map(object({
      name                        = string
      input_stream_arn           = string
      output_stream_arn          = string
      code                       = string
      input_parallelism         = number
      output_parallelism        = number
      input_schema_version      = string
      application_configuration = object({
        sql_configuration = object({
          input_schema  = string
        })
        environment_properties = object({
          property_groups = map(map(string))
        })
      })
    }))
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
output "glue_job_arns" {
  description = "ARNs de los jobs de Glue"
  value       = { for k, v in aws_glue_job.jobs : k => v.arn }
}

output "glue_crawler_names" {
  description = "Nombres de los crawlers de Glue"
  value       = { for k, v in aws_glue_crawler.crawlers : k => v.name }
}

output "lambda_function_arns" {
  description = "ARNs de las funciones Lambda"
  value       = { for k, v in aws_lambda_function.functions : k => v.arn }
}

output "step_function_arns" {
  description = "ARNs de las máquinas de estado"
  value       = { for k, v in aws_sfn_state_machine.state_machines : k => v.arn }
}

output "kinesis_stream_arns" {
  description = "ARNs de los streams de Kinesis"
  value       = { for k, v in aws_kinesis_stream.streams : k => v.arn }
}

output "kinesis_firehose_arns" {
  description = "ARNs de los Firehose"
  value       = { for k, v in aws_kinesis_firehose_delivery_stream.firehose : k => v.arn }
}
```

## Uso del Módulo

```hcl
module "processing" {
  source = "./modules/processing"

  project_name = "mi-proyecto"
  environment  = "prod"

  glue_config = {
    job_config = {
      "etl-job" = {
        name               = "etl-proceso-principal"
        description       = "Job ETL para procesamiento principal"
        role_arn         = "arn:aws:iam::account:role/GlueETLRole"
        glue_version     = "3.0"
        worker_type      = "G.1X"
        number_of_workers = 2
        max_retries      = 3
        timeout          = 2880
        script_location  = "s3://mi-bucket/scripts/etl-main.py"
        default_arguments = {
          "--enable-metrics" = "true"
          "--job-language"  = "python"
        }
        connections     = ["my-jdbc-connection"]
        max_concurrent_runs = 1
        notification_property = {
          notify_delay_after = 1800
        }
        execution_property = {
          max_concurrent_runs = 1
        }
      }
    }
    crawler_config = {
      "data-crawler" = {
        name           = "raw-data-crawler"
        role          = "arn:aws:iam::account:role/GlueCrawlerRole"
        database_name = "raw_data"
        schedule     = "cron(0 1 * * ? *)"
        table_prefix = "raw_"
        s3_target    = [
          {
            path       = "s3://mi-bucket/raw-data/"
            exclusions = ["*.tmp", "*.temp"]
          }
        ]
        schema_change_policy = {
          update_behavior = "UPDATE_IN_DATABASE"
          delete_behavior = "LOG"
        }
        recrawl_policy = {
          recrawl_behavior = "CRAWL_EVERYTHING"
        }
      }
    }
    connection_config = {
      "jdbc-connection" = {
        name                = "my-jdbc-connection"
        connection_type    = "JDBC"
        connection_properties = {
          JDBC_CONNECTION_URL = "jdbc:postgresql://host:5432/database"
          USERNAME           = "admin"
          PASSWORD           = "{{resolve:secretsmanager:db-creds:SecretString:password}}"
        }
        physical_connection_requirements = {
          availability_zone      = "us-west-2a"
          security_group_id_list = ["sg-123"]
          subnet_id              = "subnet-123"
        }
      }
    }
  }

  lambda_config = {
    "data-processor" = {
      function_name    = "data-processor"
      description     = "Procesa datos en tiempo real"
      handler         = "index.handler"
      runtime         = "nodejs18.x"
      memory_size     = 256
      timeout         = 300
      role_arn       = "arn:aws:iam::account:role/LambdaProcessorRole"
      environment    = {
        STAGE = "prod"
        LOG_LEVEL = "INFO"
      }
      vpc_config     = {
        subnet_ids         = ["subnet-123", "subnet-456"]
        security_group_ids = ["sg-789"]
      }
      dead_letter_config = {
        target_arn = "arn:aws:sqs:region:account:dlq"
      }
      tracing_config   = {
        mode = "Active"
      }
      layers          = ["arn:aws:lambda:region:account:layer:my-layer:1"]
      tags           = {
        Service = "data-processing"
      }
    }
  }

  step_functions_config = {
    "etl-workflow" = {
      name        = "etl-workflow"
      role_arn   = "arn:aws:iam::account:role/StepFunctionsETLRole"
      type       = "STANDARD"
      definition = jsonencode({
        StartAt = "StartETLProcess"
        States = {
          StartETLProcess = {
            Type = "Task"
            Resource = "arn:aws:states:::glue:startJobRun.sync"
            Parameters = {
              JobName = "etl-proceso-principal"
            }
            Next = "ProcessResults"
          }
          ProcessResults = {
            Type = "Task"
            Resource = "arn:aws:states:::lambda:invoke"
            Parameters = {
              FunctionName = "data-processor"
              Payload = {
                "operation": "process-results"
              }
            }
            End = true
          }
        }
      })
      logging_configuration = {
        level                  = "ALL"
        include_execution_data = true
        destination           = "arn:aws:logs:region:account:log-group:/aws/stepfunctions/etl"
      }
      tracing_configuration = {
        enabled = true
      }
      tags = {
        Workflow = "ETL"
      }
    }
  }

  kinesis_config = {
    stream_config = {
      "data-stream" = {
        name                      = "data-ingestion-stream"
        shard_count              = 2
        retention_period         = 24
        encryption_type         = "KMS"
        kms_key_id              = "arn:aws:kms:region:account:key/123"
        enforce_consumer_deletion = true
        tags                    = {
          Stream = "data-ingestion"
        }
      }
    }
    firehose_config = {
      "s3-delivery" = {
        name                 = "s3-data-delivery"
        destination         = "s3"
        buffer_size         = 5
        buffer_interval     = 300
        compression_format  = "GZIP"
        prefix             = "raw-data/year=!{timestamp:yyyy}/month=!{timestamp:MM}/"
        error_output_prefix = "errors/!{firehose:error-output-type}/!{timestamp:yyyy}/month=!{timestamp:MM}/"
        s3_backup_mode     = "Enabled"
        processing_configuration = {
          enabled = true
          processors = [
            {
              type = "Lambda"
              parameters = [
                {
                  parameter_name  = "LambdaArn"
                  parameter_value = "arn:aws:lambda:region:account:function:data-processor"
                }
              ]
            }
          ]
        }
      }
    }
    analytics_config = {
      "realtime-analytics" = {
        name                  = "realtime-processing"
        input_stream_arn     = "arn:aws:kinesis:region:account:stream/data-ingestion-stream"
        output_stream_arn    = "arn:aws:kinesis:region:account:stream/processed-data-stream"
        code                 = file("analytics/process.sql")
        input_parallelism   = 1
        output_parallelism  = 1
        input_schema_version = "1.0"
        application_configuration = {
          sql_configuration = {
            input_schema = jsonencode({
              RecordColumns = [
                {
                  Name = "timestamp"
                  SqlType = "TIMESTAMP"
                },
                {
                  Name = "data"
                  SqlType = "VARCHAR(255)"
                }
              ]
            })
          }
          environment_properties = {
            property_groups = {
              ProcessingConfig = {
                MetricsLevel = "APPLICATION"
                LogLevel    = "INFO"
              }
            }
          }
        }
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

### 1. ETL
- Optimizar jobs
- Gestionar recursos
- Manejar errores
- Monitorear ejecución

### 2. Procesamiento
- Arquitectura escalable
- Manejo de estados
- Control de errores
- Retries automáticos

### 3. Streaming
- Particionamiento
- Buffer sizing
- Error handling
- Backup strategy

### 4. Performance
- Resource allocation
- Concurrent execution
- Memory management
- Timeout configuration

## Monitoreo y Mantenimiento

### 1. Métricas
- Job execution
- Stream throughput
- Error rates
- Processing latency

### 2. Logs
- Application logs
- Error logs
- Audit logs
- Performance logs

### 3. Alertas
- Job failures
- Stream throttling
- Processing delays
- Resource utilization

## Troubleshooting

### Problemas Comunes
1. **ETL**:
   - Job failures
   - Memory issues
   - Timeout errors
   - Connection problems

2. **Streaming**:
   - Throttling
   - Data loss
   - Processing delays
   - Backup failures

3. **Performance**:
   - Resource constraints
   - Concurrency issues
   - Network latency
   - Memory pressure

## Seguridad

### 1. Acceso
- IAM roles
- KMS encryption
- VPC endpoints
- Security groups

### 2. Datos
- Encryption at rest
- Encryption in transit
- Data validation
- Access logging

### 3. Compliance
- Audit trails
- Data retention
- Access control
- Monitoring

## Costos y Optimización

### 1. Compute
- Resource sizing
- Concurrent jobs
- Spot instances
- Auto-scaling

### 2. Storage
- Data lifecycle
- Compression
- Retention periods
- Storage class

### 3. Streaming
- Shard optimization
- Buffer tuning
- Batch processing
- Resource allocation 