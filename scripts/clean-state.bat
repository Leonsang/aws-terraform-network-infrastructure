@echo off
echo ADVERTENCIA: Este script eliminara todos los recursos y el estado de Terraform.
echo Los siguientes recursos seran eliminados:
echo - Buckets S3 de datos (raw, processed, analytics)
echo - Bucket S3 del backend
echo - Tabla DynamoDB del backend
echo.

set /p CONFIRM="Desea continuar? (S/N): "
if /i "%CONFIRM%" neq "S" (
    echo Operacion cancelada
    exit /b 0
)

echo.
echo Eliminando recursos...

REM Destruir recursos gestionados por Terraform
terraform destroy -auto-approve -lock=false

REM Eliminar bucket del backend y tabla DynamoDB
set BUCKET_NAME=terraform-state-fraud-detection
set TABLE_NAME=terraform-state-lock
set REGION=us-east-1

aws s3 rm s3://%BUCKET_NAME% --recursive
aws s3api delete-bucket --bucket %BUCKET_NAME% --region %REGION%
aws dynamodb delete-table --table-name %TABLE_NAME% --region %REGION%

REM Limpiar archivos locales
if exist .terraform rmdir /s /q .terraform
if exist terraform.tfstate del terraform.tfstate
if exist terraform.tfstate.backup del terraform.tfstate.backup
if exist .terraform.lock.hcl del .terraform.lock.hcl

echo.
echo Limpieza completada!
echo Para reiniciar el proyecto, ejecute:
echo 1. .\scripts\init-backend.bat
echo 2. terraform init
echo 3. terraform plan
echo 4. terraform apply 