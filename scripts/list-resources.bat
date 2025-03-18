@echo off
echo Listando recursos del proyecto...
echo.

echo === Buckets S3 de Datos ===
aws s3 ls s3://fraud-detection-dev-raw 2>nul
if %ERRORLEVEL% equ 0 (
    echo [EXISTE] fraud-detection-dev-raw
) else (
    echo [NO EXISTE] fraud-detection-dev-raw
)

aws s3 ls s3://fraud-detection-dev-processed 2>nul
if %ERRORLEVEL% equ 0 (
    echo [EXISTE] fraud-detection-dev-processed
) else (
    echo [NO EXISTE] fraud-detection-dev-processed
)

aws s3 ls s3://fraud-detection-dev-analytics 2>nul
if %ERRORLEVEL% equ 0 (
    echo [EXISTE] fraud-detection-dev-analytics
) else (
    echo [NO EXISTE] fraud-detection-dev-analytics
)

echo.
echo === Backend ===
aws s3 ls s3://terraform-state-fraud-detection 2>nul
if %ERRORLEVEL% equ 0 (
    echo [EXISTE] Bucket: terraform-state-fraud-detection
) else (
    echo [NO EXISTE] Bucket: terraform-state-fraud-detection
)

aws dynamodb describe-table --table-name terraform-state-lock --region us-east-1 2>nul
if %ERRORLEVEL% equ 0 (
    echo [EXISTE] Tabla DynamoDB: terraform-state-lock
) else (
    echo [NO EXISTE] Tabla DynamoDB: terraform-state-lock
)

echo.
echo === Archivos Locales ===
if exist .terraform (
    echo [EXISTE] Directorio .terraform
) else (
    echo [NO EXISTE] Directorio .terraform
)

if exist terraform.tfstate (
    echo [EXISTE] terraform.tfstate
) else (
    echo [NO EXISTE] terraform.tfstate
)

if exist terraform.tfstate.backup (
    echo [EXISTE] terraform.tfstate.backup
) else (
    echo [NO EXISTE] terraform.tfstate.backup
)

if exist .terraform.lock.hcl (
    echo [EXISTE] .terraform.lock.hcl
) else (
    echo [NO EXISTE] .terraform.lock.hcl
)

echo.
echo Para eliminar todos estos recursos, ejecute:
echo 1. .\scripts\delete-bucket.bat
echo 2. aws dynamodb delete-table --table-name terraform-state-lock --region us-east-1
echo 3. .\scripts\clean-state.bat 