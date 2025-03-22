# Variables para el proyecto de Detección de Fraude Financiero

variable "aws_region" {
  description = "La región de AWS donde se desplegarán los recursos"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "La región debe ser una región válida de AWS (ej: us-east-1, eu-west-2)."
  }
}

variable "project_name" {
  description = "El nombre del proyecto"
  type        = string
  default     = "fraud-detection"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "El nombre del proyecto solo puede contener letras minúsculas, números y guiones."
  }
}

variable "environment" {
  description = "El entorno de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El ambiente debe ser dev, staging o prod."
  }
}

# Variables de Networking
variable "vpc_cidr" {
  description = "El bloque CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_cidr))
    error_message = "El CIDR debe ser una dirección IP válida con máscara de red (ej: 10.0.0.0/16)."
  }
}

variable "public_subnet_cidrs" {
  description = "Lista de CIDR blocks para las subredes públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  
  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))])
    error_message = "Todos los CIDRs de subredes públicas deben ser direcciones IP válidas con máscara de red."
  }
}

variable "private_subnet_cidrs" {
  description = "Lista de CIDR blocks para las subredes privadas"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
  
  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))])
    error_message = "Todos los CIDRs de subredes privadas deben ser direcciones IP válidas con máscara de red."
  }
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidad en la región"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  
  validation {
    condition     = alltrue([for az in var.availability_zones : can(regex("^[a-z]{2}-[a-z]+-\\d{1}[a-z]$", az))])
    error_message = "Todas las zonas de disponibilidad deben ser válidas (ej: us-east-1a)."
  }
}

# Variables de Storage
variable "raw_bucket_suffix" {
  description = "Sufijo para el bucket de datos crudos"
  type        = string
  default     = "raw"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.raw_bucket_suffix))
    error_message = "El sufijo del bucket raw solo puede contener letras minúsculas, números y guiones."
  }
}

variable "processed_bucket_suffix" {
  description = "Sufijo para el bucket de datos procesados"
  type        = string
  default     = "processed"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.processed_bucket_suffix))
    error_message = "El sufijo del bucket processed solo puede contener letras minúsculas, números y guiones."
  }
}

variable "analytics_bucket_suffix" {
  description = "Sufijo para el bucket de analytics"
  type        = string
  default     = "analytics"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.analytics_bucket_suffix))
    error_message = "El sufijo del bucket analytics solo puede contener letras minúsculas, números y guiones."
  }
}

# Variables de Lifecycle Policies
variable "raw_transition_ia_days" {
  description = "Días antes de transicionar objetos raw a IA"
  type        = number
  default     = 90
  
  validation {
    condition     = var.raw_transition_ia_days >= 0
    error_message = "El número de días para transición a IA debe ser mayor o igual a 0."
  }
}

variable "raw_transition_glacier_days" {
  description = "Días antes de transicionar objetos raw a Glacier"
  type        = number
  default     = 180
  
  validation {
    condition     = var.raw_transition_glacier_days >= var.raw_transition_ia_days
    error_message = "El número de días para transición a Glacier debe ser mayor o igual al de transición a IA."
  }
}

variable "raw_expiration_days" {
  description = "Días antes de expirar objetos raw"
  type        = number
  default     = 365
  
  validation {
    condition     = var.raw_expiration_days >= var.raw_transition_glacier_days
    error_message = "El número de días para expiración debe ser mayor o igual al de transición a Glacier."
  }
}

# Variables de Redshift
variable "redshift_username" {
  description = "Usuario para el cluster de Redshift"
  type        = string
  sensitive   = true
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.redshift_username))
    error_message = "El nombre de usuario de Redshift debe comenzar con una letra y solo puede contener letras, números y guiones bajos."
  }
}

variable "redshift_password" {
  description = "Contraseña para el cluster de Redshift"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.redshift_password) >= 8
    error_message = "La contraseña de Redshift debe tener al menos 8 caracteres."
  }
}

variable "redshift_master_password" {
  description = "Contraseña maestra para el cluster de Redshift"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.redshift_master_password) >= 8
    error_message = "La contraseña maestra de Redshift debe tener al menos 8 caracteres."
  }
}

variable "redshift_node_type" {
  description = "Tipo de nodo para el cluster de Redshift"
  type        = string
  default     = "dc2.large"
  
  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.redshift_node_type))
    error_message = "El tipo de nodo de Redshift debe ser válido (ej: dc2.large)."
  }
}

variable "redshift_node_count" {
  description = "Número de nodos para el cluster de Redshift"
  type        = number
  default     = 1
  
  validation {
    condition     = var.redshift_node_count >= 1 && var.redshift_node_count <= 32
    error_message = "El número de nodos de Redshift debe estar entre 1 y 32."
  }
}

# Variables de Kaggle
variable "kaggle_username" {
  description = "Usuario de Kaggle para la API"
  type        = string
  sensitive   = true
  default     = "esangc"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.kaggle_username))
    error_message = "El nombre de usuario de Kaggle solo puede contener letras, números, guiones y guiones bajos."
  }
}

variable "kaggle_key" {
  description = "Key de Kaggle para la API"
  type        = string
  sensitive   = true
  default     = "52377a6aa7b7ec11e38e3f5ab6c41922"
  
  validation {
    condition     = length(var.kaggle_key) > 0
    error_message = "La key de Kaggle no puede estar vacía."
  }
}

# Variables de Monitoreo
variable "alert_email" {
  description = "Email para recibir alertas"
  type        = string
}

# Variables de Redshift
variable "redshift_cluster_type" {
  description = "Tipo de cluster de Redshift"
  type        = string
  default     = "single-node"
}

variable "redshift_number_of_nodes" {
  description = "Número de nodos para el cluster de Redshift"
  type        = number
  default     = 1
}

# Variables de etiquetas
variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {
    Project     = "fraud-detection"
    Environment = "dev"
    Terraform   = "true"
    Owner       = "data-engineering"
  }
  
  validation {
    condition     = alltrue([for key, value in var.tags : can(regex("^[a-zA-Z0-9._-]+$", key))])
    error_message = "Las claves de los tags solo pueden contener letras, números, puntos, guiones y guiones bajos."
  }
}

variable "bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
  default     = "mi-bucket-unico-123456"
}

variable "ec2_instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro"
}

variable "ec2_ami" {
  description = "AMI para instancias EC2"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 - cambiar por AMI actual
}

variable "key_name" {
  description = "Nombre del par de claves para acceso SSH"
  type        = string
  default     = "mi-clave-aws"
}

variable "glue_database_name" {
  description = "Nombre de la base de datos de AWS Glue"
  type        = string
  default     = "fraud_detection_db"
}

variable "glue_crawler_schedule" {
  description = "Expresión cron para la programación del crawler de Glue"
  type        = string
  default     = "cron(0 0 * * ? *)" # Diariamente a medianoche
}

variable "lambda_runtime" {
  description = "Runtime para las funciones Lambda"
  type        = string
  default     = "python3.9"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.lambda_runtime))
    error_message = "El runtime de Lambda debe ser válido (ej: python3.9, nodejs18.x)."
  }
}

variable "lambda_timeout" {
  description = "Tiempo de espera para las funciones Lambda (en segundos)"
  type        = number
  default     = 300
  
  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "El timeout de Lambda debe estar entre 1 y 900 segundos."
  }
}

variable "lambda_memory_size" {
  description = "Tamaño de memoria para las funciones Lambda (en MB)"
  type        = number
  default     = 512
  
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "El tamaño de memoria de Lambda debe estar entre 128 y 10240 MB."
  }
}

variable "dynamodb_billing_mode" {
  description = "Modo de facturación para la tabla DynamoDB"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "kinesis_shard_count" {
  description = "Número de shards para el stream de Kinesis"
  type        = number
  default     = 1
  
  validation {
    condition     = var.kinesis_shard_count >= 1 && var.kinesis_shard_count <= 500
    error_message = "El número de shards de Kinesis debe estar entre 1 y 500."
  }
}

variable "kinesis_retention_period" {
  description = "Período de retención para el stream de Kinesis (en horas)"
  type        = number
  default     = 24
  
  validation {
    condition     = var.kinesis_retention_period >= 24 && var.kinesis_retention_period <= 8760
    error_message = "El período de retención de Kinesis debe estar entre 24 y 8760 horas."
  }
}

# Variables para Kaggle
variable "kaggle_download_schedule" {
  description = "Expresión cron para la programación de descarga de datos de Kaggle"
  type        = string
  default     = "cron(0 0 1 * ? *)"  # Por defecto, el primer día de cada mes a medianoche
}

variable "import_existing_buckets" {
  description = "Si es true, importa buckets existentes en lugar de crearlos"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Número de días para retener los logs en CloudWatch"
  type        = number
  default     = 30
  
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3653
    error_message = "El período de retención de logs debe estar entre 1 y 3653 días."
  }
}

variable "enable_quicksight" {
  description = "Habilitar QuickSight para análisis"
  type        = bool
  default     = false
}

variable "enable_athena" {
  description = "Habilitar Athena para consultas"
  type        = bool
  default     = false
}

variable "enable_detailed_monitoring" {
  description = "Habilitar monitoreo detallado"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Habilitar encriptación para los recursos"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Habilitar endpoints de VPC"
  type        = bool
  default     = false
}

variable "storage_bucket_prefix" {
  description = "Prefijo para los buckets de almacenamiento"
  type        = string
}

variable "data_retention_days" {
  description = "Días de retención de datos"
  type        = number
  default     = 30
}

variable "batch_processing_schedule" {
  description = "Expresión cron para la programación de procesamiento por lotes"
  type        = string
  default     = "cron(0 1 ? * MON-FRI *)"  # 1 AM UTC L-V
}

variable "streaming_enabled" {
  description = "Habilitar procesamiento en tiempo real"
  type        = bool
  default     = false
}

variable "processing_timeout" {
  description = "Tiempo de espera para el procesamiento en segundos"
  type        = number
  default     = 3600
}

variable "enable_redshift" {
  description = "Habilitar Redshift para análisis"
  type        = bool
  default     = false
}

variable "github_username" {
  description = "Nombre de usuario en GitHub"
  type        = string
}

variable "cost_alert_emails" {
  description = "Lista de emails para alertas de costos"
  type        = list(string)
  default     = []
} 