import os
import json
import logging
import boto3
import kaggle
from datetime import datetime

# Configuración de logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def setup_kaggle():
    """Configura las credenciales de Kaggle."""
    try:
        # Crear directorio .kaggle si no existe
        kaggle_dir = os.path.expanduser('~/.kaggle')
        os.makedirs(kaggle_dir, exist_ok=True)
        
        # Crear archivo de credenciales
        creds = {
            'username': os.environ['KAGGLE_USERNAME'],
            'key': os.environ['KAGGLE_KEY']
        }
        
        with open(os.path.join(kaggle_dir, 'kaggle.json'), 'w') as f:
            json.dump(creds, f)
        
        # Establecer permisos seguros
        os.chmod(os.path.join(kaggle_dir, 'kaggle.json'), 0o600)
        logger.info("Credenciales de Kaggle configuradas exitosamente")
    except Exception as e:
        logger.error(f"Error configurando credenciales de Kaggle: {str(e)}")
        raise

def process_dataset():
    """Descarga el dataset de Kaggle y lo sube a S3."""
    try:
        # Descargar dataset
        dataset = "mlg-ulb/creditcardfraud"
        kaggle.api.dataset_download_files(dataset, path='/tmp', unzip=True)
        logger.info(f"Dataset {dataset} descargado exitosamente")
        
        # Encontrar archivo CSV
        csv_file = None
        for file in os.listdir('/tmp'):
            if file.endswith('.csv'):
                csv_file = file
                break
        
        if not csv_file:
            raise FileNotFoundError("No se encontró archivo CSV en la descarga")
        
        # Subir a S3
        s3 = boto3.client('s3')
        bucket = os.environ['RAW_BUCKET']
        current_date = datetime.now().strftime('%Y/%m/%d')
        key = f"credit_fraud/{current_date}/creditcard.csv"
        
        with open(f'/tmp/{csv_file}', 'rb') as f:
            s3.upload_fileobj(f, bucket, key)
        logger.info(f"Archivo subido exitosamente a s3://{bucket}/{key}")
        
        # Limpiar archivos temporales
        os.remove(f'/tmp/{csv_file}')
        logger.info("Archivos temporales eliminados")
        
        return {
            'bucket': bucket,
            'key': key,
            'timestamp': datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Error procesando dataset: {str(e)}")
        raise

def lambda_handler(event, context):
    """Manejador principal de la función Lambda."""
    try:
        setup_kaggle()
        result = process_dataset()
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        } 