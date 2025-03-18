# Configurar variables
$BUCKET_NAME = "fraud-detection-dev-terraform-state"
$TABLE_NAME = "fraud-detection-dev-terraform-lock"
$REGION = "us-east-1"

# Crear el bucket S3
Write-Host "Creando bucket S3..."
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION

# Habilitar versionamiento
Write-Host "Habilitando versionamiento..."
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

# Habilitar cifrado
Write-Host "Habilitando cifrado..."
aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}'

# Bloquear acceso público
Write-Host "Bloqueando acceso público..."
aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Crear tabla DynamoDB
Write-Host "Creando tabla DynamoDB..."
aws dynamodb create-table --table-name $TABLE_NAME --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region $REGION

Write-Host "Configuración completada. Ahora puedes usar:"
Write-Host "terraform init -backend-config=\"bucket=$BUCKET_NAME\" -backend-config=\"key=terraform.tfstate\" -backend-config=\"region=$REGION\" -backend-config=\"dynamodb_table=$TABLE_NAME\" -backend-config=\"encrypt=true\"" 