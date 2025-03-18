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

  backend "s3" {
    bucket         = "fraud-detection-dev-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "fraud-detection-dev-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      var.tags,
      {
        Environment = var.environment
        ManagedBy   = "Terraform"
        Project     = var.project_name
        CostCenter  = "FraudDetection"
        Owner       = "DevOps"
      }
    )
  }
}

# Data sources para validación
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Validación de región
locals {
  validate_region = data.aws_region.current.name == var.region ? true : tobool("La región especificada no coincide con la región actual de AWS")
}

# Módulo de Networking
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  tags         = var.tags

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones

  depends_on = [local.validate_region]
}

# Módulo de Storage
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
  region      = var.region
  tags        = var.tags

  import_existing_buckets = var.import_existing_buckets

  raw_bucket_suffix       = var.raw_bucket_suffix
  processed_bucket_suffix = var.processed_bucket_suffix
  analytics_bucket_suffix = var.analytics_bucket_suffix

  raw_transition_ia_days       = var.raw_transition_ia_days
  raw_transition_glacier_days  = var.raw_transition_glacier_days
  raw_expiration_days         = var.raw_expiration_days

  processed_transition_ia_days      = var.processed_transition_ia_days
  processed_transition_glacier_days = var.processed_transition_glacier_days
  processed_expiration_days        = var.processed_expiration_days

  depends_on = [module.networking]
}

# Módulo de Seguridad
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = module.networking.vpc_cidr
  subnet_ids   = module.networking.private_subnet_ids
  
  # Buckets ARNs
  raw_bucket_arn  = module.storage.raw_bucket_arn
  proc_bucket_arn = module.storage.processed_bucket_arn
  analy_bucket_arn = module.storage.analytics_bucket_arn
  
  # Backend ARNs
  terraform_state_bucket_arn = module.storage.terraform_state_bucket_arn
  terraform_state_lock_table_arn = module.storage.terraform_state_lock_table_arn
  
  tags = var.tags

  depends_on = [module.networking, module.storage]
}

# Módulo de Data Ingestion
module "data_ingestion" {
  source = "./modules/data_ingestion"

  project_name = var.project_name
  environment  = var.environment
  region      = var.region
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.private_subnet_ids

  # Buckets
  raw_bucket_name = module.storage.raw_bucket_name
  raw_bucket_arn  = module.storage.raw_bucket_arn

  # Kaggle Configuration
  kaggle_username = var.kaggle_username
  kaggle_key      = var.kaggle_key

  # IAM Roles
  lambda_role_arn = module.security.lambda_role_arn

  tags = var.tags

  depends_on = [module.networking, module.storage, module.security]
}

# Módulo de Procesamiento
module "processing" {
  source = "./modules/processing"

  project_name = var.project_name
  environment  = var.environment
  region      = var.region
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.private_subnet_ids
  tags        = var.tags

  # Buckets
  raw_bucket_name  = module.storage.raw_bucket_name
  proc_bucket_name = module.storage.processed_bucket_name
  analy_bucket_name = module.storage.analytics_bucket_name

  # Data Sources
  kaggle_layer_arn = module.data_ingestion.kaggle_layer_arn
  raw_data_path    = module.data_ingestion.raw_data_path

  # IAM Roles
  glue_role_arn = module.security.glue_role_arn
  lambda_role_arn = module.security.lambda_role_arn

  # Kinesis Configuration
  kinesis_shard_count = var.kinesis_shard_count
  kinesis_retention_period = var.kinesis_retention_period

  # Lambda Configuration
  lambda_runtime = var.lambda_runtime
  lambda_timeout = var.lambda_timeout
  lambda_memory_size = var.lambda_memory_size

  depends_on = [module.networking, module.storage, module.security, module.data_ingestion]
}

# Módulo de Analytics
module "analytics" {
  source = "./modules/analytics"

  project_name = var.project_name
  environment  = var.environment
  region      = var.region
  vpc_id       = module.networking.vpc_id
  subnet_ids   = module.networking.private_subnet_ids
  tags         = var.tags

  # Buckets
  processed_bucket_name = module.storage.processed_bucket_name
  analytics_bucket_name = module.storage.analytics_bucket_name
  
  # Redshift Configuration
  redshift_username    = var.redshift_username
  redshift_password    = var.redshift_password
  redshift_node_type   = var.redshift_node_type
  redshift_node_count  = var.redshift_node_count
  
  # IAM Roles
  glue_role_arn       = module.security.glue_role_arn
  redshift_role_arn   = module.security.redshift_role_arn

  # Processing Dependencies
  glue_job_names     = module.processing.glue_job_names
  glue_database_name = module.processing.glue_database_name

  depends_on = [module.networking, module.storage, module.security, module.processing]
}

# Módulo de Monitoreo
module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  region      = var.region
  tags        = var.tags
  alert_email  = var.alert_email

  # VPC Info
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids

  # Resources to Monitor
  raw_bucket_name        = module.storage.raw_bucket_name
  processed_bucket_name  = module.storage.processed_bucket_name
  analytics_bucket_name  = module.storage.analytics_bucket_name
  glue_job_names        = module.processing.glue_job_names
  lambda_function_names = [
    module.data_ingestion.kaggle_downloader_function_name,
    module.processing.lambda_function_names
  ]
  redshift_cluster_id   = module.analytics.redshift_cluster_id

  # Additional Monitoring
  kaggle_download_status = module.data_ingestion.kaggle_download_status
  glue_database_name    = module.processing.glue_database_name
  glue_crawler_names    = module.processing.glue_crawler_names

  # Log Retention
  log_retention_days = var.log_retention_days

  depends_on = [
    module.networking,
    module.storage,
    module.security,
    module.data_ingestion,
    module.processing,
    module.analytics
  ]
}
