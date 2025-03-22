import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import *
from pyspark.sql.types import *

# Initialize Glue context
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'input_path', 'output_path'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Get input and output paths from arguments
raw_path = args['input_path']
processed_path = args['output_path']

try:
    # Read raw data
    dynamic_frame = glueContext.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={"paths": [raw_path]},
        format="csv",
        format_options={
            "withHeader": True,
            "separator": ","
        }
    )
    
    # Convert to DataFrame for processing
    df = dynamic_frame.toDF()
    
    # Basic data cleaning and transformations
    df = df.dropDuplicates()
    df = df.na.fill(0)  # Fill numeric nulls with 0
    df = df.na.fill("")  # Fill string nulls with empty string
    
    # Add data quality checks
    df = df.filter(col("amount") > 0)  # Remove negative amounts
    df = df.filter(col("transaction_date").isNotNull())  # Remove null dates
    
    # Add processing metadata
    df = df.withColumn("processed_at", current_timestamp())
    df = df.withColumn("processing_job", lit("raw_processing"))
    
    # Convert back to DynamicFrame
    processed_frame = DynamicFrame.fromDF(df, glueContext, "processed_data")
    
    # Write processed data
    glueContext.write_dynamic_frame.from_options(
        frame=processed_frame,
        connection_type="s3",
        connection_options={"path": processed_path},
        format="parquet"
    )
    
    print("Processing completed successfully")
    
except Exception as e:
    print(f"Error processing data: {str(e)}")
    raise e

finally:
    job.commit()