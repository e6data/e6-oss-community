# Data Layout Setup Automation

This Python script automates the process of partitioning and z-ordering data for optimal Query performance. It also includes commands for running compaction and vacuum operations.

## Prerequisites
### Components and Versions
Spark: 3.5.0 \
Delta-Spark: 3.1.0 \
EMR Cluster: 7.0.0

### Packages Installation

Before running the main script, ensure to install the required packages by running *requirements.txt*.

> pip install -r requirements.txt

## Environment Variables
Set the following environment variables before running the automation scripts:

* Command to download files from S3:
> aws s3 cp <S3-Path> <Destination-Path>

* Partitioning and Z-ordering information CSV path:
> export DATA_SETUP_CSV_PATH=<Path-to-python-script>

* S3 path of the database:
> export S3_DATABASE_PATH=<S3-path-of-database>

* S3 path of the delta database:
> export S3_DATABASE_DELTA_PATH=<S3-path-of-delta-database>

* Name of the delta database:
> export DATABASE_NAME=<Database-name>

* S3 bucket to dump the operation stats CSV file:
> export S3_BUCKET_NAME=<S3-bucket-name>

## Sample CSV File
The sample CSV file contains information required for the automation script:

| table_name      | partition_column              | sorting_column  |
|-----------------|-------------------------------|-----------------|
| zenoti_unload   | "center name","product sales" | "run date","id" |
| zenoti_unload_2 | "agent_id"                    |

## Spark Submit Command
Use the following Spark submit command to run the Automation Python script:

> spark-submit --deploy-mode client --master yarn --executor-memory 216G --driver-memory 216G --num-executors 2 --executor-cores 30 --packages org.apache.hadoop:hadoop-aws:3.3.1,io.delta:delta-spark_2.12:3.1.0  --conf spark.sql.parquet.outputTimestampType=TIMESTAMP_MICROS --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" --conf "spark.hadoop.hive.metastore.client.factory.class=com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory" --conf "spark.log.level=WARN" <path-to-python-script>`

Make sure to replace <path-to-python-script> with the actual path to your Python script.
The executor and Driver memory configurations can be changed accordingly.

For any queries or issues, please contact E6data.