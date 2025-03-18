#!/usr/bin/env python3
"""
Script para descargar automáticamente el dataset IEEE-CIS Fraud Detection de Kaggle
y cargarlo en un bucket S3. Diseñado para ejecutarse como una función AWS Lambda.
"""

import os
import sys
import json
import zipfile
import subprocess
import logging
import tempfile
import boto3
from pathlib import Path

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('kaggle-downloader')

def setup_kaggle_credentials(kaggle_username, kaggle_key):
    """Configura las credenciales de Kaggle."""
    # Crear directorio .kaggle si no existe
    kaggle_dir = Path('/tmp/.kaggle')
    kaggle_dir.mkdir(exist_ok=True)
    
    # Crear archivo kaggle.json con las credenciales
    kaggle_json = kaggle_dir / 'kaggle.json'
    with open(kaggle_json, 'w') as f:
        json.dump({
            'username': kaggle_username,
            'key': kaggle_key
        }, f)
    
    # Establecer permisos adecuados
    os.chmod(kaggle_json, 0o600)
    
    # Establecer la variable de entorno KAGGLE_CONFIG_DIR
    os.environ['KAGGLE_CONFIG_DIR'] = str(kaggle_dir)
    
    logger.info("Credenciales de Kaggle configuradas correctamente")

def download_dataset(competition, path):
    """Descarga el dataset de Kaggle."""
    import kaggle
    
    logger.info(f"Descargando dataset {competition}...")
    kaggle.api.competition_download_files(competition, path=path)
    logger.info(f"Dataset descargado en {path}")

def extract_dataset(zip_path, extract_path):
    """Extrae el dataset descargado."""
    logger.info(f"Extrayendo archivos de {zip_path} a {extract_path}...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_path)
    logger.info("Archivos extraídos correctamente")

def upload_to_s3(local_path, s3_bucket, s3_prefix):
    """Sube los archivos al bucket S3 usando boto3."""
    logger.info(f"Subiendo archivos a s3://{s3_bucket}/{s3_prefix}...")
    
    s3_client = boto3.client('s3')
    
    # Subir archivos CSV
    for file in Path(local_path).glob('*.csv'):
        s3_key = f"{s3_prefix}/{file.name}"
        logger.info(f"Subiendo {file} a s3://{s3_bucket}/{s3_key}")
        s3_client.upload_file(str(file), s3_bucket, s3_key)
    
    logger.info("Archivos subidos correctamente a S3")

def lambda_handler(event, context):
    """Función principal para AWS Lambda."""
    # Obtener variables de entorno
    kaggle_username = os.environ.get('KAGGLE_USERNAME')
    kaggle_key = os.environ.get('KAGGLE_KEY')
    s3_bucket = os.environ.get('S3_BUCKET')
    s3_prefix = os.environ.get('S3_PREFIX', 'data')
    competition = os.environ.get('COMPETITION', 'ieee-fraud-detection')
    
    # Validar variables de entorno
    if not all([kaggle_username, kaggle_key, s3_bucket]):
        error_msg = "Faltan variables de entorno requeridas: KAGGLE_USERNAME, KAGGLE_KEY, S3_BUCKET"
        logger.error(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }
    
    # Crear directorio temporal
    temp_dir = tempfile.mkdtemp(dir='/tmp')
    
    try:
        # Configurar credenciales de Kaggle
        setup_kaggle_credentials(kaggle_username, kaggle_key)
        
        # Descargar dataset
        download_dataset(competition, temp_dir)
        
        # Extraer archivos
        zip_file = Path(temp_dir) / f"{competition}.zip"
        extract_dataset(zip_file, temp_dir)
        
        # Subir a S3
        upload_to_s3(temp_dir, s3_bucket, s3_prefix)
        
        logger.info("Proceso completado exitosamente")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Dataset descargado y subido a S3 correctamente',
                's3_bucket': s3_bucket,
                's3_prefix': s3_prefix
            })
        }
        
    except Exception as e:
        error_msg = f"Error: {str(e)}"
        logger.error(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }
    finally:
        # Limpiar archivos temporales
        import shutil
        logger.info(f"Limpiando directorio temporal {temp_dir}...")
        shutil.rmtree(temp_dir, ignore_errors=True)

# Para pruebas locales
if __name__ == "__main__":
    # Simular evento y contexto de Lambda
    event = {}
    context = None
    
    # Configurar variables de entorno para pruebas locales
    os.environ['KAGGLE_USERNAME'] = 'tu_usuario_kaggle'
    os.environ['KAGGLE_KEY'] = 'tu_api_key_kaggle'
    os.environ['S3_BUCKET'] = 'tu_bucket_s3'
    os.environ['S3_PREFIX'] = 'data'
    os.environ['COMPETITION'] = 'ieee-fraud-detection'
    
    # Ejecutar la función
    result = lambda_handler(event, context)
    print(result) 