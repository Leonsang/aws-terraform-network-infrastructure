terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Data sources para validación
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Validación de región
locals {
  validate_region = data.aws_region.current.name == var.aws_region ? true : tobool("La región especificada no coincide con la región actual de AWS")
  aws_region = "us-east-1"
  tags = {
    Environment = "dev"
    Project     = "terraform-aws"
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
  }
}

# Módulo de Networking
module "networking" {
  source = "../../modules/networking"

  environment = "dev"
  project_name = "terraform-aws"
  aws_region = local.aws_region
  vpc_cidr = "10.0.0.0/16"
  tags = local.tags

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  enable_flow_logs   = true

  depends_on = [local.validate_region]
}

# Módulo de Storage
module "storage" {
  source = "../../modules/storage"

  environment = "dev"
  project_name = "terraform-aws"
  aws_region = local.aws_region
  tags = local.tags

  enable_versioning = true
  enable_encryption = true
}

# Módulo de Procesamiento
module "processing" {
  source = "../../modules/processing"

  environment = "dev"
  project_name = "terraform-aws"
  aws_region = local.aws_region
  vpc_id = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  tags = local.tags

  # Buckets
  raw_bucket_arn          = module.storage.s3_bucket_arn
  raw_bucket_name         = module.storage.s3_bucket_id
  processed_bucket_name   = "${var.project_name}-${var.environment}-processed"
  processed_bucket_arn    = "arn:aws:s3:::${var.project_name}-${var.environment}-processed"
  feature_store_bucket_name = "${var.project_name}-${var.environment}-feature-store"
  feature_store_bucket_arn  = "arn:aws:s3:::${var.project_name}-${var.environment}-feature-store"
  scripts_bucket          = "${var.project_name}-${var.environment}-scripts"

  # Seguridad
  security_group_ids     = [module.networking.default_security_group_id]
  kms_key_arn           = module.security.kms_key_arn
  lambda_role_arn       = module.security.lambda_role_arn
  glue_role_arn         = module.security.glue_role_arn

  # Data Sources
  kaggle_layer_arn      = module.data_ingestion.lambda_layer_arn
  raw_data_path         = "raw/kaggle/"

  # Lambda
  lambda_runtime         = var.lambda_runtime
  lambda_timeout         = var.lambda_timeout
  lambda_memory_size     = var.lambda_memory_size

  # SNS
  sns_topic_arn         = module.monitoring.sns_topic_arn

  # Glue Configuration
  glue_version       = var.glue_config.version
  glue_python_version = var.glue_config.python_version
  worker_type        = var.glue_config.worker_type
  number_of_workers  = var.glue_config.workers_count

  glue_jobs = {
    data_overview = {
      script_path         = "glue/data_overview.py"
      max_concurrent_runs = 1
      max_retries        = 2
      timeout_minutes    = var.glue_config.timeout_minutes
      arguments = {
        "--input_path"    = "s3://${var.project_name}-${var.environment}-raw/raw/kaggle/"
        "--output_path"   = "s3://${var.project_name}-${var.environment}-processed/data_overview/"
        "--environment"   = "development"
      }
    }
    feature_engineering = {
      script_path         = "glue/feature_engineering.py"
      max_concurrent_runs = 1
      max_retries        = 2
      timeout_minutes    = var.glue_config.timeout_minutes
      arguments = {
        "--input_path"    = "s3://${var.project_name}-${var.environment}-processed/data_overview/"
        "--output_path"   = "s3://${var.project_name}-${var.environment}-feature-store/"
        "--environment"   = "development"
      }
    }
  }

  default_arguments = {
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--enable-spark-ui"                 = "true"
    "--spark-event-logs-path"          = "s3://${var.project_name}-${var.environment}-scripts/spark-logs"
    "--enable-job-insights"            = "true"
    "--job-bookmark-option"           = "job-bookmark-enable"
    "--TempDir"                       = "s3://${var.project_name}-${var.environment}-scripts/temporary"
    "--extra-py-files"               = "s3://${var.project_name}-${var.environment}-scripts/dependencies/fraud_detection_utils.zip"
  }

  depends_on = [module.networking, module.storage, module.security, module.data_ingestion]
}

# Módulo de Analytics
module "analytics" {
  source = "../../modules/analytics"

  project_name    = var.project_name
  environment     = var.environment
  region         = var.aws_region
  tags           = var.tags

  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.private_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_ids = [module.networking.default_security_group_id]

  processed_bucket_name = "${var.project_name}-${var.environment}-processed"
  analytics_bucket_name = "${var.project_name}-${var.environment}-analytics"

  redshift_username       = "admin"
  redshift_password      = var.redshift_master_password
  redshift_master_username = "admin"
  redshift_master_password = var.redshift_master_password
  redshift_node_type      = var.redshift_node_type
  redshift_node_count     = 1

  glue_role_arn      = module.security.glue_role_arn
  redshift_role_arn  = module.security.redshift_role_arn
  glue_job_names     = []
  glue_database_name = "${var.project_name}-${var.environment}-analytics"

  depends_on = [module.networking, module.storage, module.processing, module.security]
}

# Módulo de Monitoreo
module "monitoring" {
  source = "../../modules/monitoring"

  environment = "dev"
  project_name = "terraform-aws"
  aws_region = local.aws_region
  tags = local.tags

  # Bucket de monitoreo
  monitoring_bucket_name = module.storage.metrics_bucket_name
  monitoring_bucket_arn  = module.storage.metrics_bucket_arn

  # Configuración de retención
  log_retention_days     = var.log_retention_days
  metrics_retention_days = 90
  metrics_transition_days = 30

  # Umbrales de alertas
  lambda_error_threshold = 5
  api_latency_threshold  = 1000
  drift_threshold        = 0.3

  # Acciones de alarma
  alarm_actions = []

  depends_on = [
    module.storage
  ]
}

# Módulo de Backup
/*
module "dr_backup" {
  source = "../../modules/dr_backup"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.security.kms_key_arn
  tags         = var.tags

  depends_on = [
    module.security
  ]
}

module "backup" {
  source = "../../modules/backup"

  project_name        = var.project_name
  environment        = var.environment
  aws_region        = var.aws_region
  kms_key_arn       = module.security.kms_key_arn
  dr_vault_arn      = module.dr_backup.vault_arn
  notification_emails = ["admin@example.com"]  # Reemplazar con emails reales
  tags              = var.tags

  backup_resources = [
    module.storage.raw_bucket_arn,
    module.storage.processed_bucket_arn,
    module.storage.analytics_bucket_arn
  ]

  providers = {
    aws.dr_region = aws.dr_region
  }

  depends_on = [
    module.security,
    module.storage,
    module.dr_backup
  ]
}
*/

# Módulo de KMS
module "kms" {
  source = "../../modules/kms"

  project_name = "terraform-aws"
  environment  = "dev"
  tags         = local.tags
}

# Módulo de Logging
module "logging" {
  source = "../../modules/logging"

  project_name = "terraform-aws"
  environment  = "dev"
  region       = var.aws_region
  kms_key_arn  = module.security.kms_key_arn
  tags         = local.tags

  # Configuración de retención y buffer
  log_retention_days      = 7
  firehose_buffer_size    = 1
  firehose_buffer_interval = 60

  # Integración con otros módulos
  logs_bucket_arn = module.storage.logs_bucket_arn
  alarm_actions   = [module.monitoring.alert_topic_arn]
  alert_email     = var.alert_email

  # Grupos de logs a monitorear
  log_groups_to_monitor = [
    module.data_ingestion.log_group_name,
    module.processing.log_group_name,
    module.analytics.log_group_name
  ]

  depends_on = [
    module.storage,
    module.security,
    module.monitoring,
    module.data_ingestion,
    module.processing,
    module.analytics
  ]
}

# Módulo de CI/CD (temporalmente comentado)
# module "cicd" {
#   source = "../../modules/cicd"

#   project_name = var.project_name
#   environment  = var.environment
#   region      = var.aws_region

#   # CodeDeploy
#   ecs_cluster_name = module.processing.ecs_cluster_name
#   ecs_service_name = module.processing.ecs_service_name
#   test_listener_arn = module.networking.test_listener_arn

#   tags = var.tags
# }

# Módulo de Costos
/*
module "costs" {
  source = "../../modules/costs"

  environment = "dev"
  project_name = "terraform-aws"
  email = "devops@example.com"
}
*/

# Módulo de Compliance
module "compliance" {
  source = "../../modules/compliance"

  project_name = var.project_name
  environment  = "dev"
  region       = var.aws_region
  tags         = var.tags

  # Argumentos requeridos que faltaban
  account_id              = data.aws_caller_identity.current.account_id
  compliance_alert_emails = [var.alert_email]

  # Configuración de encriptación y notificaciones
  kms_key_arn           = module.security.kms_key_arn
  notification_topic_arn = module.monitoring.alert_topic_arn

  # Configuración de GuardDuty para desarrollo
  guardduty_frequency = "ONE_HOUR"
  enable_guardduty    = true

  # Configuración de Security Hub para desarrollo
  enable_security_hub = true
  security_standards = [
    "CIS AWS Foundations Benchmark v1.4.0"
  ]

  # Configuración de AWS Config
  config_rules = [
    "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED",
    "S3_BUCKET_VERSIONING_ENABLED",
    "RDS_STORAGE_ENCRYPTED"
  ]
  enable_config_aggregator = false

  # Configuración de Audit Manager
  enable_audit_manager = true
  audit_assessment_reports_destination = "S3"

  # Configuración de monitoreo y remediación
  enable_continuous_monitoring = true
  enable_automated_remediation = false
  compliance_notification_frequency = 30
  remediation_concurrent_executions = 5

  # Configuración de exportación de hallazgos
  enable_findings_export = true

  depends_on = [
    module.security,
    module.monitoring,
    module.storage
  ]
}

# Módulo de Testing
module "testing" {
  source = "../../modules/testing"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  region       = var.aws_region
  tags         = var.tags

  # Argumentos requeridos que faltaban
  account_id              = data.aws_caller_identity.current.account_id
  api_gateway_url         = module.api.api_gateway_url
  sagemaker_endpoint_name = "temporary-endpoint"  # Valor temporal
  sagemaker_endpoint_arn  = "arn:aws:sagemaker:${var.aws_region}:${data.aws_caller_identity.current.account_id}:endpoint/temporary-endpoint"  # Valor temporal
  test_data_location     = "s3://${module.storage.processed_bucket_name}/test-data"
  notification_topic_arn  = module.monitoring.alert_topic_arn

  # Configuración de red
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids

  # Configuración de seguridad
  kms_key_arn = module.security.kms_key_arn

  # Configuración del repositorio
  repository_url = "https://github.com/${var.github_username}/${var.project_name}"

  # Configuración de pruebas para desarrollo
  test_schedule = "cron(0 1 ? * MON-FRI *)"  # 1 AM UTC de lunes a viernes
  test_compute_type = "BUILD_GENERAL1_SMALL"
  test_timeout = 15
  test_parallelization = 1
  test_retry_count = 1
  test_reports_retention_days = 7
  test_failure_threshold = 20
  test_coverage_threshold = 70

  # Notificaciones
  test_notification_emails = [var.alert_email]
  test_notification_frequency = "ON_FAILURE"

  # Tipos de pruebas habilitados para desarrollo
  enable_vulnerability_scanning = true
  enable_static_analysis = true
  enable_integration_tests = true
  enable_load_tests = false
  enable_security_tests = true
  enable_performance_tests = false

  # Variables de entorno para pruebas
  test_environment_variables = {
    ENVIRONMENT = "dev"
    LOG_LEVEL  = "DEBUG"
  }

  depends_on = [
    module.networking,
    module.security,
    module.monitoring
  ]
}

# Módulo de Documentación
module "documentation" {
  source = "../../modules/documentation"

  project_name = "terraform-aws"
  environment  = "dev"
  region       = local.aws_region
  tags         = local.tags

  # Configuración de documentación
  docs_compute_type        = "BUILD_GENERAL1_SMALL"
  docs_update_schedule     = "rate(1 day)"
  docs_notification_emails = ["admin@example.com"]
  repository_url          = "https://github.com/yourusername/terraform-aws"

  # KMS
  kms_key_arn = module.security.kms_key_arn

  depends_on = [
    module.security
  ]
}

# Módulo de API
module "api" {
  source = "../../modules/api"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  region       = var.aws_region
  tags         = var.tags

  # Configuración de seguridad
  kms_key_arn = module.security.kms_key_arn

  # Configuración del endpoint
  endpoint_name         = "temporary-endpoint"  # Valor temporal
  sagemaker_endpoint_arn = "arn:aws:sagemaker:${var.aws_region}:${data.aws_caller_identity.current.account_id}:endpoint/temporary-endpoint"  # Valor temporal

  # Configuración del modelo
  model_bucket     = module.storage.model_bucket_name
  model_bucket_arn = module.storage.model_bucket_arn
  model_key        = "models/fraud_detection_model.pkl"

  # Configuración de recursos
  lambda_memory = 1024
  lambda_timeout = 30

  # Configuración de logging
  log_level = "DEBUG"
  log_retention_days = 7

  # Límites y cuotas
  rate_limit = 1000
  quota_limit = 5000
  quota_period = "MONTH"
  throttle_burst_limit = 50
  throttle_rate_limit = 25
  error_threshold = 5

  # Notificaciones
  alarm_actions = [module.monitoring.alert_topic_arn]

  # Configuración de características
  enable_xray = true
  enable_caching = false
  enable_compression = true
  enable_cors = true
  enable_waf_logging = true
  enable_request_validation = true
  enable_response_validation = true
  enable_api_key = true
  enable_usage_plans = true

  # CORS
  allowed_origins = ["*"]
  allowed_methods = ["GET", "POST", "OPTIONS"]
  allowed_headers = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key"]

  depends_on = [
    module.security,
    module.storage,
    module.monitoring
  ]
}

# Módulo de Security
module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id
  tags         = var.tags

  # Configuración de alertas
  security_alert_emails = [var.alert_email]
  alarm_actions = [module.monitoring.alert_topic_arn]

  # Configuración de WAF
  waf_rate_limit = 2000
  blocked_ips = []
  waf_blocked_requests_threshold = 100

  # Configuración de Security Hub
  enable_security_hub = true
  security_findings_threshold = 10

  # Configuración de contraseñas
  minimum_password_length = 14
  max_password_age = 90
  password_reuse_prevention = 24

  # Configuración de Organizations
  create_organization = false
  additional_scp_statements = []

  # Configuración de AWS Config
  force_destroy_bucket = false

  depends_on = [module.monitoring]
}

# Módulo de Data Ingestion
module "data_ingestion" {
  source = "../../modules/data_ingestion"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id
  tags         = var.tags

  # Credenciales de Kaggle
  kaggle_username = var.kaggle_username
  kaggle_key      = var.kaggle_key

  # Configuración de almacenamiento
  raw_bucket_name = module.storage.raw_bucket_name

  # Configuración de programación
  download_schedule = var.batch_processing_schedule

  # Configuración de logs
  log_retention_days = var.log_retention_days

  # Configuración de alertas
  alert_email = var.alert_email

  depends_on = [
    module.security,
    module.storage,
    module.monitoring
  ]
}

# Módulo de Glue
module "glue" {
  source = "../../modules/glue"

  project_name     = var.project_name
  environment      = var.environment
  scripts_bucket_id = module.storage.scripts_bucket_id
  data_bucket_id   = module.storage.data_bucket_id

  glue_version       = var.glue_config.version
  glue_python_version = var.glue_config.python_version
  worker_type        = var.glue_config.worker_type
  number_of_workers  = var.glue_config.workers_count
  job_timeout        = var.glue_config.timeout_minutes

  default_arguments = {
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--enable-spark-ui"                 = "true"
    "--spark-event-logs-path"          = "s3://${module.storage.scripts_bucket_id}/spark-logs"
    "--enable-job-insights"            = "true"
    "--job-bookmark-option"           = "job-bookmark-enable"
    "--TempDir"                       = "s3://${module.storage.scripts_bucket_id}/temporary"
    "--extra-py-files"               = "s3://${module.storage.scripts_bucket_id}/dependencies/fraud_detection_utils.zip"
    "--environment"                  = "development"
  }

  alarm_actions = [module.monitoring.alert_topic_arn]
  tags         = local.tags

  depends_on = [
    module.storage,
    module.monitoring
  ]
}
