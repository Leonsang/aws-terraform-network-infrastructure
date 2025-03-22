terraform {
  required_version = ">= 1.0.0"
}

resource "aws_backup_vault" "dr_vault" {
  name        = "${var.project_name}-${var.environment}-dr-vault"
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

output "vault_arn" {
  description = "ARN del vault de DR"
  value       = aws_backup_vault.dr_vault.arn
} 