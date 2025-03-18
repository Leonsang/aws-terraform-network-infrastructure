@echo off
echo Inicializando backend de Terraform...

set BUCKET_NAME=terraform-state-fraud-detection
set TABLE_NAME=terraform-state-lock
set REGION=us-east-1

where aws >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: AWS CLI no esta instalado
    exit /b 1
)

aws sts get-caller-identity >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: No se encontraron credenciales validas de AWS
    exit /b 1
)

echo Creando bucket S3 para el estado...
aws s3api create-bucket --bucket %BUCKET_NAME% --region %REGION% >nul 2>nul

echo Habilitando versionamiento en el bucket...
aws s3api put-bucket-versioning --bucket %BUCKET_NAME% --versioning-configuration Status=Enabled

echo Habilitando cifrado en el bucket...
aws s3api put-bucket-encryption --bucket %BUCKET_NAME% --server-side-encryption-configuration "{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}"

echo Bloqueando acceso publico al bucket...
aws s3api put-public-access-block --bucket %BUCKET_NAME% --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo Creando tabla DynamoDB para bloqueo de estado...
aws dynamodb create-table --table-name %TABLE_NAME% --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --region %REGION% >nul 2>nul

echo Backend inicializado correctamente!
echo Bucket S3: %BUCKET_NAME%
echo Tabla DynamoDB: %TABLE_NAME%
echo Region: %REGION% 