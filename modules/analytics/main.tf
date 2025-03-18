# Módulo de analítica para el proyecto de Detección de Fraude Financiero
# Implementa los componentes de analítica: Redshift, Athena, QuickSight

locals {
  redshift_cluster_identifier = "${var.project_name}-${var.environment}-cluster"
  athena_workgroup_name      = "${var.project_name}-${var.environment}-workgroup"
  athena_database_name       = replace("${var.project_name}_${var.environment}_analytics", "-", "_")
  
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  })
}

# Subnet group para Redshift
resource "aws_redshift_subnet_group" "main" {
  count = var.create_redshift ? 1 : 0
  
  name       = "${var.project_name}-${var.environment}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = local.common_tags
}

# Grupo de parámetros para Redshift
resource "aws_redshift_parameter_group" "main" {
  count = var.create_redshift ? 1 : 0
  
  family = "redshift-1.0"
  name   = "${var.project_name}-${var.environment}-params"

  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }

  parameter {
    name  = "require_ssl"
    value = "true"
  }

  tags = local.common_tags
}

# Cluster Redshift
resource "aws_redshift_cluster" "main" {
  count = var.create_redshift ? 1 : 0
  
  cluster_identifier = local.redshift_cluster_identifier
  database_name      = replace("${var.project_name}_${var.environment}", "-", "_")
  master_username    = var.redshift_username
  master_password    = var.redshift_password
  node_type         = var.redshift_node_type
  cluster_type      = var.redshift_node_count > 1 ? "multi-node" : "single-node"
  number_of_nodes   = var.redshift_node_count

  cluster_subnet_group_name = aws_redshift_subnet_group.main[0].name
  cluster_parameter_group_name = aws_redshift_parameter_group.main[0].name
  vpc_security_group_ids   = var.security_group_ids
  skip_final_snapshot     = true
  publicly_accessible     = false
  port                    = 5439

  encrypted = true
  
  tags = local.common_tags
}

# Configuración de logging para Redshift
resource "aws_redshift_logging" "main" {
  count = var.create_redshift ? 1 : 0
  
  cluster_identifier    = aws_redshift_cluster.main[0].id
  bucket_name          = var.logging_bucket_name
  s3_key_prefix        = "redshift-logs/${var.project_name}/${var.environment}"
  log_destination_type = "s3"
  log_exports          = ["connectionlog", "userlog", "useractivitylog"]
}

# Workgroup de Athena
resource "aws_athena_workgroup" "main" {
  name = local.athena_workgroup_name

  configuration {
    enforce_workgroup_configuration = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.analytics_bucket_name}/athena-results/"
      
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = local.common_tags
}

# Base de datos de Athena
resource "aws_glue_catalog_database" "analytics" {
  name = local.athena_database_name
}

# Crawler de Glue para datos procesados
resource "aws_glue_crawler" "processed_data" {
  database_name = aws_glue_catalog_database.analytics.name
  name         = "${var.project_name}-${var.environment}-processed-crawler"
  role         = var.glue_role_arn

  s3_target {
    path = "s3://${var.processed_bucket_name}/processed-data/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  tags = local.common_tags
}

# Tabla de Athena para transacciones procesadas
resource "aws_glue_catalog_table" "transactions" {
  name          = "transactions"
  database_name = aws_glue_catalog_database.analytics.name
  
  table_type = "EXTERNAL_TABLE"
  
  parameters = {
    "classification"  = "parquet"
    "typeOfData"     = "file"
  }

  storage_descriptor {
    location      = "s3://${var.processed_bucket_name}/processed-data/transactions/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    
    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "transaction_id"
      type = "string"
    }
    columns {
      name = "amount"
      type = "double"
    }
    columns {
      name = "timestamp"
      type = "timestamp"
    }
    columns {
      name = "card_id"
      type = "string"
    }
    columns {
      name = "merchant"
      type = "string"
    }
    columns {
      name = "category"
      type = "string"
    }
    columns {
      name = "is_fraud"
      type = "boolean"
    }
  }
}

# Consultas guardadas de Athena
resource "aws_athena_named_query" "fraud_summary" {
  name        = "${var.project_name}-${var.environment}-fraud-summary"
  workgroup   = aws_athena_workgroup.main.name
  database    = aws_glue_catalog_database.analytics.name
  description = "Resumen de transacciones fraudulentas por día"
  query       = <<-EOF
    SELECT 
      DATE(timestamp) as transaction_date, 
      COUNT(*) as total_transactions,
      SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) as fraud_count,
      ROUND(SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_percentage,
      SUM(CASE WHEN is_fraud THEN amount ELSE 0 END) as fraud_amount
    FROM 
      transactions
    GROUP BY 
      DATE(timestamp)
    ORDER BY 
      transaction_date DESC
  EOF
}

# Consulta para análisis de patrones de fraude
resource "aws_athena_named_query" "fraud_patterns" {
  name        = "${var.project_name}-${var.environment}-fraud-patterns"
  workgroup   = aws_athena_workgroup.main.name
  database    = aws_glue_catalog_database.analytics.name
  description = "Análisis de patrones de fraude por características"
  query       = <<-EOF
    SELECT 
      merchant,
      category,
      COUNT(*) as total_transactions,
      SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) as fraud_count,
      ROUND(SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_percentage,
      AVG(amount) as avg_amount,
      SUM(CASE WHEN is_fraud THEN amount ELSE 0 END) as total_fraud_amount
    FROM 
      transactions
    GROUP BY 
      merchant, category
    HAVING 
      COUNT(*) > 100
    ORDER BY 
      fraud_percentage DESC
  EOF
} 