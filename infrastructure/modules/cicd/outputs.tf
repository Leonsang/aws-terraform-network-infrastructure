output "pipeline_arn" {
  description = "ARN del pipeline de CI/CD"
  value       = aws_codepipeline.pipeline.arn
}

output "pipeline_name" {
  description = "Nombre del pipeline de CI/CD"
  value       = aws_codepipeline.pipeline.name
}

output "artifacts_bucket_name" {
  description = "Nombre del bucket S3 para artefactos"
  value       = aws_s3_bucket.artifacts.id
}

output "artifacts_bucket_arn" {
  description = "ARN del bucket S3 para artefactos"
  value       = aws_s3_bucket.artifacts.arn
}

output "codebuild_test_project_name" {
  description = "Nombre del proyecto CodeBuild para pruebas"
  value       = aws_codebuild_project.test.name
}

output "codebuild_test_project_arn" {
  description = "ARN del proyecto CodeBuild para pruebas"
  value       = aws_codebuild_project.test.arn
}

output "codebuild_build_project_name" {
  description = "Nombre del proyecto CodeBuild para construcción"
  value       = aws_codebuild_project.build.name
}

output "codebuild_build_project_arn" {
  description = "ARN del proyecto CodeBuild para construcción"
  value       = aws_codebuild_project.build.arn
}

output "codedeploy_app_name" {
  description = "Nombre de la aplicación CodeDeploy"
  value       = aws_codedeploy_app.app.name
}

output "codedeploy_app_arn" {
  description = "ARN de la aplicación CodeDeploy"
  value       = aws_codedeploy_app.app.arn
}

output "deployment_group_name" {
  description = "Nombre del grupo de despliegue"
  value       = aws_codedeploy_deployment_group.deployment_group.deployment_group_name
}

output "deployment_group_arn" {
  description = "ARN del grupo de despliegue"
  value       = aws_codedeploy_deployment_group.deployment_group.arn
}

output "notification_rule_arn" {
  description = "ARN de la regla de notificación"
  value       = aws_codestarnotifications_notification_rule.pipeline.arn
}

output "pipeline_url" {
  description = "URL de la consola del pipeline"
  value       = "https://${var.region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.pipeline.name}/view"
}

output "codebuild_test_url" {
  description = "URL de la consola del proyecto de pruebas"
  value       = "https://${var.region}.console.aws.amazon.com/codesuite/codebuild/projects/${aws_codebuild_project.test.name}/history"
}

output "codebuild_build_url" {
  description = "URL de la consola del proyecto de construcción"
  value       = "https://${var.region}.console.aws.amazon.com/codesuite/codebuild/projects/${aws_codebuild_project.build.name}/history"
}

/*
output "repository_name" {
  description = "Nombre del repositorio CodeCommit"
  value       = aws_codecommit_repository.main.repository_name
}

output "repository_arn" {
  description = "ARN del repositorio CodeCommit"
  value       = aws_codecommit_repository.main.arn
}
*/ 