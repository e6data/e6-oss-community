# Benchmarks setup

This Python script automates sequential and concurrency benchmarking.

## Prerequisites
### Packages Installation

Make sure to install below dependencies and wheel before install e6data-python-connector.

#### Amazon Linux / CentOS dependencies
> yum install python3-devel gcc-c++ -y

#### Ubuntu/Debian dependencies
> apt install python3-dev g++ -y

#### Pip dependencies
> pip install wheel

#### E6data python connector installation
> pip install e6data-python-connector

## Environment Variables
Set the following environment variables before running the automation scripts:

* E6data cluster host:
> export HOST=<e6-cluster>

* E6data cluster port:
> export PORT=<e6-port>

* E6data username email:
> export USERNAME=<e6data-user-email>
 
* E6data user password:
> export PASSWORD=<e6data-user-token>

* Name of the e6data catalog:
> export CATALOG=<e6data-catalog-name>

* Name of the database:
> export DATABASE=<database-name>

* Local queries csv file path:
> export QUERY_PATH=<local-queries-path>

* Flag to enable concurrency:
> export ENABLE_CONCURRENCY=<true|false>

* Number of concurrent queries:
> export CONCURRENT_QUERY_COUNT=<number-of-concurrent-queries>

* Concurrency interval in seconds:
> export CONCURRENCY_INTERVAL=<number-of-concurrent-interval-seconds>

* S3 bucket for storing the results CSV file:
> export S3_BUCKET=<s3-bucket-name>

## Sample Query CSV File
The sample Query CSV file contains the necessary information for the automation script:

| QUERY_ALIAS | QUERY                                     |
|-------------|-------------------------------------------|
| Query01     | SELECT * FROM TABLE1                      |
| Query02     | SELECT * FROM TABLE2 WHERE column = value |


## Sample Output CSV File
The output CSV file includes details such as Query ID, Row count, Queue time, Compilation time, Total Client time, Query start and end times, and any error messages for each query.

| s_no | query_alias | query | database | query_id | row_count | queue_time | compilation_time | execution_time | client_calculated_time | query_status | start_time | end_time | err_msg |
|------|-------------|-------|----------|----------|-----------|------------|------------------|----------------|------------------------|--------------|------------|----------|---------|
|      |             |       |          |          |           |            |                  |                |                        |              |            |          |         |       |

