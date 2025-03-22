# Script de limpieza para recursos AWS
Write-Host "Iniciando limpieza de recursos AWS..."

# Configurar variables
$PROJECT_NAME = "terraform-aws"
$ENVIRONMENT = "dev"

# Eliminar recursos de S3
Write-Host "Eliminando buckets S3..."
$buckets = @(
    "$PROJECT_NAME-$ENVIRONMENT-feature-store",
    "$PROJECT_NAME-$ENVIRONMENT-analytics",
    "$PROJECT_NAME-$ENVIRONMENT-processed",
    "$PROJECT_NAME-$ENVIRONMENT-raw"
)

foreach ($bucket in $buckets) {
    Write-Host "Eliminando bucket: $bucket"
    aws s3 rb s3://$bucket --force
}

# Eliminar recursos de Glue
Write-Host "Eliminando recursos de Glue..."
$jobs = @(
    "$PROJECT_NAME-$ENVIRONMENT-processing",
    "$PROJECT_NAME-$ENVIRONMENT-feature-engineering",
    "$PROJECT_NAME-$ENVIRONMENT-raw-processing"
)

foreach ($job in $jobs) {
    Write-Host "Eliminando job: $job"
    aws glue delete-job --job-name $job
}

# Eliminar recursos de ECS
Write-Host "Eliminando recursos de ECS..."
aws ecs delete-cluster --cluster "$PROJECT_NAME-$ENVIRONMENT-cluster" --force

# Eliminar recursos de DynamoDB
Write-Host "Eliminando tabla DynamoDB..."
aws dynamodb delete-table --table-name "$PROJECT_NAME-$ENVIRONMENT-table"

# Eliminar recursos de Kinesis
Write-Host "Eliminando stream de Kinesis..."
aws kinesis delete-stream --stream-name "$PROJECT_NAME-$ENVIRONMENT-stream"

# Eliminar recursos de Step Functions
Write-Host "Eliminando máquina de estados de Step Functions..."
aws stepfunctions delete-state-machine --state-machine-arn "arn:aws:states:us-east-1:$(aws sts get-caller-identity --query Account --output text):stateMachine:$PROJECT_NAME-$ENVIRONMENT-etl-orchestration"

# Eliminar recursos de IAM
Write-Host "Eliminando roles y políticas de IAM..."
$roles = @(
    "$PROJECT_NAME-$ENVIRONMENT-glue-role",
    "$PROJECT_NAME-$ENVIRONMENT-step-functions-role"
)

foreach ($role in $roles) {
    Write-Host "Eliminando rol: $role"
    aws iam delete-role --role-name $role
}

# Eliminar recursos de CloudWatch
Write-Host "Eliminando recursos de CloudWatch..."
$logGroups = @(
    "/aws/glue/$PROJECT_NAME-$ENVIRONMENT-processing",
    "/aws/glue/$PROJECT_NAME-$ENVIRONMENT-feature-engineering",
    "/aws/glue/$PROJECT_NAME-$ENVIRONMENT-raw-processing"
)

foreach ($group in $logGroups) {
    Write-Host "Eliminando grupo de logs: $group"
    aws logs delete-log-group --log-group-name $group
}

# Eliminar recursos de API Gateway
Write-Host "Eliminando recursos de API Gateway..."
$apis = aws apigateway get-rest-apis --query "items[?contains(name, '$PROJECT_NAME-$ENVIRONMENT')].id" --output text
foreach ($api in $apis) {
    Write-Host "Eliminando API: $api"
    aws apigateway delete-rest-api --rest-api-id $api
}

Write-Host "Limpieza completada. Por favor, verifica en la consola de AWS que todos los recursos hayan sido eliminados correctamente." 