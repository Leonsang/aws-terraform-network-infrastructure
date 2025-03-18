# Script para crear paquetes ZIP de las funciones Lambda

$moduleDir = "../../modules/processing/lambda"

# Crear ZIP para la función de calidad de datos
Compress-Archive -Path "data_quality_lambda.py" -DestinationPath "$moduleDir/data_quality_lambda.zip" -Force

# Crear ZIP para la función de detección de fraude en tiempo real
Compress-Archive -Path "realtime_fraud_lambda.py" -DestinationPath "$moduleDir/realtime_fraud_lambda.zip" -Force

Write-Host "Paquetes Lambda creados exitosamente en $moduleDir" 