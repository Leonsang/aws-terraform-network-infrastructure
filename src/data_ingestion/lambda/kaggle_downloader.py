import json
import os
import boto3
import kaggle
from kaggle.api.kaggle_api_extended import KaggleApi
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    """
    Función Lambda para descargar dataset de Kaggle y subirlo a S3
    """
    try:
        # Inicializar clientes
        s3_client = boto3.client('s3')
        kaggle_api = KaggleApi()
        kaggle_api.authenticate()
        
        # Configuración
        bucket_name = os.environ['RAW_BUCKET']
        dataset_name = 'mlg-ulb/creditcardfraud'
        
        # Crear directorio temporal en /tmp
        temp_dir = '/tmp/kaggle_data'
        os.makedirs(temp_dir, exist_ok=True)
        
        # Descargar dataset
        print(f"Descargando dataset {dataset_name}...")
        kaggle_api.dataset_download_files(
            dataset_name,
            path=temp_dir,
            unzip=True
        )
        
        # Subir archivos a S3
        for file in os.listdir(temp_dir):
            if file.endswith('.csv'):
                s3_path = f"creditcardfraud/{file}"
                local_path = os.path.join(temp_dir, file)
                
                print(f"Subiendo {file} a S3...")
                s3_client.upload_file(
                    local_path,
                    bucket_name,
                    s3_path
                )
        
        # Limpiar archivos temporales
        for file in os.listdir(temp_dir):
            os.remove(os.path.join(temp_dir, file))
        os.rmdir(temp_dir)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Dataset descargado y subido exitosamente',
                'bucket': bucket_name,
                'dataset': dataset_name
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        } 