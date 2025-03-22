output "raw_bucket_arn" {
  description = "ARN del bucket raw"
  value       = aws_s3_bucket.raw.arn
}

output "raw_bucket_id" {
  description = "ID del bucket raw"
  value       = aws_s3_bucket.raw.id
}

output "processed_bucket_arn" {
  description = "ARN del bucket processed"
  value       = aws_s3_bucket.processed.arn
}

output "processed_bucket_id" {
  description = "ID del bucket processed"
  value       = aws_s3_bucket.processed.id
} 