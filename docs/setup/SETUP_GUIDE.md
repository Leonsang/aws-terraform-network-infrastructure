# 🚀 Guía de Configuración y Ejecución

Este documento proporciona instrucciones detalladas para configurar y ejecutar el proyecto de detección de fraude financiero.

## 📋 Requisitos Previos

1. **AWS CLI**: [AWS CLI v2](https://aws.amazon.com/cli/)
   - Versión 2.0 o superior
   - Configurado con credenciales de administrador

2. **Terraform**: [Terraform](https://www.terraform.io/downloads.html)
   - Versión 1.2.0 o superior
   - Compatible con el proveedor AWS

3. **Python**: [Python](https://www.python.org/downloads/)
   - Versión 3.9 o superior
   - pip instalado y actualizado

4. **Kaggle**: [Cuenta de Kaggle](https://www.kaggle.com/)
   - Cuenta activa
   - API key generada

5. **Git**: [Git](https://git-scm.com/downloads)
   - Última versión estable
   - Configurado con credenciales

## 🔧 Configuración Inicial

### 1. Clonar el Repositorio

```bash
git clone https://github.com/Leonsang/fraud-detection-terraform.git
cd fraud-detection-terraform
```

### 2. Configurar Credenciales de AWS

En Windows PowerShell:
```powershell
$env:AWS_ACCESS_KEY_ID="tu_access_key"
$env:AWS_SECRET_ACCESS_KEY="tu_secret_key"
$env:AWS_DEFAULT_REGION="us-east-1"
```

### 3. Configurar Kaggle

1. Crear archivo `kaggle.json`:
```json
{
    "username": "tu_usuario_kaggle",
    "key": "tu_api_key_kaggle"
}
```

2. Mover a la ubicación correcta:
```powershell
copy kaggle.json $env:USERPROFILE\.kaggle\kaggle.json
```

### 4. Configurar Variables del Proyecto

1. Crear `terraform.tfvars`:
```hcl
# Configuración AWS
aws_region = "us-east-1"
project_name = "fraud-detection"
environment = "dev"

# Configuración Kaggle
kaggle_dataset = "ieee-fraud-detection"
kaggle_username = "tu_usuario_kaggle"
kaggle_key = "tu_api_key_kaggle"

# Configuración de Notificaciones
alert_email = "tu.email@ejemplo.com"
```

## 🏗️ Despliegue de Infraestructura

### 1. Preparar el Entorno Terraform

```bash
# Inicializar Terraform
terraform init

# Validar configuración
terraform validate

# Verificar plan de ejecución
terraform plan -out=tfplan
```

### 2. Desplegar Recursos

```bash
# Aplicar configuración
terraform apply tfplan
```

## 📊 Configuración del Pipeline de Datos

### 1. Preparar Lambda Layer para Kaggle

```powershell
# Ejecutar script de preparación
.\scripts\create_kaggle_layer.sh
```

### 2. Verificar Despliegue

```powershell
# Verificar buckets S3
aws s3 ls

# Verificar funciones Lambda
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `fraud-detection-`)]'
```

## 🔄 Ejecución del Pipeline

### 1. Descarga Inicial de Datos

```powershell
# Ejecutar descarga manual (si es necesario)
.\scripts\trigger_kaggle_download.sh
```

### 2. Monitorear Procesamiento

```powershell
# Verificar estado del crawler
aws glue get-crawler --name fraud-detection-dev-raw-crawler

# Verificar estado del job ETL
aws glue get-job-runs --job-name fraud-detection-dev-etl-job
```

## 📈 Verificación y Monitoreo

### 1. Verificar Procesamiento de Datos

```powershell
# Verificar datos en S3
aws s3 ls s3://fraud-detection-dev-raw/data/
aws s3 ls s3://fraud-detection-dev-processed/data/
```

### 2. Revisar Logs

```powershell
# Logs de Lambda
aws logs tail /aws/lambda/fraud-detection-dev-kaggle-downloader

# Logs de Glue
aws logs tail /aws-glue/jobs/fraud-detection-dev-etl-job
```

## 🧹 Limpieza de Recursos

```powershell
# Eliminar todos los recursos
terraform destroy
```

## ❗ Solución de Problemas Comunes

### Error de Permisos AWS
- Verificar rol IAM y políticas
- Confirmar variables de entorno AWS

### Error en Descarga de Datos
- Verificar configuración de Kaggle
- Comprobar permisos del bucket S3

### Error en Procesamiento ETL
- Revisar logs de Glue
- Verificar formato de datos de entrada

## 📞 Soporte

Para problemas técnicos:
1. Revisar logs en CloudWatch
2. Consultar la [documentación detallada](../technical/TECHNICAL_DETAILS.md)
3. Abrir un issue en el repositorio 