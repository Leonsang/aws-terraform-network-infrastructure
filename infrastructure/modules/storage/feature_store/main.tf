locals {
  feature_group_name = "${var.project_name}-${var.environment}-fraud-features"
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
    Component   = "feature-store"
  }
}

# Bucket S3 para el Feature Store offline
resource "aws_s3_bucket" "feature_store" {
  bucket = "${var.project_name}-${var.environment}-feature-store"
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "feature_store" {
  bucket = aws_s3_bucket.feature_store.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "feature_store" {
  bucket = aws_s3_bucket.feature_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM Role para SageMaker Feature Store
resource "aws_iam_role" "feature_store" {
  name = "${var.project_name}-${var.environment}-feature-store-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# Política para acceso al bucket S3
resource "aws_iam_role_policy" "feature_store_s3" {
  name = "feature-store-s3-access"
  role = aws_iam_role.feature_store.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.feature_store.arn,
          "${aws_s3_bucket.feature_store.arn}/*"
        ]
      }
    ]
  })
}

# Política para Feature Store
resource "aws_iam_role_policy" "feature_store_permissions" {
  name = "feature-store-permissions"
  role = aws_iam_role.feature_store.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateFeatureGroup",
          "sagemaker:DeleteFeatureGroup",
          "sagemaker:DescribeFeatureGroup",
          "sagemaker:UpdateFeatureGroup"
        ]
        Resource = "arn:aws:sagemaker:${var.aws_region}:${data.aws_caller_identity.current.account_id}:feature-group/${local.feature_group_name}"
      }
    ]
  })
}

# Data source para obtener el ID de la cuenta actual
data "aws_caller_identity" "current" {}

# Outputs
output "feature_store_bucket" {
  description = "El bucket S3 para el Feature Store"
  value = {
    id   = aws_s3_bucket.feature_store.id
    arn  = aws_s3_bucket.feature_store.arn
    name = aws_s3_bucket.feature_store.bucket
  }
}

output "feature_store_role" {
  description = "El rol IAM para el Feature Store"
  value = {
    id   = aws_iam_role.feature_store.id
    arn  = aws_iam_role.feature_store.arn
    name = aws_iam_role.feature_store.name
  }
} 