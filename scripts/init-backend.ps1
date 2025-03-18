# Script para inicializar el backend de Terraform
param(
    [string]$ProjectName = "fraud-detection",
    [string]$Environment = "dev",
    [string]$Region = "us-east-1"
)

# Verificar que AWS CLI está instalado
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Error "AWS CLI no está instalado. Por favor, instálalo primero."
    exit 1
}

# Verificar credenciales de AWS
try {
    aws sts get-caller-identity | Out-Null
} catch {
    Write-Error "No se encontraron credenciales válidas de AWS. Por favor, configura tus credenciales."
    exit 1
}

# Nombres de recursos
$BucketName = "$ProjectName-$Environment-terraform-state"
$TableName = "$ProjectName-$Environment-terraform-lock"

Write-Host "Creando bucket S3 para el estado de Terraform..."
aws s3api create-bucket --bucket $BucketName --region $Region

Write-Host "Configurando versionamiento en el bucket..."
aws s3api put-bucket-versioning --bucket $BucketName --versioning-configuration Status=Enabled

Write-Host "Configurando cifrado en el bucket..."
aws s3api put-bucket-encryption --bucket $BucketName --server-side-encryption-configuration '{
    "Rules": [
        {
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }
    ]
}'

Write-Host "Bloqueando acceso público al bucket..."
aws s3api put-public-access-block --bucket $BucketName --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

Write-Host "Creando tabla DynamoDB para el bloqueo de estado..."
aws dynamodb create-table --table-name $TableName `
    --attribute-definitions AttributeName=LockID,AttributeType=S `
    --key-schema AttributeName=LockID,KeyType=HASH `
    --billing-mode PAY_PER_REQUEST

Write-Host "Esperando a que la tabla DynamoDB esté activa..."
do {
    Start-Sleep -Seconds 5
    $TableStatus = aws dynamodb describe-table --table-name $TableName --query 'Table.TableStatus' --output text
} while ($TableStatus -ne "ACTIVE")

Write-Host "Backend creado exitosamente!"
Write-Host "Bucket S3: $BucketName"
Write-Host "Tabla DynamoDB: $TableName"
Write-Host "`nAhora puedes ejecutar:"
Write-Host "terraform init"
Write-Host "terraform plan" 