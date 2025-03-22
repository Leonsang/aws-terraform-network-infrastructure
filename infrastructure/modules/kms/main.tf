resource "aws_kms_key" "this" {
  description             = "KMS key for ${var.project_name} in ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-kms-key"
    }
  )
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.this.key_id
} 