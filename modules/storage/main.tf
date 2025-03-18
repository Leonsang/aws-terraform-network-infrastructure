# Módulo de almacenamiento para el proyecto de Detección de Fraude Financiero
# Implementa los buckets S3 para las tres zonas de datos: Raw, Processed y Analytics

# Data sources para verificar si los buckets existen
data "aws_s3_bucket" "raw_existing" {
  count  = var.import_existing_buckets ? 1 : 0
  bucket = lower(local.raw_bucket_name)
}

data "aws_s3_bucket" "processed_existing" {
  count  = var.import_existing_buckets ? 1 : 0
  bucket = lower(local.processed_bucket_name)
}

data "aws_s3_bucket" "analytics_existing" {
  count  = var.import_existing_buckets ? 1 : 0
  bucket = lower(local.analytics_bucket_name)
}

locals {
  raw_bucket_name       = "${var.project_name}-${var.environment}-${var.raw_bucket_suffix}"
  processed_bucket_name = "${var.project_name}-${var.environment}-${var.processed_bucket_suffix}"
  analytics_bucket_name = "${var.project_name}-${var.environment}-${var.analytics_bucket_suffix}"
  terraform_state_bucket_name = "${var.project_name}-${var.environment}-terraform-state"
  terraform_state_lock_table_name = "${var.project_name}-${var.environment}-terraform-lock"
  
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  })

  # Verificar si los buckets existen
  raw_bucket_exists       = can(data.aws_s3_bucket.raw_existing)
  processed_bucket_exists = can(data.aws_s3_bucket.processed_existing)
  analytics_bucket_exists = can(data.aws_s3_bucket.analytics_existing)
}

# Bucket S3 para el estado de Terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.terraform_state_bucket_name
  force_destroy = false

  tags = merge(local.common_tags, {
    Name = local.terraform_state_bucket_name
    Purpose = "Terraform State Storage"
  })
}

# Configuración de cifrado para el bucket de estado
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Bloquear acceso público para el bucket de estado
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Habilitar versionamiento para el bucket de estado
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Tabla DynamoDB para el state lock
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = local.terraform_state_lock_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.common_tags, {
    Name = local.terraform_state_lock_table_name
    Purpose = "Terraform State Locking"
  })
}

# Bucket S3 para la zona raw
resource "aws_s3_bucket" "raw" {
  bucket = lower(local.raw_bucket_name)
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, {
    Name = local.raw_bucket_name
    Zone = "raw"
  })
}

# Bucket S3 para la zona processed
resource "aws_s3_bucket" "processed" {
  bucket = lower(local.processed_bucket_name)
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, {
    Name = local.processed_bucket_name
    Zone = "processed"
  })
}

# Bucket S3 para la zona analytics
resource "aws_s3_bucket" "analytics" {
  bucket = lower(local.analytics_bucket_name)
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, {
    Name = local.analytics_bucket_name
    Zone = "analytics"
  })
}

# Configuración de cifrado para los buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Bloquear acceso público para todos los buckets
resource "aws_s3_bucket_public_access_block" "raw" {
  bucket = aws_s3_bucket.raw.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "processed" {
  bucket = aws_s3_bucket.processed.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Habilitar versionamiento para todos los buckets
resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "processed" {
  bucket = aws_s3_bucket.processed.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "analytics" {
  bucket = aws_s3_bucket.analytics.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Política de ciclo de vida para el bucket Raw
resource "aws_s3_bucket_lifecycle_configuration" "raw_lifecycle" {
  bucket = aws_s3_bucket.raw.id

  rule {
    id     = "raw-lifecycle-rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.raw_transition_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.raw_transition_glacier_days
      storage_class = "GLACIER"
    }

    transition {
      days          = var.raw_expiration_days
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = var.raw_deep_archive_days
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 180
      storage_class   = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "DEEP_ARCHIVE"
    }

    noncurrent_version_expiration {
      noncurrent_days = 730
    }
  }
}

# Política de ciclo de vida para el bucket Processed
resource "aws_s3_bucket_lifecycle_configuration" "processed_lifecycle" {
  bucket = aws_s3_bucket.processed.id

  rule {
    id     = "processed-lifecycle-rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.processed_transition_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.processed_transition_glacier_days
      storage_class = "GLACIER"
    }

    transition {
      days          = var.processed_expiration_days
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = var.processed_deep_archive_days
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 180
      storage_class   = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "DEEP_ARCHIVE"
    }

    noncurrent_version_expiration {
      noncurrent_days = 730
    }
  }
}

# Política de ciclo de vida para el bucket Analytics
resource "aws_s3_bucket_lifecycle_configuration" "analytics_lifecycle" {
  bucket = aws_s3_bucket.analytics.id

  rule {
    id     = "analytics-lifecycle-rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.analytics_transition_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.analytics_transition_glacier_days
      storage_class = "GLACIER"
    }

    transition {
      days          = var.analytics_expiration_days
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = var.analytics_deep_archive_days
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 180
      storage_class   = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "DEEP_ARCHIVE"
    }

    noncurrent_version_expiration {
      noncurrent_days = 730
    }
  }
}

# Políticas de bucket para control de acceso
resource "aws_s3_bucket_policy" "raw" {
  bucket = aws_s3_bucket.raw.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.raw.arn,
          "${aws_s3_bucket.raw.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "EnforceKMSEncryption"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.raw.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption": "aws:kms"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "processed" {
  bucket = aws_s3_bucket.processed.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.processed.arn,
          "${aws_s3_bucket.processed.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "EnforceKMSEncryption"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.processed.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption": "aws:kms"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.analytics.arn,
          "${aws_s3_bucket.analytics.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "EnforceKMSEncryption"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.analytics.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption": "aws:kms"
          }
        }
      }
    ]
  })
}

# Habilitar transferencia acelerada para buckets que lo necesiten
resource "aws_s3_bucket_accelerate_configuration" "analytics" {
  bucket = aws_s3_bucket.analytics.id
  status = "Enabled"
}

# Habilitar logging de acceso para todos los buckets
resource "aws_s3_bucket_logging" "raw" {
  bucket = aws_s3_bucket.raw.id
  target_bucket = aws_s3_bucket.analytics.id
  target_prefix = "logs/raw/"
}

resource "aws_s3_bucket_logging" "processed" {
  bucket = aws_s3_bucket.processed.id
  target_bucket = aws_s3_bucket.analytics.id
  target_prefix = "logs/processed/"
}

resource "aws_s3_bucket_logging" "analytics" {
  bucket = aws_s3_bucket.analytics.id
  target_bucket = aws_s3_bucket.analytics.id
  target_prefix = "logs/analytics/"
} 