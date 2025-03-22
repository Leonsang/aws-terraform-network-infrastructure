import os
import json
import boto3
import numpy as np
import pandas as pd
from datetime import datetime
from botocore.exceptions import ClientError
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
import requests

def load_test_data(s3_client, test_data_location):
    """Carga los datos de prueba desde S3."""
    try:
        bucket = test_data_location.split('/')[2]
        key = '/'.join(test_data_location.split('/')[3:])
        response = s3_client.get_object(Bucket=bucket, Key=key)
        df = pd.read_csv(response['Body'])
        return df
    except ClientError as e:
        print(f"Error cargando datos de prueba: {str(e)}")
        raise

def test_model_endpoint(sagemaker_client, endpoint_name, test_data):
    """Prueba el endpoint del modelo con datos de prueba."""
    predictions = []
    errors = 0
    latencies = []

    try:
        for _, row in test_data.iterrows():
            # Preparar datos para la predicción
            payload = {
                "transaction_data": {
                    "amount": float(row['amount']),
                    "merchant_category": str(row['merchant_category']),
                    "customer_id": str(row['customer_id']),
                    "timestamp": str(row['timestamp'])
                }
            }

            # Invocar endpoint
            start_time = datetime.now()
            response = sagemaker_client.invoke_endpoint(
                EndpointName=endpoint_name,
                ContentType='application/json',
                Body=json.dumps(payload)
            )
            end_time = datetime.now()

            # Procesar respuesta
            result = json.loads(response['Body'].read().decode())
            predictions.append(result['prediction'])
            latencies.append((end_time - start_time).total_seconds())

    except Exception as e:
        print(f"Error en predicción: {str(e)}")
        errors += 1

    return predictions, errors, latencies

def test_api_endpoint(api_url, test_data):
    """Prueba el endpoint de la API con datos de prueba."""
    predictions = []
    errors = 0
    latencies = []

    try:
        for _, row in test_data.iterrows():
            # Preparar datos para la predicción
            payload = {
                "transaction_data": {
                    "amount": float(row['amount']),
                    "merchant_category": str(row['merchant_category']),
                    "customer_id": str(row['customer_id']),
                    "timestamp": str(row['timestamp'])
                }
            }

            # Hacer request
            start_time = datetime.now()
            response = requests.post(api_url, json=payload)
            end_time = datetime.now()

            if response.status_code == 200:
                result = response.json()
                predictions.append(result['prediction'])
                latencies.append((end_time - start_time).total_seconds())
            else:
                errors += 1

    except Exception as e:
        print(f"Error en request API: {str(e)}")
        errors += 1

    return predictions, errors, latencies

def calculate_metrics(y_true, y_pred):
    """Calcula métricas de calidad del modelo."""
    return {
        'accuracy': float(accuracy_score(y_true, y_pred)),
        'precision': float(precision_score(y_true, y_pred)),
        'recall': float(recall_score(y_true, y_pred)),
        'f1': float(f1_score(y_true, y_pred))
    }

def publish_metrics(cloudwatch, project_name, environment, metrics, api_metrics):
    """Publica métricas en CloudWatch."""
    try:
        # Métricas del modelo
        cloudwatch.put_metric_data(
            Namespace=f"{project_name}/ModelQuality",
            MetricData=[
                {
                    'MetricName': 'Accuracy',
                    'Value': metrics['accuracy'],
                    'Unit': 'None',
                    'Dimensions': [{'Name': 'Environment', 'Value': environment}]
                },
                {
                    'MetricName': 'Precision',
                    'Value': metrics['precision'],
                    'Unit': 'None',
                    'Dimensions': [{'Name': 'Environment', 'Value': environment}]
                },
                {
                    'MetricName': 'Recall',
                    'Value': metrics['recall'],
                    'Unit': 'None',
                    'Dimensions': [{'Name': 'Environment', 'Value': environment}]
                },
                {
                    'MetricName': 'F1Score',
                    'Value': metrics['f1'],
                    'Unit': 'None',
                    'Dimensions': [{'Name': 'Environment', 'Value': environment}]
                }
            ]
        )

        # Métricas de la API
        cloudwatch.put_metric_data(
            Namespace=f"{project_name}/APIQuality",
            MetricData=[
                {
                    'MetricName': 'Latency',
                    'Value': api_metrics['avg_latency'],
                    'Unit': 'Seconds',
                    'Dimensions': [{'Name': 'Environment', 'Value': environment}]
                },
                {
                    'MetricName': 'ErrorRate',
                    'Value': api_metrics['error_rate'],
                    'Unit': 'None',
                    'Dimensions': [{'Name': 'Environment', 'Value': environment}]
                }
            ]
        )
    except ClientError as e:
        print(f"Error publicando métricas: {str(e)}")
        raise

def save_test_results(s3_client, bucket, metrics, api_metrics):
    """Guarda los resultados de las pruebas en S3."""
    try:
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        results = {
            'timestamp': timestamp,
            'model_metrics': metrics,
            'api_metrics': api_metrics
        }
        
        key = f'results/test-results-{timestamp}.json'
        s3_client.put_object(
            Bucket=bucket,
            Key=key,
            Body=json.dumps(results, indent=2),
            ContentType='application/json'
        )
        
        return key
    except ClientError as e:
        print(f"Error guardando resultados: {str(e)}")
        raise

def check_thresholds(metrics, thresholds):
    """Verifica si las métricas cumplen con los umbrales establecidos."""
    return {
        'accuracy': metrics['accuracy'] >= float(thresholds['accuracy']),
        'precision': metrics['precision'] >= float(thresholds['precision']),
        'recall': metrics['recall'] >= float(thresholds['recall']),
        'f1': metrics['f1'] >= float(thresholds['f1'])
    }

def lambda_handler(event, context):
    """Función principal de Lambda."""
    try:
        # Inicializar clientes
        s3 = boto3.client('s3')
        sagemaker = boto3.client('sagemaker-runtime')
        cloudwatch = boto3.client('cloudwatch')
        sns = boto3.client('sns')

        # Obtener variables de entorno
        project_name = os.environ['PROJECT_NAME']
        environment = os.environ['ENVIRONMENT']
        endpoint_name = os.environ['SAGEMAKER_ENDPOINT']
        api_url = os.environ['API_GATEWAY_URL']
        test_data_location = os.environ['TEST_DATA_LOCATION']
        test_bucket = os.environ['TEST_BUCKET']
        topic_arn = os.environ['SNS_TOPIC_ARN']

        thresholds = {
            'accuracy': os.environ['THRESHOLD_ACCURACY'],
            'precision': os.environ['THRESHOLD_PRECISION'],
            'recall': os.environ['THRESHOLD_RECALL'],
            'f1': os.environ['THRESHOLD_F1']
        }

        # Cargar datos de prueba
        test_data = load_test_data(s3, test_data_location)
        y_true = test_data['is_fraud'].values

        # Probar endpoint del modelo
        model_predictions, model_errors, model_latencies = test_model_endpoint(
            sagemaker, endpoint_name, test_data
        )

        # Probar endpoint de la API
        api_predictions, api_errors, api_latencies = test_api_endpoint(
            api_url, test_data
        )

        # Calcular métricas
        model_metrics = calculate_metrics(y_true, model_predictions)
        threshold_results = check_thresholds(model_metrics, thresholds)

        api_metrics = {
            'avg_latency': np.mean(api_latencies),
            'error_rate': api_errors / len(test_data)
        }

        # Publicar métricas
        publish_metrics(cloudwatch, project_name, environment, model_metrics, api_metrics)

        # Guardar resultados
        results_key = save_test_results(s3, test_bucket, model_metrics, api_metrics)

        # Verificar umbrales y notificar
        failed_thresholds = [k for k, v in threshold_results.items() if not v]
        if failed_thresholds:
            message = f"""⚠️ Alerta de Calidad del Modelo
Ambiente: {environment}
Las siguientes métricas están por debajo del umbral:
"""
            for metric in failed_thresholds:
                message += f"- {metric}: {model_metrics[metric]} (umbral: {thresholds[metric]})\n"

            sns.publish(
                TopicArn=topic_arn,
                Subject=f"[{project_name}] Alerta de Calidad del Modelo",
                Message=message
            )

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Pruebas completadas exitosamente',
                'results_file': results_key,
                'metrics': model_metrics,
                'api_metrics': api_metrics,
                'thresholds_passed': all(threshold_results.values())
            })
        }

    except Exception as e:
        error_message = f"Error ejecutando pruebas: {str(e)}"
        print(error_message)

        # Notificar error
        sns.publish(
            TopicArn=topic_arn,
            Subject=f"[{project_name}] Error en Pruebas de Calidad",
            Message=error_message
        )

        raise 