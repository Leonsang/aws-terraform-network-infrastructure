variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS donde se desplegará el Feature Store"
  type        = string
}

variable "feature_definitions" {
  description = "Definiciones de features para el Feature Store"
  type = list(object({
    feature_name = string
    feature_type = string
  }))
  default = [
    {
      feature_name = "transaction_id"
      feature_type = "String"
    },
    {
      feature_name = "amount"
      feature_type = "Fractional"
    },
    {
      feature_name = "timestamp"
      feature_type = "Integral"
    },
    {
      feature_name = "is_fraud"
      feature_type = "Integral"
    }
  ]
}

variable "offline_store_config" {
  description = "Configuración para el almacenamiento offline del Feature Store"
  type = object({
    disable_glue_table_creation = bool
    data_catalog_config = object({
      table_name        = string
      database_name     = string
      catalog_role_arn  = string
    })
  })
  default = {
    disable_glue_table_creation = false
    data_catalog_config = {
      table_name       = "fraud_features"
      database_name    = "feature_store"
      catalog_role_arn = null
    }
  }
}

variable "online_store_config" {
  description = "Configuración para el almacenamiento online del Feature Store"
  type = object({
    enable_online_store = bool
    security_config = object({
      kms_key_id = string
    })
  })
  default = {
    enable_online_store = true
    security_config = {
      kms_key_id = null
    }
  }
} 