import os
import json
import boto3
import kaggle
from datetime import datetime

def lambda_handler(event, context):
    try:
        # Configurar credenciales de Kaggle
        os.environ['KAGGLE_USERNAME'] = os.environ['KAGGLE_USERNAME']
        os.environ['KAGGLE_KEY'] = os.environ['KAGGLE_KEY']

        # Configurar el cliente S3
        s3 = boto3.client('s3')
        bucket_name = os.environ['RAW_BUCKET']
        
        # Descargar el dataset
        kaggle.api.authenticate()
        kaggle.api.competition_download_files(
            'ieee-fraud-detection',
            path='/tmp'
        )

        # Subir archivos a S3
        today = datetime.now().strftime('%Y/%m/%d')
        for filename in os.listdir('/tmp'):
            if filename.endswith('.csv'):
                s3_key = f'data/{today}/{filename}'
                s3.upload_file(
                    f'/tmp/{filename}',
                    bucket_name,
                    s3_key
                )
                print(f'Archivo {filename} subido a s3://{bucket_name}/{s3_key}')

        return {
            'statusCode': 200,
            'body': json.dumps('Descarga y carga de datos completada con éxito')
        }

    except Exception as e:
        print(f'Error: {str(e)}')
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error en la descarga de datos: {str(e)}')
        } 