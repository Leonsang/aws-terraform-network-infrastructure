import json
import logging
import boto3
import numpy as np
from datetime import datetime
from typing import Dict, Any

# Configuración de logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Inicializar clientes AWS
s3 = boto3.client('s3')
sagemaker = boto3.client('sagemaker-runtime')

def load_model_config() -> Dict[str, Any]:
    """Cargar configuración del modelo desde S3"""
    try:
        response = s3.get_object(
            Bucket='fraud-detection-config',
            Key='model_config.json'
        )
        return json.loads(response['Body'].read().decode('utf-8'))
    except Exception as e:
        logger.error(f"Error cargando configuración: {str(e)}")
        raise

def preprocess_transaction(transaction: Dict[str, Any]) -> np.ndarray:
    """Preprocesar transacción para el modelo"""
    try:
        # Extraer características
        features = [
            float(transaction['amount']),
            float(transaction['hour']),
            float(transaction['day_of_week']),
            float(transaction['merchant_risk_score']),
            float(transaction['customer_risk_score'])
        ]
        return np.array(features).reshape(1, -1)
    except Exception as e:
        logger.error(f"Error en preprocesamiento: {str(e)}")
        raise

def get_prediction(features: np.ndarray) -> float:
    """Obtener predicción del modelo"""
    try:
        response = sagemaker.invoke_endpoint(
            EndpointName='fraud-detection-endpoint',
            ContentType='application/json',
            Body=json.dumps({
                'features': features.tolist()
            })
        )
        result = json.loads(response['Body'].read().decode('utf-8'))
        return float(result['prediction'])
    except Exception as e:
        logger.error(f"Error en predicción: {str(e)}")
        raise

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Manejador principal de la función Lambda"""
    try:
        # Cargar configuración
        config = load_model_config()
        
        # Procesar transacción
        transaction = event['transaction']
        features = preprocess_transaction(transaction)
        
        # Obtener predicción
        fraud_probability = get_prediction(features)
        
        # Determinar resultado
        is_fraud = fraud_probability > config['fraud_threshold']
        
        # Preparar respuesta
        response = {
            'transaction_id': transaction['transaction_id'],
            'timestamp': datetime.utcnow().isoformat(),
            'fraud_probability': fraud_probability,
            'is_fraud': is_fraud,
            'threshold': config['fraud_threshold']
        }
        
        logger.info(f"Procesada transacción {transaction['transaction_id']}")
        return {
            'statusCode': 200,
            'body': json.dumps(response)
        }
        
    except Exception as e:
        logger.error(f"Error en procesamiento: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        } 