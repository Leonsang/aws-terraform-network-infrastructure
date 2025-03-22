output "kms_key_id" {
  description = "The ID of the KMS key"
  value       = aws_kms_key.this.id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key"
  value       = aws_kms_key.this.arn
}

output "kms_alias_name" {
  description = "The name of the KMS alias"
  value       = aws_kms_alias.this.name
} 