locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
  }

  raw_bucket_name       = "${var.project_name}-${var.environment}-raw"
  processed_bucket_name = "${var.project_name}-${var.environment}-processed"
  analytics_bucket_name = "${var.project_name}-${var.environment}-analytics"
  scripts_bucket_name   = "${var.project_name}-${var.environment}-scripts-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Bucket para la zona Raw (Bronze)
resource "aws_s3_bucket" "raw" {
  bucket = local.raw_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id

  rule {
    id     = "lifecycle_rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.transition_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration_days
    }
  }
}

# Bucket para la zona Processed (Silver)
resource "aws_s3_bucket" "processed" {
  bucket = local.processed_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "processed" {
  bucket = aws_s3_bucket.processed.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id

  rule {
    id     = "lifecycle_rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.transition_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration_days
    }
  }
}

# Bucket para la zona Analytics (Gold)
resource "aws_s3_bucket" "analytics" {
  bucket = local.analytics_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "analytics" {
  bucket = aws_s3_bucket.analytics.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket para scripts
resource "aws_s3_bucket" "scripts" {
  bucket = local.scripts_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "scripts" {
  bucket = aws_s3_bucket.scripts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Políticas de cifrado para todos los buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scripts" {
  bucket = aws_s3_bucket.scripts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Outputs
output "raw_bucket" {
  description = "El bucket S3 para datos raw"
  value = {
    id   = aws_s3_bucket.raw.id
    arn  = aws_s3_bucket.raw.arn
    name = aws_s3_bucket.raw.bucket
  }
}

output "processed_bucket" {
  description = "El bucket S3 para datos procesados"
  value = {
    id   = aws_s3_bucket.processed.id
    arn  = aws_s3_bucket.processed.arn
    name = aws_s3_bucket.processed.bucket
  }
}

output "analytics_bucket" {
  description = "El bucket S3 para datos analíticos"
  value = {
    id   = aws_s3_bucket.analytics.id
    arn  = aws_s3_bucket.analytics.arn
    name = aws_s3_bucket.analytics.bucket
  }
}

output "scripts_bucket" {
  description = "El bucket S3 para scripts"
  value = {
    id   = aws_s3_bucket.scripts.id
    arn  = aws_s3_bucket.scripts.arn
    name = aws_s3_bucket.scripts.bucket
  }
} 