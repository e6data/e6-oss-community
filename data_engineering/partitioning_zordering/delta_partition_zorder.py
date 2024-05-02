import os
import csv
import traceback
import warnings
import logging
from pathlib import Path

import boto3
import pandas as pd
from delta.tables import *
from datetime import datetime, timedelta
from pyspark.sql import SparkSession

MSG_FORMAT = '%(asctime)s %(levelname)s %(name)s: %(message)s'
DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'
logging.basicConfig(format=MSG_FORMAT, datefmt=DATETIME_FORMAT)
logger = logging.getLogger()
logger.setLevel(logging.INFO)
warnings.simplefilter(action='ignore', category=FutureWarning)

data_setup_csv_path = os.environ.get("DATA_SETUP_CSV_PATH")
database_name = os.environ.get("DATABASE_NAME")
s3_database_path = os.environ.get("S3_DATABASE_PATH")
s3_database_delta_path = os.environ.get("S3_DATABASE_DELTA_PATH")
s3_bucket_name = os.environ.get("S3_BUCKET_NAME")


def get_data_setup_info_from_csv(schema_path) -> dict:
    start_time = datetime.now()
    try:
        logger.info(f"Reading CSV file from path {schema_path}")
        csv_data = {}
        with open(schema_path, 'r') as fh:
            data = csv.DictReader(fh)
            logger.info("Parsing CSV content and extracting schema details")
            for line in data:
                column_data = []
                table_name = line.get('table_name')
                column_data.append(str(line.get('partition_column')).replace('\"', '`').replace(',', ', '))
                column_data.append(str(line.get('sorting_column')).replace('\"', '`').replace(',', ', '))
                csv_data[table_name] = column_data
        logger.info(f"Successfully extracted data setup information from CSV")
        end_time = datetime.now()
        total_time = end_time - start_time
        logger.info(f"Total duration taken for extracting values from CSV file is {total_time}")
        return csv_data
    except Exception as e:
        logger.error(f"Error occurred while reading CSV file: {e}")
        return {}


def partition_data(data, delta_table_path, partition_columns_list, table_name, database_name):
    logger.info(f"Started Partitioning...")
    data.write.format("delta").mode("overwrite").option("ignoreCorruptFiles", "true").option("overwriteSchema", "true") \
        .option("delta.columnMapping.mode", "name").option("delta.dataSkippingNumIndexedCols", "-1").partitionBy(*partition_columns_list).option("path",
                                                                                                delta_table_path) \
        .saveAsTable(f"{database_name}.{table_name}")
    logger.info(f"Completed Partitioning and Delta table creation")


def zorder_data(delta_table, zorder_columns_list):
    logger.info(f"Started Z-ordering and Compaction...")
    delta_table.optimize().executeZOrderBy(*zorder_columns_list)
    logger.info(f"Completed Z-ordering and Compaction")


def csv_write_data(database_name, table_name, timings_data):
    try:
        path = Path(__file__).resolve().parent
        local_csv_path = os.path.join(path, f'{database_name}_{table_name}_timings.csv')
        logger.info(f"Started writing operations stats into CSV file")
        df = pd.DataFrame([timings_data])
        df.to_csv(local_csv_path, index=False)
        logger.info(f"Successfully created stats CSV file at local path {local_csv_path}")
        return local_csv_path
    except Exception as e:
        logging.error(f"Error occurred during stats CSV file creation for table {table_name}: {e}")


def s3_upload_csv(local_file_path, table_name):
    logger.info("Started uploading stats CSV file to S3")
    s3_folder_file_path = f"data_setup_stats_folder/{database_name}/{table_name}.csv"
    try:
        s3 = boto3.resource('s3')
        s3.meta.client.upload_file(local_file_path, s3_bucket_name, s3_folder_file_path)
        s3_file_path = f"s3://{s3_bucket_name}/{s3_folder_file_path}"
        logger.info(f"Successfully uploaded stats CSV file into S3 Path {s3_file_path}")
    except Exception as e:
        logging.error(f"Error occurred during CSV upload for {table_name}: {e}")


def datetime_check(operation_time):
    if operation_time is datetime:
        return pd.to_datetime(operation_time)
    else:
        return pd.to_datetime(operation_time)


def data_setup_function(csv_data):
    successful_tables_list = []
    failed_tables_list = {}
    try:
        logger.info("")
        logger.info(f"Started creating {database_name} database at {s3_database_delta_path}")
        database_creation_ddl = f"CREATE DATABASE {database_name} LOCATION '{s3_database_delta_path}'"
        spark.sql(database_creation_ddl)
        logger.info(f"Successfully created {database_name} database")
        spark.sql(f"USE {database_name}")
    except Exception as exception:
        logging.error(f"Error occurred during database creation: {exception}")

    for table_name, config in csv_data.items():
        try:
            total_operation_time = timedelta(seconds=0)
            timings_csv_data = {'database_name': database_name, 'table_name': table_name,
                                'parquet_reading_time': '',
                                'partition_table_creation_time': '', 'unpartition_table_creation_time': '',
                                'zordering_compaction_time': '', 'compaction_time': '',
                                'vacuum_time': '', 'total_time': ''}
            partition_columns, zorder_columns = config
            source_path = f"{s3_database_path}{table_name}"
            delta_table_path = f"{s3_database_delta_path}{table_name}"
            logger.info(
                f"------------------------ Starting data setup for {table_name} Table "
                f"-------------------------")
            logger.info(f"Started reading Parquet data {table_name} at path {source_path}")
            reading_start_time = datetime.now()
            data = spark.read.parquet(source_path)
            reading_end_time = datetime.now()
            parquet_reading_time = reading_end_time - reading_start_time
            logger.info(f"Time taken to read Parquet data is {parquet_reading_time}")
            timings_csv_data['parquet_reading_time'] = parquet_reading_time
            total_operation_time += parquet_reading_time
            if partition_columns:
                partitioning_start_time = datetime.now()
                partition_columns_list = partition_columns.split(", ")
                logger.info(f"partition columns list is {partition_columns_list}")
                partition_data(data, delta_table_path, partition_columns_list, table_name, database_name)
                partitioning_end_time = datetime.now()
                partition_table_creation_time = partitioning_end_time - partitioning_start_time
                logger.info(f"Time taken for Partitioning and Delta table creation is {partition_table_creation_time}")
                timings_csv_data['partition_table_creation_time'] = partition_table_creation_time
                total_operation_time += partition_table_creation_time
            else:
                un_partitioning_creation_start_time = datetime.now()
                logger.info(f"No Partitioning keys provided for table")
                logger.info(f"Started creating Delta table without Partitioning")
                data.write.format("delta").mode("overwrite").option("ignoreCorruptFiles", "true") \
                    .option("delta.columnMapping.mode", "name").option("delta.dataSkippingNumIndexedCols", "-1").option("path", delta_table_path) \
                    .saveAsTable(f"{database_name}.{table_name}")
                logger.info(f"Completed creation of Delta table")
                unpartitioning_creation_end_time = datetime.now()
                unpartition_table_creation_time = unpartitioning_creation_end_time - un_partitioning_creation_start_time
                logger.info(
                    f"Time taken for Delta table creation without Partitioning is {unpartition_table_creation_time}")
                timings_csv_data['unpartition_table_creation_time'] = unpartition_table_creation_time
                total_operation_time += unpartition_table_creation_time

            delta_table = DeltaTable.forPath(spark, delta_table_path)

            logger.info("")

            logger.info(f"Starting Z-ordering and compaction operation...")
            logger.info("Z-ordering operation colocate related information in the same set of files")
            logger.info("Compaction operation consolidates small files into larger ones to improve query performance")
            if zorder_columns:
                zordering_start_time = datetime.now()
                zorder_columns_list = zorder_columns.split(", ")
                logger.info(f"Z-ordering columns are {zorder_columns_list}")
                zorder_data(delta_table, zorder_columns_list)
                zordering_end_time = datetime.now()
                zordering_compaction_time = zordering_end_time - zordering_start_time
                logger.info(f"Time taken for Z-ordering and Compaction is {zordering_compaction_time}")
                timings_csv_data['zordering_compaction_time'] = zordering_compaction_time
                total_operation_time += zordering_compaction_time

            else:
                no_zordering_start_time = datetime.now()
                logger.info(f"No Z-ordering columns")
                logger.info("Started compaction")
                delta_table.optimize().executeCompaction()
                no_zordering_end_time = datetime.now()
                logger.info(f"Compaction completed for table {table_name}")
                compaction_time = no_zordering_end_time - no_zordering_start_time
                logger.info(f"Time taken for Compaction is {compaction_time}")
                timings_csv_data['compaction_time'] = compaction_time
                total_operation_time += compaction_time
            logger.info(f"Completed Z-ordering operation...")
            logger.info("")
            logger.info(f"Starting Vacuum operation...")
            logger.info(f"Vacuum operation removes files no longer referenced by a Delta table")
            vacuum_start_time = datetime.now()
            delta_table.vacuum()
            vacuum_end_time = datetime.now()
            logger.info(f"Completed Vacuum operation")
            vacuum_time = vacuum_end_time - vacuum_start_time
            logger.info(f"Time taken for Vacuum is {vacuum_time}")
            timings_csv_data['vacuum_time'] = vacuum_time
            total_operation_time += vacuum_time
            timings_csv_data['total_time'] = total_operation_time
            logger.info(f"Total time taken to complete operation is {total_operation_time}")
            local_file_path = csv_write_data(database_name, table_name, timings_csv_data)
            s3_upload_csv(local_file_path, table_name)
            logger.info("")
            logger.info(f"Successfully completed data setup for {table_name} Table")
            logger.info("")
            successful_tables_list.append(table_name)
        except Exception as exception:
            logger.error(f"Error occurred during data setup for table {table_name}: {exception}")
            full_exception = traceback.format_exception(type(exception), exception, exception.__traceback__)
            failed_tables_list[table_name] = ''.join(full_exception).split(':')[2]
    return successful_tables_list, failed_tables_list


if __name__ == '__main__':
    logger.info("")
    logger.info(f"Starting Data setup for Database {database_name}...")
    data_setup_start = datetime.now()
    logger.info(f"Data setup csv path: {data_setup_csv_path}")
    spark = SparkSession.builder \
        .appName("DeltaTableOperations") \
        .config("spark.jars.packages", "org.apache.hadoop:hadoop-aws:3.3.1,io.delta:delta-spark_2.12:3.1.0") \
        .config("spark.sql.parquet.outputTimestampType", "TIMESTAMP_MICROS") \
        .config("spark.hadoop.hive.metastore.client.factory.class",
                "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory") \
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
        .enableHiveSupport() \
        .getOrCreate()
    spark.conf.set("spark.databricks.delta.optimize.minFileSize", 134217728)
    spark.conf.set("spark.databricks.delta.optimize.maxFileSize", 134217728)
    spark.conf.set("spark.sql.files.ignoreCorruptFiles", True)
    csv_content = get_data_setup_info_from_csv(data_setup_csv_path)
    logger.info("")
    if csv_content:
        success_list, failed_list = data_setup_function(csv_content)
        data_setup_end = datetime.now()
        total_data_setup_time = (data_setup_end - data_setup_start).total_seconds()
        logger.info("")
        logger.info("******************************** SUMMARY OF DATA SETUP ******************************** ")
        logger.info(f"Total tables considered for data setup: {len(success_list) + len(failed_list)}")
        logger.info(f"Total number of complete data setup tables: {len(success_list)}")
        logger.info(f"List of complete data setup tables: {success_list}")
        logger.info(f"Total number of failed/incomplete data setup tables: {len(failed_list)}")
        logger.info(f"List of failed/incomplete data setup tables with exceptions: {failed_list}")
        logger.info(f"******************* Total time taken {total_data_setup_time} seconds ********************")
        logger.info("")
    else:
        logger.error("Data setup has been incomplete check error logs")
