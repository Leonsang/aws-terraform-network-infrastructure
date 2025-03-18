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
from pyspark.ml.classification import RandomForestClassifier
from pyspark.ml.evaluation import BinaryClassificationEvaluator
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
    StructField("card_id", StringType(), True),
    StructField("merchant_id", StringType(), True),
    StructField("amount", DoubleType(), True),
    StructField("timestamp", TimestampType(), True),
    StructField("location", StringType(), True),
    StructField("merchant_category", StringType(), True),
    StructField("is_fraud", BooleanType(), True)
])

# Leer datos crudos
raw_path = f"s3://{args['raw_bucket']}/data/transactions/"
raw_df = spark.read.schema(transaction_schema).parquet(raw_path)

# Limpieza y validación de datos
cleaned_df = raw_df.dropna(how='any')  # Eliminar filas con valores nulos
cleaned_df = cleaned_df.filter(col("amount") > 0)  # Filtrar montos válidos

# Enriquecimiento de datos
enriched_df = cleaned_df \
    .withColumn("transaction_date", to_date(col("timestamp"))) \
    .withColumn("transaction_hour", hour(col("timestamp"))) \
    .withColumn("transaction_day", dayofweek(col("timestamp"))) \
    .withColumn("transaction_month", month(col("timestamp"))) \
    .withColumn("transaction_year", year(col("timestamp")))

# Calcular estadísticas por tarjeta
card_stats = enriched_df \
    .groupBy("card_id", "transaction_date") \
    .agg(
        count("transaction_id").alias("daily_transactions"),
        sum("amount").alias("daily_amount"),
        sum(when(col("is_fraud"), 1).otherwise(0)).alias("fraud_count")
    )

# Calcular estadísticas por comerciante
merchant_stats = enriched_df \
    .groupBy("merchant_id", "merchant_category", "transaction_date") \
    .agg(
        count("transaction_id").alias("daily_transactions"),
        sum("amount").alias("daily_amount"),
        sum(when(col("is_fraud"), 1).otherwise(0)).alias("fraud_count"),
        (sum(when(col("is_fraud"), 1).otherwise(0)) / count("transaction_id")).alias("fraud_rate")
    )

# Guardar datos procesados
processed_path = f"s3://{args['processed_bucket']}/data/transactions/"
analytics_path = f"s3://{args['analytics_bucket']}/data/"

enriched_df.write \
    .mode("overwrite") \
    .partitionBy("transaction_year", "transaction_month") \
    .parquet(processed_path)

card_stats.write \
    .mode("overwrite") \
    .partitionBy("transaction_date") \
    .parquet(f"{analytics_path}card_stats/")

merchant_stats.write \
    .mode("overwrite") \
    .partitionBy("transaction_date") \
    .parquet(f"{analytics_path}merchant_stats/")

# Registrar tablas en el catálogo
database = args['database_name']

# Registrar tabla de transacciones enriquecidas
enriched_table = "enriched_transactions"
glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"path": processed_path},
    format="parquet"
).toDF().createOrReplaceTempView(enriched_table)

spark.sql(f"""
    CREATE TABLE IF NOT EXISTS {database}.{enriched_table}
    USING PARQUET
    LOCATION '{processed_path}'
    AS SELECT * FROM {enriched_table}
""")

# Registrar tabla de estadísticas de tarjetas
card_stats_table = "card_statistics"
glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"path": f"{analytics_path}card_stats/"},
    format="parquet"
).toDF().createOrReplaceTempView(card_stats_table)

spark.sql(f"""
    CREATE TABLE IF NOT EXISTS {database}.{card_stats_table}
    USING PARQUET
    LOCATION '{analytics_path}card_stats/'
    AS SELECT * FROM {card_stats_table}
""")

# Registrar tabla de estadísticas de comerciantes
merchant_stats_table = "merchant_statistics"
glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"path": f"{analytics_path}merchant_stats/"},
    format="parquet"
).toDF().createOrReplaceTempView(merchant_stats_table)

spark.sql(f"""
    CREATE TABLE IF NOT EXISTS {database}.{merchant_stats_table}
    USING PARQUET
    LOCATION '{analytics_path}merchant_stats/'
    AS SELECT * FROM {merchant_stats_table}
""")

job.commit() 