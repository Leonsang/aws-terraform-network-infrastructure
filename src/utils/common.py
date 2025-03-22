import logging
import json
from typing import Dict, Any
from datetime import datetime
import boto3
import os

def setup_logging(level: str = 'INFO') -> logging.Logger:
    """Configurar logging con formato estándar"""
    logger = logging.getLogger()
    logger.setLevel(getattr(logging, level))
    
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
    
    return logger

def load_config(bucket: str, key: str) -> Dict[str, Any]:
    """Cargar configuración desde S3"""
    try:
        s3 = boto3.client('s3')
        response = s3.get_object(Bucket=bucket, Key=key)
        return json.loads(response['Body'].read().decode('utf-8'))
    except Exception as e:
        raise Exception(f"Error cargando configuración: {str(e)}")

def save_metrics(bucket: str, key: str, metrics: Dict[str, Any]) -> None:
    """Guardar métricas en S3"""
    try:
        s3 = boto3.client('s3')
        metrics['timestamp'] = datetime.utcnow().isoformat()
        s3.put_object(
            Bucket=bucket,
            Key=key,
            Body=json.dumps(metrics)
        )
    except Exception as e:
        raise Exception(f"Error guardando métricas: {str(e)}")

def validate_environment(required_vars: list) -> None:
    """Validar variables de entorno requeridas"""
    missing_vars = []
    for var in required_vars:
        if var not in os.environ:
            missing_vars.append(var)
    
    if missing_vars:
        raise ValueError(f"Variables de entorno faltantes: {', '.join(missing_vars)}")

def format_error_response(error: Exception) -> Dict[str, Any]:
    """Formatear respuesta de error estándar"""
    return {
        'statusCode': 500,
        'body': json.dumps({
            'error': str(error),
            'timestamp': datetime.utcnow().isoformat()
        })
    }

def format_success_response(data: Dict[str, Any]) -> Dict[str, Any]:
    """Formatear respuesta de éxito estándar"""
    return {
        'statusCode': 200,
        'body': json.dumps({
            'data': data,
            'timestamp': datetime.utcnow().isoformat()
        })
    } 