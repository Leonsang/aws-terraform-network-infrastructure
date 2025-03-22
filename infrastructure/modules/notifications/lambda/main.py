import os
import json
import boto3
import requests
from datetime import datetime

def send_slack_notification(webhook_url, message):
    """Envía notificación a Slack."""
    try:
        payload = {
            "text": message,
            "username": "Fraud Detection Bot",
            "icon_emoji": ":warning:"
        }
        response = requests.post(webhook_url, json=payload)
        response.raise_for_status()
        return True
    except Exception as e:
        print(f"Error enviando notificación a Slack: {str(e)}")
        return False

def send_email_notification(topic_arn, subject, message):
    """Envía notificación por email usando SNS."""
    try:
        sns = boto3.client('sns')
        sns.publish(
            TopicArn=topic_arn,
            Subject=subject,
            Message=message
        )
        return True
    except Exception as e:
        print(f"Error enviando notificación por email: {str(e)}")
        return False

def format_message(event_type, details):
    """Formatea el mensaje de notificación."""
    environment = os.environ.get('ENVIRONMENT', 'unknown')
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    message = f"[{environment.upper()}] {event_type} - {timestamp}\n\n"
    
    if event_type == "FRAUD_DETECTED":
        message += (
            f"🚨 Fraude Detectado\n"
            f"Transaction ID: {details.get('transaction_id')}\n"
            f"Amount: ${details.get('amount')}\n"
            f"Risk Score: {details.get('risk_score')}\n"
            f"Customer ID: {details.get('customer_id')}\n"
            f"Merchant: {details.get('merchant_category')}"
        )
    elif event_type == "MODEL_DRIFT":
        message += (
            f"📊 Drift Detectado en el Modelo\n"
            f"Drift Score: {details.get('drift_score')}\n"
            f"Feature: {details.get('feature')}\n"
            f"Threshold: {details.get('threshold')}"
        )
    elif event_type == "RETRAINING_STARTED":
        message += (
            f"🔄 Reentrenamiento Iniciado\n"
            f"Job ID: {details.get('job_id')}\n"
            f"Dataset Size: {details.get('dataset_size')}\n"
            f"Previous Model Version: {details.get('previous_version')}"
        )
    elif event_type == "HIGH_RISK_PATTERN":
        message += (
            f"⚠️ Patrón de Alto Riesgo Detectado\n"
            f"Pattern Type: {details.get('pattern_type')}\n"
            f"Frequency: {details.get('frequency')}\n"
            f"Time Window: {details.get('time_window')}"
        )
    
    return message

def lambda_handler(event, context):
    """Manejador principal de la función Lambda."""
    try:
        # Obtener variables de entorno
        slack_webhook_url = os.environ['SLACK_WEBHOOK_URL']
        email_topic_arn = os.environ['EMAIL_TOPIC_ARN']
        
        # Procesar el evento
        event_body = json.loads(event['Records'][0]['Sns']['Message'])
        event_type = event_body.get('event_type')
        details = event_body.get('details', {})
        
        # Formatear mensaje
        message = format_message(event_type, details)
        
        # Enviar notificaciones
        slack_sent = send_slack_notification(slack_webhook_url, message)
        email_sent = send_email_notification(
            email_topic_arn,
            f"[Fraud Detection] {event_type}",
            message
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'slack_notification_sent': slack_sent,
                'email_notification_sent': email_sent
            })
        }
        
    except Exception as e:
        print(f"Error procesando notificación: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        } 