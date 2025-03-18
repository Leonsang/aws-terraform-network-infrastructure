"""
Función Lambda para validación de calidad de datos
Esta función verifica la calidad de los datos en la zona raw antes de procesarlos.
"""

import json
import boto3
import pandas as pd
import io
import logging
import os
from datetime import datetime
import awswrangler as wr

# Configuración del logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Inicializar clientes de AWS
s3 = boto3.client('s3')
glue = boto3.client('glue')
sns = boto3.client('sns')

# Obtener variables de entorno
RAW_BUCKET = os.environ.get('RAW_BUCKET')
PROCESSED_BUCKET = os.environ.get('PROCESSED_BUCKET')
DATABASE_NAME = os.environ.get('DATABASE_NAME')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')

def setup_logging():
    """Configura el formato del logging"""
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    handler = logging.StreamHandler()
    handler.setFormatter(formatter)
    logger.addHandler(handler)

def log_validation_result(result, context):
    """Registra el resultado de la validación con detalles"""
    log_data = {
        "timestamp": datetime.utcnow().isoformat(),
        "validation_result": result,
        "context": context,
        "environment": "production"
    }
    logger.info(json.dumps(log_data))

def lambda_handler(event, context):
    """
    Función principal de Lambda para validación de calidad de datos.
    """
    try:
        # Obtener variables de entorno
        raw_bucket = os.environ["RAW_BUCKET"]
        processed_bucket = os.environ["PROCESSED_BUCKET"]
        database_name = os.environ["DATABASE_NAME"]
        
        # Leer datos de S3 usando AWS Data Wrangler
        df = wr.s3.read_parquet(
            path=f"s3://{raw_bucket}/data/transactions/",
            dataset=True
        )
        
        # Validar datos
        validation_results = validate_transaction_data(df)
        
        # Guardar resultados de validación
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        validation_path = f"s3://{processed_bucket}/validation/transaction_validation_{timestamp}.json"
        
        s3 = boto3.client("s3")
        s3.put_object(
            Bucket=processed_bucket,
            Key=f"validation/transaction_validation_{timestamp}.json",
            Body=json.dumps(validation_results, indent=2)
        )
        
        # Verificar si hay problemas críticos
        critical_issues = (
            validation_results["validation_rules"]["invalid_amounts"] > 0 or
            validation_results["validation_rules"]["missing_required_fields"] > 100 or
            validation_results["validation_rules"]["duplicate_transactions"] > 50
        )
        
        return {
            "statusCode": 200 if not critical_issues else 400,
            "body": json.dumps({
                "message": "Data quality validation completed",
                "validation_results": validation_results,
                "validation_path": validation_path,
                "has_critical_issues": critical_issues
            })
        }
        
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e),
                "message": "Error during data quality validation"
            })
        }

def validate_transaction_data(df):
    """
    Valida la calidad de los datos de transacciones.
    """
    validation_results = {
        "total_records": len(df),
        "null_counts": {},
        "validation_rules": {
            "invalid_amounts": 0,
            "invalid_dates": 0,
            "duplicate_transactions": 0,
            "missing_required_fields": 0
        },
        "timestamp": datetime.now().isoformat()
    }
    
    # Verificar valores nulos
    for column in df.columns:
        null_count = df[column].isnull().sum()
        if null_count > 0:
            validation_results["null_counts"][column] = int(null_count)
    
    # Verificar montos inválidos
    validation_results["validation_rules"]["invalid_amounts"] = int(
        df[df["amount"] <= 0].shape[0]
    )
    
    # Verificar fechas inválidas
    validation_results["validation_rules"]["invalid_dates"] = int(
        df[df["timestamp"].isnull()].shape[0]
    )
    
    # Verificar transacciones duplicadas
    duplicates = df[df.duplicated(subset=["transaction_id"], keep=False)].shape[0]
    validation_results["validation_rules"]["duplicate_transactions"] = int(duplicates)
    
    # Verificar campos requeridos
    required_fields = ["transaction_id", "card_id", "merchant_id", "amount"]
    missing_required = df[required_fields].isnull().any(axis=1).sum()
    validation_results["validation_rules"]["missing_required_fields"] = int(missing_required)
    
    return validation_results

def validate_identity_file(bucket, key):
    """
    Valida un archivo de identidad.
    """
    setup_logging()
    context = {"bucket": bucket, "key": key}
    
    try:
        logger.info(f"Iniciando validación del archivo: s3://{bucket}/{key}")
        
        # Cargar el archivo en un DataFrame
        df = load_file_to_dataframe(bucket, key)
        
        if df is None:
            result = {
                "status": "error",
                "message": f"No se pudo cargar el archivo: s3://{bucket}/{key}"
            }
            log_validation_result(result, context)
            return result
        
        # Verificar columnas requeridas
        required_columns = ["TransactionID"]
        missing_columns = [col for col in required_columns if col not in df.columns]
        
        if missing_columns:
            result = {
                "status": "error",
                "message": f"Columnas requeridas faltantes: {missing_columns}"
            }
            log_validation_result(result, context)
            return result
        
        # Verificar duplicados
        duplicate_count = df.duplicated(subset=["TransactionID"]).sum()
        if duplicate_count > 0:
            result = {
                "status": "warning",
                "message": f"Se encontraron {duplicate_count} TransactionID duplicados"
            }
            log_validation_result(result, context)
        
        # Generar estadísticas
        device_type_counts = df["DeviceType"].value_counts().to_dict() if "DeviceType" in df.columns else {}
        
        stats = {
            "total_rows": len(df),
            "unique_transaction_ids": df["TransactionID"].nunique(),
            "device_type_counts": device_type_counts
        }
        
        # Guardar estadísticas en S3
        save_stats_to_s3(stats, key)
        
        result = {
            "status": "success",
            "message": "Validación completada exitosamente",
            "stats": stats
        }
        log_validation_result(result, context)
        return result
        
    except Exception as e:
        result = {
            "status": "error",
            "message": f"Error durante la validación: {str(e)}"
        }
        log_validation_result(result, context)
        return result

def load_file_to_dataframe(bucket, key):
    """
    Carga un archivo de S3 en un DataFrame de pandas.
    """
    try:
        # Obtener el objeto de S3
        response = s3.get_object(Bucket=bucket, Key=key)
        content = response['Body'].read()
        
        # Determinar el formato del archivo
        if key.endswith('.csv'):
            return pd.read_csv(io.BytesIO(content))
        elif key.endswith('.parquet'):
            return pd.read_parquet(io.BytesIO(content))
        else:
            logger.error(f"Formato de archivo no soportado: {key}")
            return None
    
    except Exception as e:
        logger.error(f"Error cargando archivo: {str(e)}")
        return None

def save_stats_to_s3(stats, source_key):
    """
    Guarda las estadísticas en S3.
    """
    try:
        # Generar nombre de archivo para las estadísticas
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        file_name = source_key.split('/')[-1].split('.')[0]
        stats_key = f"data-quality/stats/{file_name}_{timestamp}.json"
        
        # Guardar estadísticas en S3
        s3.put_object(
            Bucket=PROCESSED_BUCKET,
            Key=stats_key,
            Body=json.dumps(stats, indent=2),
            ContentType='application/json'
        )
        
        logger.info(f"Estadísticas guardadas en s3://{PROCESSED_BUCKET}/{stats_key}")
    
    except Exception as e:
        logger.error(f"Error guardando estadísticas: {str(e)}")

def send_notification(validation_result, file_key):
    """
    Envía una notificación SNS sobre problemas de calidad de datos.
    """
    try:
        subject = f"Alerta de calidad de datos - {validation_result['status'].upper()}"
        
        message = f"""
        Se ha detectado un problema de calidad de datos:
        
        Archivo: {file_key}
        Estado: {validation_result['status']}
        Mensaje: {validation_result['message']}
        
        Fecha y hora: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
        """
        
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        
        logger.info(f"Notificación enviada al tema SNS: {SNS_TOPIC_ARN}")
    
    except Exception as e:
        logger.error(f"Error enviando notificación: {str(e)}") 