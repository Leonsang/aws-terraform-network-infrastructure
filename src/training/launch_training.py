import boto3
import json
import time
from datetime import datetime

def launch_training_job(
    role_arn,
    image_uri,
    feature_store_bucket,
    model_artifacts_bucket,
    instance_type='ml.m5.xlarge',
    instance_count=1,
    hyperparameters=None
):
    """Lanza un trabajo de entrenamiento en SageMaker."""
    
    sagemaker = boto3.client('sagemaker')
    
    # Nombre único para el trabajo
    job_name = f"fraud-detection-training-{int(time.time())}"
    
    # Hiperparámetros por defecto si no se proporcionan
    if hyperparameters is None:
        hyperparameters = {
            'n_estimators': '100',
            'learning_rate': '0.1',
            'max_depth': '7',
            'num_leaves': '31'
        }
    
    # Configurar el trabajo de entrenamiento
    training_params = {
        'JobName': job_name,
        'AlgorithmSpecification': {
            'TrainingImage': image_uri,
            'TrainingInputMode': 'File'
        },
        'RoleArn': role_arn,
        'InputDataConfig': [
            {
                'ChannelName': 'training',
                'DataSource': {
                    'S3DataSource': {
                        'S3DataType': 'S3Prefix',
                        'S3Uri': f's3://{feature_store_bucket}/features/',
                        'S3DataDistributionType': 'FullyReplicated'
                    }
                }
            }
        ],
        'OutputDataConfig': {
            'S3OutputPath': f's3://{model_artifacts_bucket}/models/'
        },
        'ResourceConfig': {
            'InstanceType': instance_type,
            'InstanceCount': instance_count,
            'VolumeSizeInGB': 30
        },
        'HyperParameters': hyperparameters,
        'StoppingCondition': {
            'MaxRuntimeInSeconds': 86400  # 24 horas
        },
        'Tags': [
            {
                'Key': 'Project',
                'Value': 'fraud-detection'
            }
        ]
    }
    
    # Lanzar el trabajo
    response = sagemaker.create_training_job(**training_params)
    
    print(f"Trabajo de entrenamiento lanzado: {job_name}")
    return job_name

def wait_for_training(job_name):
    """Espera a que el trabajo de entrenamiento termine."""
    
    sagemaker = boto3.client('sagemaker')
    
    while True:
        response = sagemaker.describe_training_job(TrainingJobName=job_name)
        status = response['TrainingJobStatus']
        
        if status == 'Completed':
            print(f"Entrenamiento completado exitosamente")
            break
        elif status in ['Failed', 'Stopped']:
            print(f"Entrenamiento fallido o detenido: {response.get('FailureReason', 'No hay razón disponible')}")
            break
        
        print(f"Estado actual: {status}")
        time.sleep(60)  # Esperar 1 minuto antes de verificar de nuevo

if __name__ == '__main__':
    # Estos valores deberían venir de variables de entorno o argumentos
    config = {
        'role_arn': 'arn:aws:iam::ACCOUNT_ID:role/fraud-detection-sagemaker-role',
        'image_uri': 'ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/fraud-detection-training:latest',
        'feature_store_bucket': 'feature-store-bucket-name',
        'model_artifacts_bucket': 'model-artifacts-bucket-name',
        'instance_type': 'ml.m5.xlarge',
        'instance_count': 1,
        'hyperparameters': {
            'n_estimators': '100',
            'learning_rate': '0.1',
            'max_depth': '7',
            'num_leaves': '31'
        }
    }
    
    # Lanzar entrenamiento
    job_name = launch_training_job(**config)
    
    # Esperar a que termine
    wait_for_training(job_name) 