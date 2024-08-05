import sys
import threading
import csv
import datetime
import logging
import boto3
import os
import time
import json

from pathlib import Path
from multiprocessing import Pool
from e6data_python_connector import Connection

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

cluster_host = os.environ.get("HOST")
cluster_port = int(os.environ.get("PORT"))
username = os.environ.get("E6_USERNAME")
password = os.environ.get("E6_PASSWORD")
concurrent_query_count = os.environ.get("CONCURRENT_QUERY_COUNT")
concurrency_interval = os.environ.get("CONCURRENCY_INTERVAL")
catalog = os.environ.get("CATALOG")
database = os.environ.get("DATABASE")
query_path = os.environ.get("QUERY_PATH")
enable_concurrency = os.getenv("ENABLE_CONCURRENCY") == "true"
s3_bucket = os.environ.get("S3_BUCKET")


def get_e6_connection_obj():
    e6x_connection = Connection(host=cluster_host,
                                port=cluster_port,
                                database=database,
                                catalog=catalog,
                                username=username,
                                password=password,
                                )
    return e6x_connection


def create_e6x_con(retry_count=0):
    max_retry_count = 3
    logger.info(f'TIMESTAMP : {datetime.datetime.now()} Connecting to e6data database ...')
    now = time.time()
    try:
        e6x_connection = get_e6_connection_obj()
        logger.info(
            'TIMESTAMP : {} connected with database {} and catalog {} in {} seconds'.format(datetime.datetime.now(),
                                                                                            database, catalog,
                                                                                            time.time() - now))
        return e6x_connection
    except Exception as e:
        logger.error(e)
        logger.error(
            'TIMESTAMP : {} Failed to connect to the e6xdata database with {}'.format(datetime.datetime.now(),
                                                                                      database))
        if retry_count > max_retry_count:
            raise e
        logger.error('Retry to connect in {} seconds...'.format(10))
        retry_count += 1
        time.sleep(10)
        return create_e6x_con(retry_count=retry_count)


def get_status_waiting(current_time: float):
    new_time = current_time * 0.2
    if new_time > 2.0:
        new_time = 2
    return new_time


class SimpleThread:
    result = None
    timeout_result = dict(query_id=None,
                          row_count=None,
                          queue_time=None,
                          compilation_time=None,
                          execution_time=None,
                          client_calculated_time=None,
                          query_status='Failure',
                          start_time=None,
                          end_time=None,
                          err_msg="Process Timeout")

    def query_on_6ex(self, query, cursor, query_alias=None):
        query_start_time = datetime.datetime.now()
        self.timeout_result.update(start_time=query_start_time)
        query_id = None
        try:
            query_id = cursor.execute(query)
            logger.info(
                "Prepare Statement completed | Status check started for {} | Time Taken {} | Alias {}".format(query_id,
                                                                                                              (
                                                                                                                      datetime.datetime.now() - query_start_time).total_seconds(),
                                                                                                              query_alias))
            self.timeout_result.update(query_id=query_id)
            status_counter = 0
            waiting_start_time = 0.5
            while True:
                query_status = cursor.status(query_id)
                if query_status.status:
                    break
                else:
                    status_counter += 1
                    time.sleep(waiting_start_time)
                    waiting_start_time = get_status_waiting(waiting_start_time)
            logger.info("Status completed | Fetch all Buffer started for {} | Time Taken {} | Alias {}".format(query_id,
                                                                                                               (
                                                                                                                       datetime.datetime.now() - query_start_time).total_seconds(),
                                                                                                               query_alias))
            records_iterator = cursor.fetchall_buffer()
            for row in records_iterator:
                pass
            logger.info("Fetch all Buffer completed for {} |Total Time Taken {} | Alias {}".format(query_id, (
                    datetime.datetime.now() - query_start_time).total_seconds(), query_alias))
            self.timeout_result.update(err_msg="Timeout after fetch many")
            query_end_time = datetime.datetime.now()
            explain_analyse = cursor.explain_analyse()
            planner_result = explain_analyse.get('planner')
            if type(planner_result) == str:
                planner_result = json.loads(planner_result)
            execution_time = planner_result.get("total_query_time") / 1000 if planner_result.get(
                "total_query_time") is not None else "Not Available"
            queue_time = planner_result.get("executionQueueingTime") / 1000 if planner_result.get(
                "executionQueueingTime") is not None else "Not Available"
            compilation_time = planner_result.get("parsingTime") / 1000 if planner_result.get(
                "parsingTime") is not None else "Not Available"
            row_count = planner_result.get('row_count_out') if planner_result.get(
                "row_count_out") is not None else "Not Available"
            query_status = 'Success'
            self.result = dict(
                query_id=query_id,
                row_count=row_count,
                queue_time=queue_time,
                compilation_time=compilation_time,
                execution_time=execution_time,
                client_calculated_time=(query_end_time - query_start_time).total_seconds(),
                query_status=query_status,
                start_time=query_start_time,
                end_time=query_end_time,
                err_msg=None,
            )
        except BaseException as e:
            try:
                query_id = e.queryId
            except:
                pass
            logger.info('TIMESTAMP {} Error on querying e6data engine: {}'.format(datetime.datetime.now(), e))
            query_status = 'Failure'
            err_msg = str(e)
            query_end_time = datetime.datetime.now()
            if 'timeout' in err_msg:
                err_msg = 'Connect timeout. Unable to connect.'
            self.result = dict(
                query_id=query_id,
                row_count=0,
                queue_time=0,
                compilation_time=0,
                execution_time=0,
                client_calculated_time=0,
                query_status=query_status,
                start_time=query_start_time,
                end_time=query_end_time,
                err_msg=err_msg,
            )


def thread_query_pool(query, cursor, query_alias):
    simple_thread = SimpleThread()
    if not simple_thread.result:
        thread1 = threading.Thread(target=simple_thread.query_on_6ex, args=(query, cursor, query_alias))
        thread1.daemon = True
        thread1.start()
        while True:
            if simple_thread.result:
                break
    return simple_thread.result


def cursor_clear_and_connection_close(cursor, connection):
    try:
        cursor.clear()
    except Exception as e:
        logger.error("CURSOR CLEAR FAILED : {}".format(str(e)))
    try:
        connection.close()
    except Exception as e:
        logger.error("CONNECTION CLOSE FAILED : {}".format(str(e)))


def e6x_query_method(row):
    query_alias_name = row.get('query_alias_name')
    logger.info(
        'Initiated Concurrent call for {}, FIRED at: X{}'.format(query_alias_name, datetime.datetime.now()))
    query = row.get('query').replace('\n', ' ').replace('  ', ' ')
    try:
        local_connection = create_e6x_con()
        local_cursor = local_connection.cursor()
        logger.info('Query alias: {}, Started Executing at: {}'.format(query_alias_name, datetime.datetime.now()))
        status = thread_query_pool(query, local_cursor, query_alias=query_alias_name)
        logger.info('Query alias: {}, Ended at: {}'.format(query_alias_name, datetime.datetime.now()))
        if not status.get("err_msg") == "Process Timeout":
            if status.get("query_status") == "Failure":
                if "Executor is non responsive" in status.get('err_msg'):
                    logger.info(
                        "Got Error Executor is non responsive . Bypassing Cursor Clear and close .Closing Connection.")
                    try:
                        local_connection.close()
                    except Exception as e:
                        logger.error("CONNECTION CLOSE FAILED : {}".format(str(e)))
                else:
                    cursor_clear_and_connection_close(cursor=local_cursor, connection=local_connection)
            else:
                cursor_clear_and_connection_close(cursor=local_cursor, connection=local_connection)
        else:
            logger.info(
                "Process Timeout for alias {}.Bypassing connection close and cursor clear".format(query_alias_name))
        logger.info(
            'Completed Concurrent call for {}, Complted at: X{}'.format(query_alias_name, datetime.datetime.now()))
        return status, query_alias_name, query, database
    except Exception as e:
        logger.error("CURSOR create FAILED : {}".format(str(e)))
        status = dict(row_count=0,
                      query_status="Failure",
                      err_msg="CURSOR CREATE FAILED",
                      )
        return status, query_alias_name, query, database


def s3_upload(result_file_path):
    s3_folder_file_path = f"e6_benchmark_results/{database}/{datetime.datetime.now().date()}/results_{time.time()}.csv"
    s3_path = f"s3://{s3_bucket}/{s3_folder_file_path}"
    logger.info('TIMESTAMP {} Stated uploading result csv file to s3 folder...'.format(datetime.datetime.now()))
    s3 = boto3.resource('s3')
    s3.meta.client.upload_file(result_file_path, s3_bucket, s3_folder_file_path)
    logger.info('TIMESTAMP {} Completed uploading result csv file to s3 folder'.format(datetime.datetime.now()))
    logger.info('TIMESTAMP {} Uploaded s3 path is {}'.format(datetime.datetime.now(), s3_path))


class E6XBenchmark():
    current_retry_count = 1
    max_retry_count = 5
    retry_sleep_time = 5

    def __init__(self, thread=None, time_wait=None):
        super(E6XBenchmark, self).__init__()
        self.failed_query_alias = []
        self.execution_start_time = None
        self.e6x_connection = None
        self.e6x_cursor = None
        self.local_file_path = None
        self.total_number_of_threads = thread
        self.time_wait = time_wait
        self.db_conn_retry_count = 0
        self._check_envs()
        self.counter = 0
        self.failed_query_count = 0
        self.success_query_count = 0
        self.query_results = list()
        self.local_file_path = query_path
        self.csv_flag = 3
        result, is_any_query_failed = self._perform_query_from_csv()
        self._send_summary_readymade()
        self._send_to_webclient(result)
        if is_any_query_failed:
            msg = 'Some queries failed. Please check the above logs for more information.'
            logger.error(msg)
            raise Exception(msg)

    def _check_envs(self):
        if not cluster_host:
            raise Exception('Invalid cluster_host: Please set the environment.')
        if not catalog:
            raise Exception('Invalid catalog: Please set the environment.')

    def e6x_query_method(self, row):
        query_alias_name = row.get('query_alias_name')
        query = row.get('query').replace('\n', ' ').replace('  ', ' ')
        local_connection = self.create_e6x_con(database)
        logger.info(
            'TIMESTAMP : {} connected with catalog {} , db {} and Engine {}'.format(datetime.datetime.now(),
                                                                                    catalog, database, cluster_host))
        local_cursor = local_connection.cursor()
        logger.info('TIMESTAMP : {}'.format(datetime.datetime.now()))
        logger.info('Query alias: {}, Started at: {}'.format(query_alias_name, datetime.datetime.now()))
        status = self._query_on_6ex(query, local_cursor, query_alias=query_alias_name)
        cursor_clear_and_connection_close(cursor=local_cursor, connection=local_connection)
        logger.info('Query alias: {}, Ended at: {}'.format(query_alias_name, datetime.datetime.now()))
        if enable_concurrency:
            return status, query_alias_name, query, database
        else:
            if status.get('query_status') == 'Failure':
                self.failed_query_count += 1
                self.failed_query_alias.append(query_alias_name)
            else:
                self.success_query_count += 1
            self.query_results.append(dict(
                s_no=self.counter + 1,
                query_alias=query_alias_name,
                query=query,
                database=database,
                **status
            ))
            logger.info(dict(
                s_no=self.counter + 1,
                query_alias=query_alias_name,
                query=query,
                database=database,
                **status
            ))
            logger.info('{}. Query status of query alias: {} {}'.format(
                self.counter,
                query_alias_name,
                status.get('query_status'))
            )
            self.counter += 1

    def _perform_query_from_csv(self):
        all_rows = self._get_query_list_from_csv_file()
        if enable_concurrency:
            self.total_number_of_threads = int(self.total_number_of_threads)
            self.time_wait = int(self.time_wait)
            pool_pool = list()
            size = min(self.total_number_of_threads, len(all_rows))
            a = (len(all_rows) / self.total_number_of_threads)
            concur_looper = int(a) + 1 if type(a) == float else a
            for j in range(concur_looper):
                pool = Pool(processes=size)
                res = pool.map_async(e6x_query_method, (i for i in all_rows[size * j:size * (j + 1)]))
                pool_pool.append(res)
                time.sleep(self.time_wait)
            logger.info("Running concurrent queries in E6DATA with ENABLE_CONCURRENCY enabled")
            threads = []
            for process_pool in pool_pool:
                x = threading.Thread(target=self.process_retrieval_and_update, args=(process_pool,))
                x.daemon = True
                x.start()
                threads.append(x)
            for i in threads:
                i.join()
        else:
            for row in all_rows:
                logger.info("Running sequential queries in E6DATA with ENABLE_CONCURRENCY disabled")
                self.e6x_query_method(row)
        logger.info('TIMESTAMP {} ALL Query completed'.format(datetime.datetime.now()))
        self.total_number_of_queries = len(all_rows)
        self.total_number_of_queries_successful = self.success_query_count
        self.total_number_of_queries_failed = self.failed_query_count

        is_any_query_failed = self.failed_query_count > 0
        return self.query_results, is_any_query_failed

    def process_retrieval_and_update(self, process):
        logger.info("Started retrieval for process {}".format(process))
        present_pool_results = process.get()
        for output in present_pool_results:
            try:
                status, query_alias_name, query, db_name = output[0], output[1], output[2], output[3]

                if status.get('query_status') == 'Failure':
                    self.failed_query_count += 1
                    self.failed_query_alias.append(query_alias_name)
                else:
                    self.success_query_count += 1
                self.query_results.append(dict(
                    s_no=self.counter + 1,
                    query_alias=query_alias_name,
                    query=query,
                    database=db_name,
                    **status
                ))
                logger.info(dict(
                    s_no=self.counter + 1,
                    query_alias=query_alias_name,
                    query=query,
                    database=db_name,
                    **status
                ))
                logger.info('{}. Query status of query alias: {} {}'.format(
                    self.counter,
                    query_alias_name,
                    status.get('query_status'))
                )
                self.counter += 1
            except Exception as e:
                logger.error("Getting Output of query has failed CHECK IT: {}".format(str(e)))

    def _query_on_6ex(self, query, cursor, query_alias) -> dict:
        query_start_time = datetime.datetime.now()
        query_id = None
        try:
            query_id = cursor.execute(query)
            status_counter = 0
            waiting_start_time = 0.5
            while True:
                query_status = cursor.status(query_id)
                if query_status.status:
                    break
                else:
                    status_counter += 1
                    time.sleep(waiting_start_time)
                    waiting_start_time = get_status_waiting(waiting_start_time)

            logger.info("Status completed | Fetch all Buffer started for {} | Time Taken {} | Alias {}".format(query_id,
                                                                                                               (
                                                                                                                       datetime.datetime.now() - query_start_time).total_seconds(),
                                                                                                               query_alias))
            records_iterator = cursor.fetchall_buffer()
            for row in records_iterator:
                pass
            logger.info("Fetch all Buffer completed for {} |Total Time Taken {} | Alias {}".format(query_id,
                                                                                                   (
                                                                                                           datetime.datetime.now() - query_start_time).total_seconds(),
                                                                                                   query_alias))
            query_end_time = datetime.datetime.now()
            explain_analyse = cursor.explain_analyse()
            planner_result = explain_analyse.get('planner')
            if type(planner_result) == str:
                planner_result = json.loads(planner_result)
            execution_time = planner_result.get("total_query_time") / 1000 if planner_result.get(
                "total_query_time") is not None else "Not Available"
            queue_time = planner_result.get("executionQueueingTime") / 1000 if planner_result.get(
                "executionQueueingTime") is not None else "Not Available "
            compilation_time = planner_result.get("parsingTime") / 1000 if planner_result.get(
                "parsingTime") is not None else "Not Available"
            row_count = planner_result.get('row_count_out') if planner_result.get(
                "row_count_out") is not None else "Not Available"
            query_status = 'Success'
            data = dict(
                query_id=query_id,
                row_count=row_count,
                queue_time=queue_time,
                compilation_time=compilation_time,
                execution_time=execution_time,
                client_calculated_time=(query_end_time - query_start_time).total_seconds(),
                query_status=query_status,
                start_time=query_start_time,
                end_time=query_end_time,
                err_msg=None,
            )
            return data
        except BaseException as e:
            try:
                query_id = e.queryId
            except:
                pass
            if 'TSocket read 0 bytes' in str(e):
                if self.current_retry_count <= self.max_retry_count:
                    logger.info(
                        'TIMESTAMP {} Reconnecting to the e6data engine due to error {}'.format(datetime.datetime.now(),
                                                                                                e))
                    logger.info('Sleeping for {} seconds.'.format(self.retry_sleep_time))
                    time.sleep(self.retry_sleep_time)
                    logger.info('Retry attempt number: {}'.format(self.current_retry_count))
                    local_connection = self.create_e6x_con(database)
                    cursor = local_connection.cursor(db_name=database, catalog_name=catalog)
                    self.current_retry_count += 1
                    return self._query_on_6ex(query, cursor, query_alias)
                else:
                    query_end_time = datetime.datetime.now()
                    query_status = 'Failure'
                    err_msg = str(e)
                    return dict(
                        query_id=query_id,
                        row_count=0,
                        queue_time=0,
                        compilation_time=0,
                        execution_time=0,
                        client_calculated_time=0,
                        query_status=query_status,
                        start_time=query_start_time,
                        end_time=query_end_time,
                        err_msg=err_msg,
                    )
            else:
                logger.info('TIMESTAMP {} Error on querying e6data engine: {}'.format(datetime.datetime.now(), e))
                query_status = 'Failure'
                err_msg = str(e)
                query_end_time = datetime.datetime.now()
                if 'timeout' in err_msg:
                    err_msg = 'Connect timeout. Unable to connect.'
                return dict(
                    query_id=query_id,
                    row_count=0,
                    queue_time=0,
                    compilation_time=0,
                    execution_time=0,
                    client_calculated_time=(query_end_time - query_start_time).total_seconds(),
                    query_status=query_status,
                    start_time=query_start_time,
                    end_time=query_end_time,
                    err_msg=err_msg,
                )

    def create_e6x_con(self, db_name=database):
        logger.info(f'TIMESTAMP : {datetime.datetime.now()} Connecting to e6x database...')
        now = time.time()
        try:

            e6x_connection = get_e6_connection_obj()
            logger.info('TIMESTAMP : {} Connected to e6x in {}'.format(datetime.datetime.now(), time.time() - now))
            return e6x_connection
        except Exception as e:
            logger.error(e)
            logger.error(
                'TIMESTAMP : {} Failed to connect to the e6x database with {}'.format(datetime.datetime.now(), db_name))
            if self.db_conn_retry_count > 10:
                raise e
            logger.error('Retry to connect in {} seconds...'.format(10))
            self.db_conn_retry_count += 1
            time.sleep(10)
            return self.create_e6x_con(db_name)

    def _send_summary_readymade(self):
        failed_query_message = self.total_number_of_queries_failed
        if failed_query_message > 0:
            try:
                failed_query_message = '{} | (Query Alias: {})'.format(failed_query_message,
                                                                       ', '.join(self.failed_query_alias))
            except:
                failed_query_message = '{} | Failed Query Alias not available'.format(failed_query_message)
        summary_data = {
            'Test Run Date': datetime.date.today(),
            'Dataset': database,
            'Total Queries Run': self.total_number_of_queries,
            'Total Queries Successful': self.total_number_of_queries_successful,
            'Total Queries Failed': failed_query_message,
        }
        data = 'Summary \n'
        for key, value in summary_data.items():
            data += '{} - {} \n'.format(key, value)
        logger.info("SUMMARY\n" + data)

    def __del__(self):
        if self.local_file_path:
            try:
                pass
            except Exception as e:
                logger.error('Failed to delete the file error: {}'.format(str(e)))

    def _get_query_list_from_csv_file(self):
        if not query_path.endswith('.csv'):
            raise Exception('Invalid query_path: Only CSV file is supported.')
        logger.info('Local file path {}'.format(self.local_file_path))
        logger.info('Reading data from file...')
        data = list()
        maxInt = sys.maxsize
        csv.field_size_limit(maxInt)
        with open(self.local_file_path, 'r') as fh:
            reader = csv.DictReader(fh)
            csv_data = [i for i in reader]
            for row in csv_data:
                data.append({
                    'query': row.get('QUERY'),
                    'query_alias_name': row.get('QUERY_ALIAS')
                })
        self.total_number_of_queries = len(csv_data)
        logger.debug("TIMESTAMP {} CSV TYPE is {} and total number of queries are {}".format(datetime.datetime.now(),
                                                                                             self.csv_flag, self.total_number_of_queries))
        logger.info('Completed reading data from file')
        return data

    def _send_to_webclient(self, result):
        logger.info('TIMESTAMP {} Stated creating result csv file...'.format(datetime.datetime.now()))
        path = Path(__file__).resolve().parent
        result_file_path = os.path.join(path, 'results_{}.csv'.format(datetime.datetime.now()))
        logger.info('TIMESTAMP {} Result local file path {}'.format(datetime.datetime.now(), result_file_path))
        if self.csv_flag != 1:
            with open(result_file_path, 'w', newline='') as fp:
                header_list = list(result[0].keys())
                writer = csv.writer(fp, delimiter=',')
                writer.writerow(header_list)
                for line in result:
                    li = list(line.values())
                    writer.writerow(li)
                writer.writerow([''])
                writer.writerow([''])
        logger.info('TIMESTAMP {} Completed creating result csv file'.format(datetime.datetime.now()))
        s3_upload(result_file_path)


if __name__ == '__main__':
    logger.info('******************* Benchmarks started *******************')
    logger.info('Engin IP is {}'.format(cluster_host))
    logger.info('Engin Port is {}'.format(cluster_port))
    logger.info('Query Path is {}'.format(query_path))
    logger.info(
        'CONCURRENT_QUERY_COUNT {}, with CONCURRENCY_INTERVAL {}'.format(concurrent_query_count, concurrency_interval))
    a = threading.Thread(args=(5,))
    a.daemon = True
    a.start()

    E6XBenchmark(thread=concurrent_query_count, time_wait=concurrency_interval)
    logger.info('******************* Benchmarks completed *******************')
