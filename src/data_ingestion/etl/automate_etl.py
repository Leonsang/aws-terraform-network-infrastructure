import os
import sys
import boto3
import time
from datetime import datetime
from kaggle.api.kaggle_api_extended import KaggleApi
from botocore.exceptions import ClientError
import json
from typing import Dict, Any
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def load_kaggle_credentials() -> Dict[str, str]:
    """Carga las credenciales de Kaggle desde el archivo de configuración"""
    try:
        with open('src/config/kaggle.json', 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error al cargar credenciales de Kaggle: {str(e)}")
        raise

class ETLOrchestrator:
    def __init__(self, project_name: str, environment: str, region: str):
        self.project_name = project_name
        self.environment = environment
        self.region = region
        
        # Inicializar clientes AWS
        self.s3_client = boto3.client('s3')
        self.glue_client = boto3.client('glue')
        self.stepfunctions_client = boto3.client('stepfunctions')
        self.athena_client = boto3.client('athena')
        
        # Configurar nombres de recursos
        self.workgroup_name = f"{project_name}-{environment}-workgroup"
        self.database_name = f"{project_name}_{environment}"
        
        # Configuración
        self.raw_bucket = f"{self.project_name}-{self.environment}-raw"
        self.processed_bucket = f"{self.project_name}-{self.environment}-processed"
        self.feature_bucket = f"{self.project_name}-{self.environment}-feature-store"
        self.scripts_bucket = f"{self.project_name}-{self.environment}-scripts"
        
    def download_kaggle_dataset(self) -> Dict[str, Any]:
        """Descarga el dataset de Kaggle"""
        try:
            # Cargar credenciales de Kaggle
            credentials = load_kaggle_credentials()
            
            # Configurar credenciales de Kaggle
            os.environ['KAGGLE_USERNAME'] = credentials['username']
            os.environ['KAGGLE_KEY'] = credentials['key']
            
            # Inicializar API de Kaggle
            kaggle_api = KaggleApi()
            kaggle_api.authenticate()

            # Descargar dataset
            kaggle_api.dataset_download_files(
                'mlg-ulb/creditcardfraud',
                path='data/raw',
                unzip=True
            )

            # Subir a S3
            self.s3_client.upload_file(
                'data/raw/creditcard.csv',
                self.raw_bucket,
                'raw/creditcardfraud/creditcard.csv'
            )

            return {
                'status': 'success',
                'message': 'Dataset descargado y subido a S3',
                'timestamp': datetime.utcnow().isoformat()
            }

        except Exception as e:
            logger.error(f"Error al descargar dataset: {str(e)}")
            return {
                'status': 'error',
                'message': str(e),
                'timestamp': datetime.utcnow().isoformat()
            }

    def upload_scripts(self) -> Dict[str, Any]:
        """Sube los scripts de ETL a S3"""
        try:
            # Subir scripts de Glue
            self.s3_client.upload_file(
                'src/data_processing/glue/raw_processing.py',
                self.scripts_bucket,
                'glue/raw_processing.py'
            )

            return {
                'status': 'success',
                'message': 'Scripts subidos a S3',
                'timestamp': datetime.utcnow().isoformat()
            }

        except Exception as e:
            logger.error(f"Error al subir scripts: {str(e)}")
            return {
                'status': 'error',
                'message': str(e),
                'timestamp': datetime.utcnow().isoformat()
            }

    def start_glue_job(self, job_name: str) -> Dict[str, Any]:
        """Inicia el job de Glue"""
        try:
            response = self.glue_client.start_job_run(
                JobName=job_name,
                Arguments={
                    '--job-language': 'python',
                    '--TempDir': f's3://{self.raw_bucket}/temp/',
                    '--job-bookmark-option': 'job-bookmark-enable'
                }
            )

            return {
                'status': 'success',
                'message': 'Glue job iniciado',
                'job_run_id': response['JobRunId'],
                'timestamp': datetime.utcnow().isoformat()
            }

        except Exception as e:
            logger.error(f"Error al iniciar job de Glue: {str(e)}")
            return {
                'status': 'error',
                'message': str(e),
                'timestamp': datetime.utcnow().isoformat()
            }

    def execute_athena_query(self, query: str) -> Dict[str, Any]:
        """Ejecuta una consulta en Athena"""
        try:
            # Iniciar la consulta
            response = self.athena_client.start_query_execution(
                QueryString=query,
                QueryExecutionContext={
                    'Database': self.database_name
                },
                WorkGroup=self.workgroup_name
            )
            
            query_execution_id = response['QueryExecutionId']
            
            # Esperar a que la consulta termine
            while True:
                query_status = self.athena_client.get_query_execution(
                    QueryExecutionId=query_execution_id
                )
                state = query_status['QueryExecution']['Status']['State']
                
                if state in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
                    break
                    
                time.sleep(1)
            
            # Obtener resultados
            if state == 'SUCCEEDED':
                results = self.athena_client.get_query_results(
                    QueryExecutionId=query_execution_id
                )
                return {"status": "success", "results": results}
            else:
                error_message = query_status['QueryExecution']['Status'].get('StateChangeReason', 'Unknown error')
                return {"status": "error", "message": error_message}
                
        except Exception as e:
            logger.error(f"Error al ejecutar consulta en Athena: {str(e)}")
            return {"status": "error", "message": str(e)}

    def sync_to_athena(self) -> Dict[str, Any]:
        """Sincroniza los datos con Athena"""
        try:
            # Verificar que las tablas existan
            tables_query = f"""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = '{self.database_name}'
            """
            tables_result = self.execute_athena_query(tables_query)
            
            if tables_result["status"] == "error":
                return tables_result
                
            existing_tables = [row['Data'][0]['VarCharValue'] for row in tables_result["results"]["ResultSet"]["Rows"][1:]]
            
            # Crear tablas si no existen
            if "transactions" not in existing_tables:
                create_transactions_query = f"""
                CREATE EXTERNAL TABLE IF NOT EXISTS transactions (
                    transaction_id STRING,
                    timestamp TIMESTAMP,
                    amount DOUBLE,
                    merchant_id STRING,
                    card_number STRING,
                    is_fraud BOOLEAN
                )
                STORED AS PARQUET
                LOCATION 's3://{self.project_name}-{self.environment}-processed/transactions/'
                """
                result = self.execute_athena_query(create_transactions_query)
                if result["status"] == "error":
                    return result
            
            if "merchants" not in existing_tables:
                create_merchants_query = f"""
                CREATE EXTERNAL TABLE IF NOT EXISTS merchants (
                    merchant_id STRING,
                    merchant_name STRING,
                    category STRING,
                    location STRING
                )
                STORED AS PARQUET
                LOCATION 's3://{self.project_name}-{self.environment}-processed/merchants/'
                """
                result = self.execute_athena_query(create_merchants_query)
                if result["status"] == "error":
                    return result
            
            if "fraud_analysis" not in existing_tables:
                create_fraud_query = f"""
                CREATE EXTERNAL TABLE IF NOT EXISTS fraud_analysis (
                    analysis_id STRING,
                    transaction_id STRING,
                    risk_score DOUBLE,
                    model_version STRING,
                    features_used STRING
                )
                STORED AS PARQUET
                LOCATION 's3://{self.project_name}-{self.environment}-processed/fraud_analysis/'
                """
                result = self.execute_athena_query(create_fraud_query)
                if result["status"] == "error":
                    return result
            
            # Crear vista de métricas si no existe
            create_metrics_view_query = """
            CREATE OR REPLACE VIEW fraud_metrics AS
            SELECT 
                DATE(timestamp) as date,
                COUNT(*) as total_transactions,
                SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) as fraud_count,
                AVG(CASE WHEN is_fraud THEN amount ELSE 0 END) as avg_fraud_amount
            FROM transactions
            GROUP BY DATE(timestamp)
            """
            result = self.execute_athena_query(create_metrics_view_query)
            if result["status"] == "error":
                return result
            
            return {"status": "success", "message": "Datos sincronizados exitosamente con Athena"}
            
        except Exception as e:
            logger.error(f"Error al sincronizar con Athena: {str(e)}")
            return {"status": "error", "message": str(e)}

    def start_step_function(self) -> Dict[str, Any]:
        """Inicia la Step Function de orquestación"""
        try:
            state_machine_arn = f"arn:aws:states:{self.region}:{os.getenv('AWS_ACCOUNT_ID')}:stateMachine:{self.project_name}-{self.environment}-etl"
            response = self.stepfunctions_client.start_execution(
                stateMachineArn=state_machine_arn
            )
            return {"status": "success", "execution_arn": response['executionArn']}
        except Exception as e:
            logger.error(f"Error al iniciar Step Function: {str(e)}")
            return {"status": "error", "message": str(e)}

    def run_pipeline(self) -> Dict[str, Any]:
        """Ejecuta el pipeline completo de ETL"""
        try:
            # 1. Descargar dataset
            download_result = self.download_kaggle_dataset()
            if download_result["status"] == "error":
                return download_result
            
            # 2. Subir scripts
            upload_result = self.upload_scripts()
            if upload_result["status"] == "error":
                return upload_result
            
            # 3. Iniciar Step Function
            step_function_result = self.start_step_function()
            if step_function_result["status"] == "error":
                return step_function_result
            
            # 4. Sincronizar con Athena
            sync_result = self.sync_to_athena()
            if sync_result["status"] == "error":
                return sync_result
            
            return {
                "status": "success",
                "message": "Pipeline ejecutado exitosamente",
                "execution_arn": step_function_result["execution_arn"]
            }
            
        except Exception as e:
            logger.error(f"Error en el pipeline: {str(e)}")
            return {"status": "error", "message": str(e)}

def main():
    # Obtener variables de entorno
    project_name = os.getenv('PROJECT_NAME', 'terraform-aws')
    environment = os.getenv('ENVIRONMENT', 'dev')
    region = os.getenv('AWS_REGION', 'us-east-1')
    
    # Crear orquestador
    orchestrator = ETLOrchestrator(project_name, environment, region)
    
    try:
        # Ejecutar pipeline
        result = orchestrator.run_pipeline()
        
        if result['status'] == 'success':
            logger.info("Pipeline ejecutado exitosamente")
        else:
            logger.error(f"Error en el pipeline: {result['message']}")
            
    except Exception as e:
        logger.error(f"Error en el pipeline: {str(e)}")

if __name__ == "__main__":
    main() 