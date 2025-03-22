import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['AUTH_TABLE'])

def lambda_handler(event, context):
    try:
        # Obtener el token del header
        auth_header = event.get('authorizationToken', '')
        if not auth_header.startswith('Bearer '):
            return generate_policy('user', 'Deny', event['methodArn'])

        token = auth_header.split(' ')[1]
        
        # Verificar el token en DynamoDB
        response = table.get_item(
            Key={'token': token}
        )
        
        if 'Item' not in response:
            return generate_policy('user', 'Deny', event['methodArn'])
            
        return generate_policy('user', 'Allow', event['methodArn'])
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return generate_policy('user', 'Deny', event['methodArn'])

def generate_policy(principal_id, effect, resource):
    return {
        'principalId': principal_id,
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': resource
                }
            ]
        }
    } 