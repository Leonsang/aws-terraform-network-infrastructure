# Guía Maestra: Módulo de CI/CD

## Descripción General
Este módulo implementa un pipeline completo de CI/CD utilizando AWS CodePipeline, CodeBuild, CodeDeploy y CodeArtifact, con integración a repositorios de código y gestión de artefactos.

## Componentes Principales

### 1. CodePipeline
- **Pipeline Principal**:
  - Source stage
  - Build stage
  - Test stage
  - Deploy stage
  - Approval gates

### 2. CodeBuild
- **Proyectos**:
  - Build projects
  - Test projects
  - Security scan
  - Quality gates

### 3. CodeDeploy
- **Deployments**:
  - Blue/Green
  - Rolling updates
  - Canary deployments
  - Rollback config

### 4. CodeArtifact
- **Repositorios**:
  - Artifact storage
  - Version control
  - Dependencies
  - Access control

## Variables Principales

```hcl
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "repository_config" {
  description = "Configuración del repositorio"
  type = object({
    provider     = string
    repo_name    = string
    branch       = string
    oauth_token  = string
  })
}

variable "build_config" {
  description = "Configuración de build"
  type = object({
    compute_type                = string
    image                      = string
    type                       = string
    privileged_mode            = bool
    cache_type                 = string
    environment_variables      = map(string)
  })
}

variable "deploy_config" {
  description = "Configuración de deployment"
  type = object({
    deployment_type           = string
    deployment_config_name    = string
    auto_rollback            = bool
    alarm_configuration      = map(string)
  })
}

variable "artifact_config" {
  description = "Configuración de artefactos"
  type = object({
    domain_name              = string
    repository_name         = string
    upstream_repositories   = list(string)
    retention_period        = number
  })
}

variable "notification_config" {
  description = "Configuración de notificaciones"
  type = object({
    sns_topic_arn           = string
    events                  = list(string)
    detail_type            = string
  })
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}
```

## Outputs Principales

```hcl
output "pipeline_name" {
  description = "Nombre del pipeline"
  value       = aws_codepipeline.main.name
}

output "pipeline_arn" {
  description = "ARN del pipeline"
  value       = aws_codepipeline.main.arn
}

output "build_project_name" {
  description = "Nombre del proyecto CodeBuild"
  value       = aws_codebuild_project.main.name
}

output "build_project_arn" {
  description = "ARN del proyecto CodeBuild"
  value       = aws_codebuild_project.main.arn
}

output "deployment_group_name" {
  description = "Nombre del grupo de deployment"
  value       = aws_codedeploy_deployment_group.main.deployment_group_name
}

output "deployment_group_arn" {
  description = "ARN del grupo de deployment"
  value       = aws_codedeploy_deployment_group.main.arn
}

output "artifact_domain_name" {
  description = "Nombre del dominio CodeArtifact"
  value       = aws_codeartifact_domain.main.domain_name
}

output "artifact_repository_name" {
  description = "Nombre del repositorio CodeArtifact"
  value       = aws_codeartifact_repository.main.repository_name
}
```

## Uso del Módulo

```hcl
module "cicd" {
  source = "./modules/cicd"

  project_name = "mi-proyecto"
  environment  = "prod"

  repository_config = {
    provider    = "GitHub"
    repo_name   = "mi-org/mi-repo"
    branch      = "main"
    oauth_token = var.github_token
  }

  build_config = {
    compute_type           = "BUILD_GENERAL1_SMALL"
    image                 = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                  = "LINUX_CONTAINER"
    privileged_mode       = true
    cache_type            = "LOCAL"
    environment_variables = {
      NODE_ENV = "production"
    }
  }

  deploy_config = {
    deployment_type        = "BLUE_GREEN"
    deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
    auto_rollback         = true
    alarm_configuration   = {
      enabled = true
      ignore_poll_alarm_failure = false
    }
  }

  artifact_config = {
    domain_name           = "mi-dominio"
    repository_name      = "mi-repo"
    upstream_repositories = ["npmjs"]
    retention_period     = 30
  }

  notification_config = {
    sns_topic_arn = aws_sns_topic.pipeline_notifications.arn
    events        = ["PIPELINE_EXECUTION_STARTED", "PIPELINE_EXECUTION_FAILED"]
    detail_type   = "FULL"
  }

  tags = {
    Environment = "prod"
    Project     = "mi-proyecto"
  }
}
```

## Mejores Prácticas

### 1. Control de Versiones
- Usar Git Flow
- Implementar branch protection
- Requerir code reviews
- Automatizar versioning

### 2. Testing
- Unit tests
- Integration tests
- Security scans
- Quality checks

### 3. Deployment
- Implementar Blue/Green
- Configurar rollbacks
- Monitorear deployments
- Documentar procesos

### 4. Seguridad
- Secrets management
- IAM roles
- Security scans
- Audit logs

## Monitoreo y Mantenimiento

### 1. Pipeline
- Monitorear ejecuciones
- Revisar logs
- Analizar métricas
- Configurar alertas

### 2. Build
- Monitorear builds
- Optimizar cache
- Analizar tiempos
- Revisar recursos

### 3. Deploy
- Monitorear deployments
- Verificar health checks
- Analizar rollbacks
- Revisar logs

## Troubleshooting

### Problemas Comunes
1. **Pipeline**:
   - Source failures
   - Build timeouts
   - Deploy failures
   - Permission issues

2. **Build**:
   - Dependencies
   - Resource limits
   - Cache issues
   - Network problems

3. **Deploy**:
   - Health checks
   - Rollback failures
   - Configuration errors
   - Service discovery

## Seguridad

### 1. Accesos
- IAM roles
- Repository access
- Secrets management
- Audit logging

### 2. Scanning
- Code scanning
- Dependency scanning
- Container scanning
- Compliance checks

### 3. Protección
- Branch protection
- Approval gates
- Environment locks
- Role separation

## Costos y Optimización

### 1. Build
- Optimizar build times
- Usar caching
- Ajustar recursos
- Monitorear uso

### 2. Artifacts
- Implementar lifecycle
- Optimizar storage
- Limpiar versiones
- Monitorear costos

### 3. Pipeline
- Optimizar stages
- Reducir duración
- Ajustar concurrencia
- Monitorear ejecuciones 