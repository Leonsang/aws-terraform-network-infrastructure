import json
import logging
import boto3
from datetime import datetime
from typing import Dict, Any, List
import pandas as pd
from pydantic import BaseModel, validator

# Configuración de logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Inicializar cliente S3
s3 = boto3.client('s3')

class Transaction(BaseModel):
    """Modelo de validación para transacciones"""
    transaction_id: str
    timestamp: datetime
    amount: float
    merchant_id: str
    customer_id: str
    is_fraud: float

    @validator('amount')
    def validate_amount(cls, v):
        if v <= 0:
            raise ValueError('El monto debe ser mayor a 0')
        return v

    @validator('is_fraud')
    def validate_fraud(cls, v):
        if v not in [0.0, 1.0]:
            raise ValueError('El valor de fraude debe ser 0.0 o 1.0')
        return v

def validate_schema(data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Validar esquema de los datos"""
    errors = []
    valid_data = []
    
    for record in data:
        try:
            Transaction(**record)
            valid_data.append(record)
        except Exception as e:
            errors.append({
                'record': record,
                'error': str(e)
            })
    
    return valid_data, errors

def check_data_quality(df: pd.DataFrame) -> Dict[str, Any]:
    """Realizar verificaciones de calidad de datos"""
    quality_metrics = {
        'total_records': len(df),
        'null_counts': df.isnull().sum().to_dict(),
        'duplicate_records': df.duplicated().sum(),
        'unique_merchants': df['merchant_id'].nunique(),
        'unique_customers': df['customer_id'].nunique(),
        'fraud_rate': df['is_fraud'].mean(),
        'amount_stats': {
            'mean': df['amount'].mean(),
            'std': df['amount'].std(),
            'min': df['amount'].min(),
            'max': df['amount'].max()
        }
    }
    
    return quality_metrics

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Manejador principal de la función Lambda"""
    try:
        # Obtener datos del evento
        bucket = event['bucket']
        key = event['key']
        
        # Leer datos
        response = s3.get_object(Bucket=bucket, Key=key)
        data = json.loads(response['Body'].read().decode('utf-8'))
        
        # Validar esquema
        valid_data, schema_errors = validate_schema(data)
        
        if schema_errors:
            logger.warning(f"Errores de esquema encontrados: {len(schema_errors)}")
        
        # Convertir a DataFrame
        df = pd.DataFrame(valid_data)
        
        # Verificar calidad
        quality_metrics = check_data_quality(df)
        
        # Preparar respuesta
        response = {
            'timestamp': datetime.utcnow().isoformat(),
            'file_location': f"s3://{bucket}/{key}",
            'schema_validation': {
                'total_records': len(data),
                'valid_records': len(valid_data),
                'error_count': len(schema_errors),
                'errors': schema_errors
            },
            'quality_metrics': quality_metrics
        }
        
        # Guardar resultados
        result_key = f"quality_reports/{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.json"
        s3.put_object(
            Bucket=bucket,
            Key=result_key,
            Body=json.dumps(response)
        )
        
        logger.info(f"Reporte de calidad guardado en: {result_key}")
        return {
            'statusCode': 200,
            'body': json.dumps(response)
        }
        
    except Exception as e:
        logger.error(f"Error en validación: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        } 