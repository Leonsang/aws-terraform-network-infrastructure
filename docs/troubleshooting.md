# 🔧 Guía de Solución de Problemas

## 🚨 Problemas Comunes y Soluciones

### 1. Errores de Credenciales

#### Error: "Unable to locate credentials"
**Solución:**
1. Verifica que AWS CLI está instalado
2. Ejecuta `aws configure`
3. Comprueba las variables de entorno:
```bash
echo %AWS_ACCESS_KEY_ID%
echo %AWS_SECRET_ACCESS_KEY%
echo %AWS_DEFAULT_REGION%
```

#### Error: "Invalid Kaggle credentials"
**Solución:**
1. Verifica el archivo `kaggle.json`
2. Comprueba los permisos del archivo
3. Actualiza las credenciales en Kaggle

### 2. Errores de Terraform

#### Error: "Error initializing Terraform"
**Solución:**
1. Verifica la versión de Terraform
2. Limpia el directorio `.terraform`
3. Ejecuta `terraform init -reconfigure`

#### Error: "State locked"
**Solución:**
1. Verifica si hay otro proceso ejecutándose
2. Elimina el archivo de estado:
```bash
rm .terraform/terraform.tfstate.lock.info
```

### 3. Errores de AWS

#### Error: "Access Denied"
**Solución:**
1. Verifica los permisos IAM
2. Comprueba las políticas de bucket
3. Revisa los roles de servicio

#### Error: "Resource limit exceeded"
**Solución:**
1. Revisa los límites de servicio
2. Solicita un aumento de límites
3. Limpia recursos no utilizados

### 4. Errores de ETL

#### Error: "Glue job failed"
**Solución:**
1. Revisa los logs en CloudWatch
2. Verifica la configuración del job
3. Comprueba los permisos de S3

#### Error: "Data validation failed"
**Solución:**
1. Revisa el esquema de datos
2. Verifica la calidad de datos
3. Comprueba las transformaciones

## 🔍 Diagnóstico

### 1. Verificación de Recursos

```bash
# Verificar recursos S3
aws s3 ls

# Verificar funciones Lambda
aws lambda list-functions

# Verificar jobs de Glue
aws glue get-jobs
```

### 2. Verificación de Logs

```bash
# Ver logs de CloudWatch
aws logs get-log-events --log-group-name /aws/lambda/function-name

# Ver logs de Glue
aws glue get-job-run --job-name job-name --run-id run-id
```

### 3. Verificación de Estado

```bash
# Ver estado de Step Functions
aws stepfunctions describe-execution --execution-arn arn:aws:states:region:account:execution:state-machine-name:execution-id

# Ver métricas de CloudWatch
aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Invocations
```

## 🛠️ Herramientas de Diagnóstico

### 1. AWS CLI
```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-windows-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
```

### 2. Terraform
```bash
# Verificar versión
terraform version

# Validar configuración
terraform validate

# Ver plan detallado
terraform plan -out=tfplan
```

### 3. Python
```bash
# Verificar dependencias
pip list

# Verificar versión
python --version
```

## 📝 Registro de Problemas

### 1. Información Necesaria
- Versión de software
- Logs de error
- Pasos para reproducir
- Configuración relevante

### 2. Plantilla de Reporte
```markdown
## Descripción del Problema
[Describe el problema]

## Pasos para Reproducir
1. [Paso 1]
2. [Paso 2]
3. [Paso 3]

## Logs de Error
```
[Pega los logs aquí]
```

## Configuración
- Versión de AWS CLI: [versión]
- Versión de Terraform: [versión]
- Versión de Python: [versión]
``` 