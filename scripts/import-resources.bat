@echo off
echo Importando recursos existentes a Terraform...

terraform import -lock=false module.storage.aws_s3_bucket.raw fraud-detection-dev-raw
terraform import -lock=false module.storage.aws_s3_bucket.processed fraud-detection-dev-processed
terraform import -lock=false module.storage.aws_s3_bucket.analytics fraud-detection-dev-analytics

echo Proceso de importacion completado!
echo Por favor, ejecute 'terraform plan' para verificar el estado. 