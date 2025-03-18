"""
Función Lambda para procesamiento en tiempo real de fraude
Esta función procesa transacciones en tiempo real desde Kinesis y detecta posibles fraudes.
"""

import json
import boto3
import base64
import os
import logging
import time
import uuid
from datetime import datetime, timedelta
import numpy as np
from decimal import Decimal
import pandas as pd

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Inicializar clientes de AWS
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
sns = boto3.client('sns')

# Obtener variables de entorno
DYNAMODB_TABLE = os.environ.get('DYNAMODB_TABLE')
PROCESSED_BUCKET = os.environ.get('PROCESSED_BUCKET')
ANALYTICS_BUCKET = os.environ.get('ANALYTICS_BUCKET')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')

# Cargar la tabla de DynamoDB
card_stats_table = dynamodb.Table(DYNAMODB_TABLE)

# Umbrales para detección de fraude
AMOUNT_THRESHOLD = 5000.0  # Monto de transacción sospechoso
VELOCITY_THRESHOLD = 3     # Número de transacciones en corto tiempo
TIME_WINDOW = 3600         # Ventana de tiempo en segundos (1 hora)
DISTANCE_THRESHOLD = 100   # Distancia geográfica sospechosa (en unidades arbitrarias)

def get_card_stats(dynamodb, card_id, table_name):
    """
    Obtiene las estadísticas históricas de una tarjeta desde DynamoDB.
    """
    try:
        response = dynamodb.get_item(
            TableName=table_name,
            Key={
                'card_id': {'S': card_id},
                'transaction_date': {'S': datetime.now().strftime('%Y-%m-%d')}
            }
        )
        
        if 'Item' in response:
            return {
                'daily_transactions': int(response['Item']['daily_transactions']['N']),
                'daily_amount': float(response['Item']['daily_amount']['N']),
                'avg_transaction_amount': float(response['Item']['avg_transaction_amount']['N']),
                'last_transaction_time': response['Item']['last_transaction_time']['S']
            }
        return None
    except Exception as e:
        logger.error(f"Error getting card stats: {str(e)}")
        return None

def update_card_stats(dynamodb, card_stats, transaction, table_name):
    """
    Actualiza las estadísticas de la tarjeta en DynamoDB.
    """
    try:
        if card_stats is None:
            card_stats = {
                'daily_transactions': 0,
                'daily_amount': 0.0,
                'avg_transaction_amount': 0.0,
                'last_transaction_time': datetime.now().isoformat()
            }
        
        new_daily_transactions = card_stats['daily_transactions'] + 1
        new_daily_amount = card_stats['daily_amount'] + transaction['amount']
        new_avg_amount = new_daily_amount / new_daily_transactions
        
        dynamodb.put_item(
            TableName=table_name,
            Item={
                'card_id': {'S': transaction['card_id']},
                'transaction_date': {'S': datetime.now().strftime('%Y-%m-%d')},
                'daily_transactions': {'N': str(new_daily_transactions)},
                'daily_amount': {'N': str(new_daily_amount)},
                'avg_transaction_amount': {'N': str(new_avg_amount)},
                'last_transaction_time': {'S': datetime.now().isoformat()}
            }
        )
    except Exception as e:
        logger.error(f"Error updating card stats: {str(e)}")

def detect_anomalies(transaction, card_stats):
    """
    Detecta anomalías en la transacción basándose en las estadísticas de la tarjeta.
    """
    anomalies = []
    
    if card_stats:
        # Verificar monto inusual
        if transaction['amount'] > card_stats['avg_transaction_amount'] * 3:
            anomalies.append('unusual_amount')
        
        # Verificar frecuencia inusual
        if card_stats['daily_transactions'] > 20:  # Umbral arbitrario
            anomalies.append('high_frequency')
        
        # Verificar velocidad entre transacciones
        if card_stats.get('last_transaction_time'):
            last_tx_time = datetime.fromisoformat(card_stats['last_transaction_time'])
            current_time = datetime.now()
            if (current_time - last_tx_time).total_seconds() < 60:  # Menos de 1 minuto
                anomalies.append('high_velocity')
    
    # Verificar monto grande
    if transaction['amount'] > 10000:  # Umbral arbitrario
        anomalies.append('large_amount')
    
    return anomalies

def save_to_s3(transaction, anomalies, bucket, prefix):
    """
    Guarda la transacción y sus anomalías en S3.
    """
    try:
        s3 = boto3.client('s3')
        
        transaction_with_anomalies = {
            **transaction,
            'anomalies': anomalies,
            'timestamp': datetime.now().isoformat()
        }
        
        year = datetime.now().strftime('%Y')
        month = datetime.now().strftime('%m')
        day = datetime.now().strftime('%d')
        filename = f"{transaction['transaction_id']}.json"
        
        key = f"{prefix}/{year}/{month}/{day}/{filename}"
        
        s3.put_object(
            Bucket=bucket,
            Key=key,
            Body=json.dumps(transaction_with_anomalies, indent=2)
        )
        
        return f"s3://{bucket}/{key}"
    except Exception as e:
        logger.error(f"Error saving to S3: {str(e)}")
        return None

def lambda_handler(event, context):
    """
    Función principal que se ejecuta cuando se invoca la Lambda.
    Procesa registros de Kinesis y detecta posibles fraudes.
    """
    logger.info("Iniciando procesamiento en tiempo real de fraude")
    
    if 'Records' not in event:
        logger.warning("Evento no contiene registros de Kinesis")
        return {
            "statusCode": 400,
            "body": "Evento no contiene registros de Kinesis"
        }
    
    processed_count = 0
    fraud_detected_count = 0
    batch_item_failures = []
    
    for record in event['Records']:
        try:
            # Obtener datos del registro de Kinesis
            payload = base64.b64decode(record['kinesis']['data']).decode('utf-8')
            transaction = json.loads(payload)
            
            # Registrar la transacción recibida
            logger.info(f"Procesando transacción: {json.dumps(transaction)}")
            
            # Validar la transacción
            if not is_valid_transaction(transaction):
                logger.warning(f"Transacción inválida: {json.dumps(transaction)}")
                batch_item_failures.append({"itemIdentifier": record['kinesis']['sequenceNumber']})
                continue
            
            # Obtener estadísticas de la tarjeta
            card_stats = get_card_stats(dynamodb, transaction['card_id'], DYNAMODB_TABLE)
            
            # Detectar anomalías
            anomalies = detect_anomalies(transaction, card_stats)
            
            # Actualizar estadísticas de la tarjeta
            update_card_stats(dynamodb, card_stats, transaction, DYNAMODB_TABLE)
            
            # Guardar transacción procesada en S3
            processed_path = save_to_s3(
                transaction,
                anomalies,
                PROCESSED_BUCKET,
                'processed_transactions'
            )
            
            # Si hay anomalías, guardar en la zona de análisis
            if anomalies:
                analytics_path = save_to_s3(
                    transaction,
                    anomalies,
                    ANALYTICS_BUCKET,
                    'anomalous_transactions'
                )
            
            processed_count += 1
            
            # Si se detectó fraude, incrementar el contador
            if anomalies:
                fraud_detected_count += 1
                
                # Guardar la transacción fraudulenta en S3
                save_fraud_transaction(transaction, anomalies)
                
                # Enviar alerta si hay un tema SNS configurado
                if SNS_TOPIC_ARN:
                    send_fraud_alert(transaction, anomalies)
        
        except Exception as e:
            logger.error(f"Error procesando registro: {str(e)}")
            batch_item_failures.append({"itemIdentifier": record['kinesis']['sequenceNumber']})
    
    logger.info(f"Procesamiento completado. Transacciones procesadas: {processed_count}, Fraudes detectados: {fraud_detected_count}")
    
    return {
        "statusCode": 200,
        "body": json.dumps({
            "processed_count": processed_count,
            "fraud_detected_count": fraud_detected_count
        }),
        "batchItemFailures": batch_item_failures
    }

def is_valid_transaction(transaction):
    """
    Valida que la transacción tenga todos los campos requeridos.
    """
    required_fields = ["TransactionID", "TransactionDT", "TransactionAmt", "card_id"]
    
    for field in required_fields:
        if field not in transaction:
            logger.warning(f"Campo requerido faltante: {field}")
            return False
    
    # Validar tipos de datos
    if not isinstance(transaction.get("TransactionAmt"), (int, float)):
        logger.warning("TransactionAmt no es un número")
        return False
    
    return True

def process_transaction(transaction):
    """
    Procesa una transacción y detecta posibles fraudes.
    """
    # Extraer información relevante
    transaction_id = transaction["TransactionID"]
    card_id = transaction["card_id"]
    transaction_amount = float(transaction["TransactionAmt"])
    transaction_dt = int(transaction["TransactionDT"])
    transaction_date = datetime.fromtimestamp(transaction_dt).strftime("%Y-%m-%d")
    
    # Inicializar resultado
    result = {
        "transaction_id": transaction_id,
        "card_id": card_id,
        "transaction_date": transaction_date,
        "fraud_detected": False,
        "fraud_score": 0.0,
        "fraud_reasons": []
    }
    
    # Aplicar reglas de detección de fraude
    
    # Regla 1: Monto de transacción alto
    if transaction_amount > AMOUNT_THRESHOLD:
        result["fraud_score"] += 0.3
        result["fraud_reasons"].append(f"Monto alto: ${transaction_amount}")
    
    # Regla 2: Velocidad de transacciones
    recent_transactions = get_recent_transactions(card_id, transaction_date, transaction_dt)
    
    if len(recent_transactions) >= VELOCITY_THRESHOLD:
        result["fraud_score"] += 0.3
        result["fraud_reasons"].append(f"Velocidad alta: {len(recent_transactions)} transacciones en la última hora")
    
    # Regla 3: Ubicación geográfica (si está disponible)
    if "addr1" in transaction and "addr2" in transaction:
        addr1 = float(transaction.get("addr1", 0))
        addr2 = float(transaction.get("addr2", 0))
        
        # Obtener la última ubicación conocida
        last_location = get_last_location(card_id, transaction_date)
        
        if last_location:
            # Calcular distancia (simplificada)
            distance = calculate_distance(addr1, addr2, last_location["addr1"], last_location["addr2"])
            
            if distance > DISTANCE_THRESHOLD:
                result["fraud_score"] += 0.4
                result["fraud_reasons"].append(f"Cambio de ubicación sospechoso: {distance:.2f} unidades")
    
    # Determinar si es fraude basado en el score
    if result["fraud_score"] >= 0.5:
        result["fraud_detected"] = True
    
    # Guardar estadísticas de la tarjeta en DynamoDB
    save_card_stats(card_id, transaction_date, transaction_dt, transaction_amount, result["fraud_detected"])
    
    return result

def get_recent_transactions(card_id, transaction_date, transaction_dt):
    """
    Obtiene las transacciones recientes para una tarjeta en una ventana de tiempo.
    """
    try:
        # Calcular el timestamp de inicio de la ventana
        start_time = transaction_dt - TIME_WINDOW
        
        # Consultar DynamoDB
        response = card_stats_table.query(
            KeyConditionExpression="card_id = :card_id AND transaction_timestamp > :start_time",
            ExpressionAttributeValues={
                ":card_id": card_id,
                ":start_time": start_time
            }
        )
        
        return response.get("Items", [])
    
    except Exception as e:
        logger.error(f"Error obteniendo transacciones recientes: {str(e)}")
        return []

def get_last_location(card_id, transaction_date):
    """
    Obtiene la última ubicación conocida para una tarjeta.
    """
    try:
        # Consultar DynamoDB
        response = card_stats_table.query(
            KeyConditionExpression="card_id = :card_id",
            ExpressionAttributeValues={
                ":card_id": card_id
            },
            Limit=1,
            ScanIndexForward=False  # Ordenar por timestamp descendente
        )
        
        items = response.get("Items", [])
        
        if items:
            return items[0]
        
        return None
    
    except Exception as e:
        logger.error(f"Error obteniendo última ubicación: {str(e)}")
        return None

def calculate_distance(addr1_a, addr2_a, addr1_b, addr2_b):
    """
    Calcula una distancia simplificada entre dos puntos.
    """
    # Distancia euclidiana simple
    return np.sqrt((addr1_a - addr1_b)**2 + (addr2_a - addr2_b)**2)

def save_card_stats(card_id, transaction_date, transaction_dt, transaction_amount, is_fraud):
    """
    Guarda estadísticas de la tarjeta en DynamoDB.
    """
    try:
        # Crear un ID único para la entrada
        entry_id = str(uuid.uuid4())
        
        # Preparar el ítem para DynamoDB
        item = {
            "card_id": card_id,
            "transaction_date": transaction_date,
            "transaction_timestamp": transaction_dt,
            "transaction_amount": Decimal(str(transaction_amount)),
            "is_fraud": 1 if is_fraud else 0,
            "entry_id": entry_id,
            "ttl": int(time.time()) + 7 * 24 * 3600  # TTL de 7 días
        }
        
        # Guardar en DynamoDB
        card_stats_table.put_item(Item=item)
        
        logger.info(f"Estadísticas guardadas para tarjeta {card_id}")
    
    except Exception as e:
        logger.error(f"Error guardando estadísticas de tarjeta: {str(e)}")

def save_fraud_transaction(transaction, anomalies):
    """
    Guarda la transacción fraudulenta en S3.
    """
    try:
        # Generar nombre de archivo
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        transaction_id = transaction["TransactionID"]
        file_key = f"fraud-transactions/{timestamp}_{transaction_id}.json"
        
        # Combinar transacción y resultado
        data = {
            "transaction": transaction,
            "fraud_analysis": {
                "fraud_detected": True,
                "fraud_score": 0.5,
                "fraud_reasons": anomalies
            },
            "detection_time": datetime.now().isoformat()
        }
        
        # Guardar en S3
        s3.put_object(
            Bucket=ANALYTICS_BUCKET,
            Key=file_key,
            Body=json.dumps(data, indent=2, default=str),
            ContentType="application/json"
        )
        
        logger.info(f"Transacción fraudulenta guardada en s3://{ANALYTICS_BUCKET}/{file_key}")
    
    except Exception as e:
        logger.error(f"Error guardando transacción fraudulenta: {str(e)}")

def send_fraud_alert(transaction, anomalies):
    """
    Envía una alerta de fraude a través de SNS.
    """
    try:
        # Preparar el mensaje
        subject = f"ALERTA DE FRAUDE - Tarjeta {transaction['card_id']}"
        
        message = f"""
        ALERTA DE FRAUDE DETECTADO
        
        Transacción ID: {transaction['TransactionID']}
        Tarjeta: {transaction['card_id']}
        Monto: ${transaction['TransactionAmt']}
        Fecha: {datetime.fromtimestamp(transaction['TransactionDT']).strftime('%Y-%m-%d %H:%M:%S')}
        
        Razones:
        {chr(10).join(['- ' + reason for reason in anomalies])}
        
        Esta alerta fue generada automáticamente por el sistema de detección de fraude en tiempo real.
        """
        
        # Enviar mensaje
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        
        logger.info(f"Alerta de fraude enviada para la transacción {transaction['TransactionID']}")
    
    except Exception as e:
        logger.error(f"Error enviando alerta de fraude: {str(e)}") 