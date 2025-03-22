# Guía Maestra: Módulo de Analytics

## Descripción General
Este módulo implementa una infraestructura de análisis de datos utilizando servicios AWS como Athena, EMR, Redshift, QuickSight y servicios relacionados, permitiendo el procesamiento y análisis de datos a gran escala.

## Componentes Principales

### 1. Amazon Athena
- **Configuración**:
  - Workgroups
  - Query optimization
  - Data catalogs
  - Output location

### 2. Amazon EMR
- **Configuración**:
  - Cluster management
  - Applications
  - Instance fleets
  - Step execution

### 3. Amazon Redshift
- **Configuración**:
  - Cluster setup
  - Workload management
  - Query optimization
  - Backup strategy

### 4. Amazon QuickSight
- **Configuración**:
  - Data sources
  - Datasets
  - Dashboards
  - User management

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

variable "athena_config" {
  description = "Configuración de Athena"
  type = object({
    workgroup_config = object({
      name                  = string
      description           = string
      state                = string
      bytes_scanned_cutoff = number
      enforce_workgroup_configuration = bool
      publish_cloudwatch_metrics_enabled = bool
      result_configuration = object({
        output_location = string
        encryption_configuration = object({
          encryption_option = string
          kms_key_arn      = string
        })
      })
      engine_version = object({
        selected_engine_version = string
      })
    })
    database_config = map(object({
      name        = string
      description = string
      location    = string
      properties  = map(string)
    }))
    named_queries = map(object({
      name        = string
      description = string
      database    = string
      query_string = string
    }))
  })
}

variable "emr_config" {
  description = "Configuración de EMR"
  type = object({
    cluster_config = object({
      name           = string
      release_label = string
      applications  = list(string)
      service_role  = string
      instance_profile = string
      log_uri       = string
      security_configuration = string
      configurations_json = string
    })
    instance_groups = map(object({
      name           = string
      instance_type = string
      instance_count = number
      bid_price     = string
      ebs_config    = object({
        size                 = number
        type                = string
        volumes_per_instance = number
      })
    }))
    bootstrap_actions = list(object({
      name = string
      path = string
      args = list(string)
    }))
    steps = list(object({
      name          = string
      action_on_failure = string
      hadoop_jar_step = object({
        jar  = string
        args = list(string)
      })
    }))
  })
}

variable "redshift_config" {
  description = "Configuración de Redshift"
  type = object({
    cluster_config = object({
      cluster_identifier = string
      database_name     = string
      master_username   = string
      node_type        = string
      number_of_nodes  = number
      port             = number
      vpc_config       = object({
        vpc_id         = string
        subnet_ids     = list(string)
        security_groups = list(string)
      })
      encryption_config = object({
        encrypted        = bool
        kms_key_id      = string
      })
      backup_config    = object({
        automated_snapshot_retention_period = number
        preferred_maintenance_window        = string
      })
      logging_config   = object({
        enable_logging = bool
        bucket_name   = string
        s3_key_prefix = string
      })
    })
    parameter_group_config = object({
      name        = string
      family      = string
      parameters  = map(string)
    })
    workload_management_config = list(object({
      name                     = string
      concurrency_scaling      = string
      query_groups            = list(string)
      user_groups             = list(string)
      wildcards               = list(string)
    }))
  })
}

variable "quicksight_config" {
  description = "Configuración de QuickSight"
  type = object({
    account_config = object({
      account_name        = string
      edition            = string
      notification_email = string
    })
    user_config = map(object({
      email      = string
      user_role  = string
      namespace  = string
    }))
    data_source_config = map(object({
      name        = string
      type        = string
      connection_config = object({
        database_name     = string
        host             = string
        port             = number
        credentials_arn  = string
      })
    }))
    dataset_config = map(object({
      name            = string
      physical_table_id = string
      import_mode     = string
      logical_table_config = object({
        alias         = string
        source_table  = string
      })
      permissions     = list(object({
        principal     = string
        actions      = list(string)
      }))
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
output "athena_workgroup_arn" {
  description = "ARN del workgroup de Athena"
  value       = aws_athena_workgroup.main.arn
}

output "athena_database_names" {
  description = "Nombres de las bases de datos de Athena"
  value       = { for k, v in aws_athena_database.databases : k => v.name }
}

output "emr_cluster_id" {
  description = "ID del cluster EMR"
  value       = aws_emr_cluster.main.id
}

output "emr_cluster_name" {
  description = "Nombre del cluster EMR"
  value       = aws_emr_cluster.main.name
}

output "redshift_cluster_id" {
  description = "ID del cluster Redshift"
  value       = aws_redshift_cluster.main.id
}

output "redshift_endpoint" {
  description = "Endpoint del cluster Redshift"
  value       = aws_redshift_cluster.main.endpoint
}

output "quicksight_account_name" {
  description = "Nombre de la cuenta QuickSight"
  value       = aws_quicksight_account.main.account_name
}

output "quicksight_user_arns" {
  description = "ARNs de los usuarios QuickSight"
  value       = { for k, v in aws_quicksight_user.users : k => v.arn }
}
```

## Uso del Módulo

```hcl
module "analytics" {
  source = "./modules/analytics"

  project_name = "mi-proyecto"
  environment  = "prod"

  athena_config = {
    workgroup_config = {
      name                  = "analytics-workgroup"
      description           = "Workgroup principal para análisis"
      state                = "ENABLED"
      bytes_scanned_cutoff = 10000000000
      enforce_workgroup_configuration = true
      publish_cloudwatch_metrics_enabled = true
      result_configuration = {
        output_location = "s3://mi-bucket/athena-results/"
        encryption_configuration = {
          encryption_option = "SSE_KMS"
          kms_key_arn      = "arn:aws:kms:region:account:key/123"
        }
      }
      engine_version = {
        selected_engine_version = "Athena engine version 2"
      }
    }
    database_config = {
      "analytics" = {
        name        = "analytics_db"
        description = "Base de datos principal para análisis"
        location    = "s3://mi-bucket/data/"
        properties  = {
          "creator" = "analytics-team"
        }
      }
    }
    named_queries = {
      "daily_metrics" = {
        name         = "daily_metrics_query"
        description  = "Consulta de métricas diarias"
        database     = "analytics_db"
        query_string = "SELECT date, count(*) as total FROM events GROUP BY date"
      }
    }
  }

  emr_config = {
    cluster_config = {
      name           = "analytics-cluster"
      release_label = "emr-6.6.0"
      applications  = ["Spark", "Hive", "Jupyter"]
      service_role  = "EMR_DefaultRole"
      instance_profile = "EMR_EC2_DefaultRole"
      log_uri       = "s3://mi-bucket/emr-logs/"
      security_configuration = "emr-security-config"
      configurations_json = jsonencode([
        {
          Classification = "spark-defaults"
          Properties = {
            "spark.driver.memory" = "5g"
          }
        }
      ])
    }
    instance_groups = {
      "master" = {
        name           = "master-group"
        instance_type = "m5.xlarge"
        instance_count = 1
        bid_price     = null
        ebs_config    = {
          size                 = 100
          type                = "gp2"
          volumes_per_instance = 1
        }
      }
    }
    bootstrap_actions = [
      {
        name = "install-dependencies"
        path = "s3://mi-bucket/scripts/install-deps.sh"
        args = []
      }
    ]
    steps = [
      {
        name              = "process-data"
        action_on_failure = "CONTINUE"
        hadoop_jar_step   = {
          jar  = "command-runner.jar"
          args = ["spark-submit", "s3://mi-bucket/scripts/process.py"]
        }
      }
    ]
  }

  redshift_config = {
    cluster_config = {
      cluster_identifier = "analytics-cluster"
      database_name     = "analytics"
      master_username   = "admin"
      node_type        = "ra3.xlplus"
      number_of_nodes  = 2
      port             = 5439
      vpc_config       = {
        vpc_id         = "vpc-123"
        subnet_ids     = ["subnet-123", "subnet-456"]
        security_groups = ["sg-789"]
      }
      encryption_config = {
        encrypted   = true
        kms_key_id = "arn:aws:kms:region:account:key/123"
      }
      backup_config    = {
        automated_snapshot_retention_period = 7
        preferred_maintenance_window        = "sun:03:00-sun:04:00"
      }
      logging_config   = {
        enable_logging = true
        bucket_name   = "mi-bucket"
        s3_key_prefix = "redshift-logs/"
      }
    }
    parameter_group_config = {
      name       = "analytics-params"
      family     = "redshift-1.0"
      parameters = {
        "wlm_json_configuration" = jsonencode([
          {
            "query_group"        = ["report_queries"]
            "memory_percent"     = 50
            "concurrency"        = 5
            "user_group"        = ["report_users"]
            "queue_timeout"     = 3600000
          }
        ])
      }
    }
    workload_management_config = [
      {
        name                = "ETL"
        concurrency_scaling = "auto"
        query_groups       = ["etl_queries"]
        user_groups        = ["etl_users"]
        wildcards         = ["etl_*"]
      }
    ]
  }

  quicksight_config = {
    account_config = {
      account_name        = "mi-empresa"
      edition            = "ENTERPRISE"
      notification_email = "admin@ejemplo.com"
    }
    user_config = {
      "admin" = {
        email     = "admin@ejemplo.com"
        user_role = "ADMIN"
        namespace = "default"
      }
    }
    data_source_config = {
      "redshift" = {
        name        = "redshift-analytics"
        type        = "REDSHIFT"
        connection_config = {
          database_name    = "analytics"
          host            = "redshift-cluster.region.redshift.amazonaws.com"
          port            = 5439
          credentials_arn = "arn:aws:secretsmanager:region:account:secret:redshift-creds"
        }
      }
    }
    dataset_config = {
      "metrics" = {
        name              = "daily-metrics"
        physical_table_id = "metrics-table"
        import_mode      = "DIRECT_QUERY"
        logical_table_config = {
          alias        = "metrics"
          source_table = "daily_metrics"
        }
        permissions = [
          {
            principal = "arn:aws:quicksight:region:account:user/default/admin"
            actions   = ["quicksight:DescribeDataSet", "quicksight:UpdateDataSet"]
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

### 1. Rendimiento
- Query optimization
- Partition management
- Resource allocation
- Caching strategy

### 2. Costos
- Data lifecycle
- Instance sizing
- Storage optimization
- Query efficiency

### 3. Seguridad
- Data encryption
- Access control
- Network isolation
- Audit logging

### 4. Escalabilidad
- Cluster sizing
- Workload management
- Auto scaling
- Resource distribution

## Monitoreo y Mantenimiento

### 1. Métricas
- Query performance
- Resource utilization
- Data volumes
- Cost tracking

### 2. Logs
- Query logs
- Error logs
- Audit logs
- Performance logs

### 3. Alertas
- Performance issues
- Cost thresholds
- Error rates
- Capacity limits

## Troubleshooting

### Problemas Comunes
1. **Performance**:
   - Query optimization
   - Resource contention
   - Data skew
   - Memory pressure

2. **Conectividad**:
   - Network access
   - VPC configuration
   - Security groups
   - IAM permissions

3. **Datos**:
   - Data quality
   - Schema evolution
   - Partition management
   - Storage issues

## Seguridad

### 1. Acceso
- IAM roles
- Security groups
- KMS encryption
- VPC endpoints

### 2. Datos
- Encryption at rest
- Encryption in transit
- Data masking
- Column-level security

### 3. Auditoría
- CloudTrail logs
- CloudWatch logs
- Query history
- User activity

## Costos y Optimización

### 1. Compute
- Instance selection
- Concurrency scaling
- Query optimization
- Workload management

### 2. Storage
- Compression
- Data lifecycle
- Table design
- Partition strategy

### 3. Operaciones
- Maintenance windows
- Backup retention
- Resource scheduling
- Cost allocation 