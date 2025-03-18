# Bucket S3 para el estado de Terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = "fraud-detection-dev-terraform-state"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project     = "fraud-detection"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "data-engineering-team"
    Purpose     = "Terraform State Storage"
  }
}

# Habilitar versionamiento en el bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Habilitar cifrado por defecto
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquear acceso público al bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Tabla DynamoDB para el state lock
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "fraud-detection-dev-terraform-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project     = "fraud-detection"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "data-engineering-team"
    Purpose     = "Terraform State Locking"
  }
} 