import sys
import logging
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql.functions import col, to_timestamp, when
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, TimestampType

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Obtener argumentos del job
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'input_path', 'output_path', 'environment'])

# Inicializar contexto de Glue
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Inicializar job
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

try:
    # Definir esquema de datos
    schema = StructType([
        StructField("transaction_id", StringType(), True),
        StructField("timestamp", TimestampType(), True),
        StructField("amount", DoubleType(), True),
        StructField("merchant_id", StringType(), True),
        StructField("customer_id", StringType(), True),
        StructField("is_fraud", DoubleType(), True)
    ])

    # Leer datos raw
    logger.info(f"Leyendo datos de: {args['input_path']}")
    df = spark.read.csv(
        args['input_path'],
        header=True,
        schema=schema,
        inferSchema=False
    )

    # Transformaciones básicas
    df = df.withColumn("timestamp", to_timestamp(col("timestamp")))
    df = df.withColumn("is_fraud", when(col("is_fraud") == 1, 1.0).otherwise(0.0))

    # Validaciones básicas
    df = df.filter(col("amount").isNotNull())
    df = df.filter(col("amount") > 0)

    # Guardar datos procesados
    logger.info(f"Guardando datos procesados en: {args['output_path']}")
    df.write.mode("overwrite").parquet(args['output_path'])

    # Log de estadísticas
    logger.info(f"Total de registros procesados: {df.count()}")
    logger.info(f"Total de fraudes detectados: {df.filter(col('is_fraud') == 1.0).count()}")

    job.commit()
    logger.info("Job completado exitosamente")

except Exception as e:
    logger.error(f"Error en el procesamiento: {str(e)}")
    raise e 