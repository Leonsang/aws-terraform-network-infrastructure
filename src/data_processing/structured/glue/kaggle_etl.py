import sys
import os
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import *
from pyspark.sql.types import *
import kaggle
from kaggle.api.kaggle_api_extended import KaggleApi
import boto3

def download_kaggle_dataset():
    """Descarga el dataset de fraude de Kaggle"""
    try:
        # Inicializar la API de Kaggle
        api = KaggleApi()
        api.authenticate()
        
        # Crear directorio temporal para los datos
        os.makedirs('/tmp/raw', exist_ok=True)
        
        # Descargar el dataset
        api.dataset_download_files(
            'mlg-ulb/creditcardfraud',
            path='/tmp/raw',
            unzip=True
        )
        
        # Subir al bucket S3
        s3_client = boto3.client('s3')
        s3_client.upload_file(
            '/tmp/raw/creditcard.csv',
            'terraform-aws-dev-raw',
            'data/creditcard.csv'
        )
        
        print("Dataset descargado y subido exitosamente")
        return True
    except Exception as e:
        print(f"Error descargando dataset: {str(e)}")
        return False

def process_data(glueContext, input_path, output_path):
    """Procesa los datos del dataset"""
    try:
        # Leer datos
        dynamic_frame = glueContext.create_dynamic_frame.from_options(
            connection_type="s3",
            connection_options={"paths": [input_path]},
            format="csv",
            format_options={
                "withHeader": True,
                "separator": ","
            }
        )
        
        # Convertir a DataFrame
        df = dynamic_frame.toDF()
        
        # Limpieza básica
        df = df.dropDuplicates()
        df = df.na.fill(0)
        
        # Agregar metadatos de procesamiento
        df = df.withColumn("processed_at", current_timestamp())
        df = df.withColumn("processing_job", lit("kaggle_etl"))
        
        # Convertir de vuelta a DynamicFrame
        processed_frame = DynamicFrame.fromDF(df, glueContext, "processed_data")
        
        # Escribir datos procesados
        glueContext.write_dynamic_frame.from_options(
            frame=processed_frame,
            connection_type="s3",
            connection_options={"path": output_path},
            format="parquet"
        )
        
        print("Procesamiento completado exitosamente")
        return True
    except Exception as e:
        print(f"Error procesando datos: {str(e)}")
        return False

def main():
    # Inicializar contexto de Glue
    args = getResolvedOptions(sys.argv, ['JOB_NAME', 'input_path', 'output_path'])
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)
    
    try:
        # Descargar dataset de Kaggle
        if not download_kaggle_dataset():
            raise Exception("Error en la descarga del dataset")
        
        # Procesar datos
        if not process_data(glueContext, args['input_path'], args['output_path']):
            raise Exception("Error en el procesamiento de datos")
        
        print("ETL completado exitosamente")
        
    except Exception as e:
        print(f"Error en el proceso ETL: {str(e)}")
        raise e
    
    finally:
        job.commit()

if __name__ == "__main__":
    main() 