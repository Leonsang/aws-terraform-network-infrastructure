# Script para crear paquetes ZIP para el módulo de ingesta de datos

$moduleDir = "../../modules/data_ingestion"

# Crear ZIP para la función de descarga de Kaggle
Compress-Archive -Path "kaggle_downloader.py" -DestinationPath "$moduleDir/functions/kaggle_downloader.zip" -Force

# Crear ZIP para la capa de Kaggle
New-Item -ItemType Directory -Force -Path "python/lib/python3.9/site-packages"
Copy-Item -Path "requirements.txt" -Destination "python/lib/python3.9/site-packages/" -Force
pip install -r requirements.txt -t "python/lib/python3.9/site-packages/"
Compress-Archive -Path "python" -DestinationPath "$moduleDir/layers/kaggle_layer.zip" -Force
Remove-Item -Path "python" -Recurse -Force

Write-Host "Paquetes creados exitosamente en $moduleDir" 