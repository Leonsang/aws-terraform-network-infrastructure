# Outputs del módulo de almacenamiento

# Outputs para el bucket raw
output "raw_bucket_name" {
  description = "Nombre del bucket raw"
  value       = aws_s3_bucket.raw.id
}

output "raw_bucket_arn" {
  description = "ARN del bucket raw"
  value       = aws_s3_bucket.raw.arn
}

# Outputs para el bucket processed
output "processed_bucket_name" {
  description = "Nombre del bucket processed"
  value       = aws_s3_bucket.processed.id
}

output "processed_bucket_arn" {
  description = "ARN del bucket processed"
  value       = aws_s3_bucket.processed.arn
}

# Outputs para el bucket analytics
output "analytics_bucket_name" {
  description = "Nombre del bucket analytics"
  value       = aws_s3_bucket.analytics.id
}

output "analytics_bucket_arn" {
  description = "ARN del bucket analytics"
  value       = aws_s3_bucket.analytics.arn
}

# Outputs para el backend de Terraform
output "terraform_state_bucket_name" {
  description = "Nombre del bucket para el estado de Terraform"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_bucket_arn" {
  description = "ARN del bucket para el estado de Terraform"
  value       = aws_s3_bucket.terraform_state.arn
}

output "terraform_state_lock_table_name" {
  description = "Nombre de la tabla DynamoDB para el bloqueo de estado"
  value       = aws_dynamodb_table.terraform_state_lock.id
}

output "terraform_state_lock_table_arn" {
  description = "ARN de la tabla DynamoDB para el bloqueo de estado"
  value       = aws_dynamodb_table.terraform_state_lock.arn
} 