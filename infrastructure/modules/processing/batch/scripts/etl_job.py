"""
ETL Job para el proyecto de Detección de Fraude Financiero
Este script procesa los datos de transacciones financieras y los prepara para análisis.
"""

import sys
import datetime
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, when, lit, to_date, year, month, dayofmonth, hour, expr, count, sum, dayofweek
from pyspark.ml.feature import VectorAssembler, StandardScaler
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, TimestampType, BooleanType

# Inicializar el contexto de Glue
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'raw_bucket', 'processed_bucket', 'analytics_bucket', 'database_name'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Parámetros
raw_bucket = args['raw_bucket']
processed_bucket = args['processed_bucket']
analytics_bucket = args['analytics_bucket']
database_name = args['database_name']
current_date = datetime.datetime.now().strftime("%Y-%m-%d")

print(f"Iniciando ETL job para detección de fraude financiero - {current_date}")
print(f"Raw bucket: {raw_bucket}")
print(f"Processed bucket: {processed_bucket}")
print(f"Analytics bucket: {analytics_bucket}")
print(f"Database name: {database_name}")

# Definir esquema de datos
transaction_schema = StructType([
    StructField("transaction_id", StringType(), True),
    StructField("timestamp", TimestampType(), True),
    StructField("amount", DoubleType(), True),
    StructField("merchant_id", StringType(), True),
    StructField("card_number", StringType(), True),
    StructField("is_fraud", BooleanType(), True)
])

# Leer datos raw
raw_data = spark.read.schema(transaction_schema).parquet(f"s3://{raw_bucket}/transactions/")

# Extraer características temporales
processed_data = raw_data.withColumn("year", year("timestamp")) \
    .withColumn("month", month("timestamp")) \
    .withColumn("day", dayofmonth("timestamp")) \
    .withColumn("hour", hour("timestamp")) \
    .withColumn("day_of_week", dayofweek("timestamp"))

# Agregar características por tarjeta
card_features = processed_data.groupBy("card_number") \
    .agg(
        count("*").alias("transaction_count"),
        sum("amount").alias("total_amount"),
        sum(when(col("is_fraud"), 1).otherwise(0)).alias("fraud_count")
    )

# Unir características con datos procesados
final_data = processed_data.join(card_features, "card_number", "left")

# Guardar datos procesados
processed_path = f"s3://{processed_bucket}/processed/{current_date}/"
final_data.write.mode("overwrite").parquet(processed_path)

# Calcular métricas para analytics
metrics = final_data.groupBy("year", "month", "day") \
    .agg(
        count("*").alias("total_transactions"),
        sum(when(col("is_fraud"), 1).otherwise(0)).alias("fraud_transactions"),
        sum("amount").alias("total_amount"),
        sum(when(col("is_fraud"), col("amount")).otherwise(0)).alias("fraud_amount")
    )

# Guardar métricas
metrics_path = f"s3://{analytics_bucket}/metrics/{current_date}/"
metrics.write.mode("overwrite").parquet(metrics_path)

# Registrar tablas en el catálogo de Glue
processed_data.write \
    .format("parquet") \
    .mode("overwrite") \
    .saveAsTable(f"{database_name}.processed_transactions")

metrics.write \
    .format("parquet") \
    .mode("overwrite") \
    .saveAsTable(f"{database_name}.daily_metrics")

print("ETL job completado exitosamente")
job.commit() 