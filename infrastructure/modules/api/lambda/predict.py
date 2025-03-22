import json
import boto3
import os

runtime = boto3.client('runtime.sagemaker')
endpoint_name = os.environ['SAGEMAKER_ENDPOINT']

def lambda_handler(event, context):
    try:
        # Obtener el cuerpo de la solicitud
        body = json.loads(event['body'])
        
        # Validar el formato de los datos
        if not validate_input(body):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Formato de datos inválido'
                })
            }
        
        # Invocar el endpoint de SageMaker
        response = runtime.invoke_endpoint(
            EndpointName=endpoint_name,
            ContentType='application/json',
            Body=json.dumps(body)
        )
        
        # Procesar la respuesta
        result = json.loads(response['Body'].read().decode())
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Error interno del servidor'
            })
        }

def validate_input(data):
    required_fields = ['transaction_amount', 'merchant_id', 'card_number']
    return all(field in data for field in required_fields) 