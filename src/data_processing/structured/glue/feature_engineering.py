import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import *
from pyspark.sql.types import *
from pyspark.sql.window import Window

# Initialize Glue context
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Define paths
processed_path = "s3://terraform-aws-dev-processed/transactions/"
analytics_path = "s3://terraform-aws-dev-analytics/features/"

try:
    # Read processed data
    dynamic_frame = glueContext.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={"paths": [processed_path]},
        format="parquet"
    )
    
    # Convert to DataFrame for feature engineering
    df = dynamic_frame.toDF()
    
    # Add temporal features
    df = df.withColumn("transaction_timestamp", to_timestamp("transaction_date"))
    df = df.withColumn("hour_of_day", hour("transaction_timestamp"))
    df = df.withColumn("day_of_week", dayofweek("transaction_timestamp"))
    df = df.withColumn("month", month("transaction_timestamp"))
    df = df.withColumn("year", year("transaction_timestamp"))
    
    # Calculate aggregated features by card
    card_features = df.groupBy("card_id").agg(
        count("transaction_id").alias("transaction_count"),
        avg("amount").alias("avg_amount"),
        max("amount").alias("max_amount"),
        min("amount").alias("min_amount"),
        stddev("amount").alias("std_amount"),
        countDistinct("merchant_category").alias("unique_merchant_categories"),
        countDistinct("merchant_id").alias("unique_merchants")
    )
    
    # Add time-based features
    time_features = df.groupBy("card_id", "hour_of_day").agg(
        count("transaction_id").alias("transactions_in_hour"),
        avg("amount").alias("avg_amount_in_hour")
    )
    
    # Add merchant category features
    merchant_features = df.groupBy("card_id", "merchant_category").agg(
        count("transaction_id").alias("category_transaction_count"),
        sum("amount").alias("category_total_amount")
    )
    
    # Convert back to DynamicFrame
    features_frame = DynamicFrame.fromDF(card_features, glueContext, "card_features")
    time_features_frame = DynamicFrame.fromDF(time_features, glueContext, "time_features")
    merchant_features_frame = DynamicFrame.fromDF(merchant_features, glueContext, "merchant_features")
    
    # Write features to analytics bucket
    glueContext.write_dynamic_frame.from_options(
        frame=features_frame,
        connection_type="s3",
        connection_options={"path": f"{analytics_path}card_features/"},
        format="parquet"
    )
    
    glueContext.write_dynamic_frame.from_options(
        frame=time_features_frame,
        connection_type="s3",
        connection_options={"path": f"{analytics_path}time_features/"},
        format="parquet"
    )
    
    glueContext.write_dynamic_frame.from_options(
        frame=merchant_features_frame,
        connection_type="s3",
        connection_options={"path": f"{analytics_path}merchant_features/"},
        format="parquet"
    )
    
    print("Feature engineering completed successfully")
    
except Exception as e:
    print(f"Error in feature engineering: {str(e)}")
    raise e

finally:
    job.commit()