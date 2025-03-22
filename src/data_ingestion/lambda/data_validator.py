import json
import os
import boto3
import pandas as pd
from datetime import datetime

def lambda_handler(event, context):
    """
    Función Lambda para validar los datos descargados de Kaggle
    """
    try:
        # Inicializar clientes
        s3_client = boto3.client('s3')
        
        # Configuración
        bucket_name = os.environ['RAW_BUCKET']
        dataset_path = 'creditcardfraud/creditcard.csv'
        
        # Descargar archivo de S3
        print("Descargando archivo para validación...")
        response = s3_client.get_object(Bucket=bucket_name, Key=dataset_path)
        df = pd.read_csv(response['Body'])
        
        # Validaciones
        validation_results = {
            'timestamp': datetime.now().isoformat(),
            'total_rows': len(df),
            'missing_values': df.isnull().sum().to_dict(),
            'column_types': df.dtypes.astype(str).to_dict(),
            'basic_stats': {
                'mean': df.mean().to_dict(),
                'std': df.std().to_dict(),
                'min': df.min().to_dict(),
                'max': df.max().to_dict()
            }
        }
        
        # Verificar valores nulos
        if df.isnull().any().any():
            validation_results['has_missing_values'] = True
        else:
            validation_results['has_missing_values'] = False
        
        # Verificar tipos de datos
        expected_types = {
            'Time': 'float64',
            'Amount': 'float64',
            'Class': 'int64'
        }
        
        validation_results['type_validation'] = {
            col: df[col].dtype == expected_types.get(col, df[col].dtype)
            for col in df.columns
        }
        
        # Guardar resultados de validación
        validation_key = f"validation_results/{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        s3_client.put_object(
            Bucket=bucket_name,
            Key=validation_key,
            Body=json.dumps(validation_results)
        )
        
        # Determinar si la validación fue exitosa
        validation_success = (
            not validation_results['has_missing_values'] and
            all(validation_results['type_validation'].values())
        )
        
        return {
            'statusCode': 200 if validation_success else 400,
            'body': json.dumps({
                'message': 'Validación completada',
                'success': validation_success,
                'validation_results': validation_results,
                'validation_file': validation_key
            })
        }
        
    except Exception as e:
        print(f"Error en la validación: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        } 