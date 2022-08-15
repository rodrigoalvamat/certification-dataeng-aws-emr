"""Defines the ETLPipeline class to extract json data from
the AWS S3 bucket, transform them with Spark, and load
them back into S3 as a set of dimensional parquet tables."""

# sys libs
import argparse
from timeit import default_timer as timer
# spark libs
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, concat, concat_ws, from_unixtime, substring, to_date
from pyspark.sql.functions import dayofmonth, dayofweek, hour, month, weekofyear, year
# config libs
from etl.config import Config
# metadata libs
from etl.metadata import columns


class ETLPipeline:
    """This class defines the AWS EMR ETL pipeline.

    Code usage example with default config:

    config = Config()
    pipeline = ETLPipeline(config)
    pipeline.run()

    Usage example as python script with local config:
    python -m etl --local
    """

    def __init__(self, config):
        """Creates the ETLPipeline object and sets the config object.

        Args:
            config: The config adapter wrapper.
        """
        self.config = config
        self.spark = self.__create_spark_session()

    def __create_spark_session(self):
        """Creates the Spark session, sets the application name and
        configure the jar dependencies packages."""
        spark = SparkSession.builder \
            .appName(self.config.get('SPARK', 'APP_NAME')) \
            .getOrCreate()

        # .config('spark.jars.packages', self.config.get('SPARK', 'HADOOP_JAR')) \
        return spark

    def __repartition(self, source, target):
        """Reads all json files in the source folder and
        merge them into one JSON file in the target folder.

        NOTE: The number of partitions was set to ONE just
        because the data set is small and the merged JSON
        file has less than 128 MB.

        Args:
            source: The origin folder of the json files.
            target: The destination folder for the JSON file.
        """
        data = self.spark.read.json(source).repartition(1)
        data.write.mode('overwrite').json(target)
        return self.spark.read.json(target)

    def __extract(self, source, target):
        """Reads JSON data files from the landing zone and merges them,
        by repartitioning, into a single file in the bronze layer.

        Returns:
            The merged JSON file.
        """
        landing = f"{self.config.get('S3', 'LANDING')}/{source}"
        bronze = f"{self.config.get('S3', 'BRONZE')}/{target}"

        return self.__repartition(source=landing, target=bronze)

    @staticmethod
    def __transform_table(data, json_columns, table_columns, duplicates=None):
        """Renames all columns of a DataFrame and drop duplicate values
        for the given list of columns with duplicates.

        Args:
            data: The table DataFrame
            json_columns: Column names from spark infer schema.
            table_columns: Column names to write to the parquet file.
            duplicates: List of columns to drop duplicate values.

        Returns:
            The transformed table DataFrame.
        """
        return data.select(json_columns).toDF(*table_columns).drop_duplicates(duplicates)

    @staticmethod
    def __transform_time(data, json_columns, table_columns, duplicates=None):
        """Transforms the unix epoch timestamp into a unique time identifier
        and add columns - hour, day, week, month, year and weekday - to the
        table DataFrame.

        Args:
            data: The table DataFrame
            json_columns: Column names from spark infer schema.
            table_columns: Column names to write to the parquet file.
            duplicates: List of columns to drop duplicate values.

        Returns:
            The transformed table DataFrame.
        """
        # @formatter:off
        time = data.select(json_columns) \
            .withColumn('start_time', concat_ws('.',
                                                from_unixtime((col('ts') / 1000), 'yyyy-MM-dd HH:mm:ss'),
                                                substring(col('ts'), -3, 3))) \
            .withColumn('date', to_date('start_time')) \
            .withColumn('hour', hour('date')) \
            .withColumn('day', dayofmonth('date')) \
            .withColumn('week', weekofyear('date')) \
            .withColumn('month', month('date')) \
            .withColumn('year', year('date')) \
            .withColumn('weekday', dayofweek('date')) \
            .select(table_columns) \
            .drop_duplicates(duplicates)
        # @formatter:on
        return time

    @staticmethod
    def __transform_songplays(log_data, song_data, json_columns, table_columns):
        """Join the log_data and song_data DataFrames and transforms
        the unix epoch timestamp into a unique time identifier that
        matches the time table.

        Args:
            log_data: The DataFrame with songplays data.
            song_data: The DataFrame with songs data.
            json_columns: Column names from spark infer schema.
            table_columns: Column names to write to the parquet file.

        Returns:
            The transformed table DataFrame.
        """
        join_conditions = [
            (col('sp.song') == col('so.title')) &
            (col('sp.artist') == col('so.artist_name')) &
            (col('sp.length') == col('so.duration'))
        ]
        # @formatter:off
        songplays = log_data.select(json_columns).alias('sp') \
            .join(song_data.alias('so'), join_conditions) \
            .withColumnRenamed('userAgent', 'user_agent') \
            .withColumnRenamed('sessionId', 'session_id') \
            .withColumnRenamed('userId', 'user_id') \
            .withColumn('songplay_id', concat(col('user_id'),
                                              col('session_id').cast('string'),
                                              col('itemInSession').cast('string'))) \
            .withColumn('start_time', concat_ws('.',
                                                from_unixtime((col('ts') / 1000), 'yyyy-MM-dd HH:mm:ss'),
                                                substring(col('ts'), -3, 3))) \
            .withColumn('date', to_date('start_time')) \
            .withColumn('month', month('date')) \
            .withColumn('year', year('date')) \
            .select(table_columns)
        # @formatter:on
        return songplays

    def __transform(self, log_data, song_data):
        print('INFO: Transform artists table.')
        artists = self.__transform_table(data=song_data,
                                         json_columns=columns['artists']['json'],
                                         table_columns=columns['artists']['table'],
                                         duplicates=['artist_id'])

        print('INFO: Transform songs table.')
        songs = self.__transform_table(data=song_data,
                                       json_columns=columns['songs']['json'],
                                       table_columns=columns['songs']['table'],
                                       duplicates=['song_id'])

        print('INFO: Transform users table.')
        users = self.__transform_table(data=log_data,
                                       json_columns=columns['users']['json'],
                                       table_columns=columns['users']['table'],
                                       duplicates=['user_id'])

        print('INFO: Transform time table.')
        time = self.__transform_time(data=log_data,
                                     json_columns=columns['time']['json'],
                                     table_columns=columns['time']['table'],
                                     duplicates=['start_time'])

        print('INFO: Transform songplays table.')
        songplays = self.__transform_songplays(log_data, song_data,
                                               json_columns=columns['songplays']['json'],
                                               table_columns=columns['songplays']['table'])

        return {
            'artists': artists,
            'songs': songs,
            'users': users,
            'time': time,
            'songplays': songplays
        }

    def __load(self, tables):
        silver = self.config.get('S3', 'SILVER')

        print(f'INFO: Write artists parquet table.')
        tables['artists'].write.mode('overwrite') \
            .parquet(f"{silver}/{self.config.get('FILES', 'ARTISTS_SILVER')}")

        print(f'INFO: Write songs parquet tables.')
        tables['songs'].write.partitionBy('artist_id').mode('overwrite') \
            .parquet(f"{silver}/{self.config.get('FILES', 'SONGS_BY_ARTIST_SILVER')}")
        tables['songs'].write.partitionBy('year').mode('overwrite') \
            .parquet(f"{silver}/{self.config.get('FILES', 'SONGS_BY_YEAR_SILVER')}")

        print(f'INFO: Write users parquet table.')
        tables['users'].write.mode('overwrite') \
            .parquet(f"{silver}/{self.config.get('FILES', 'USERS_SILVER')}")

        print(f'INFO: Write time parquet tables.')
        tables['time'].write.partitionBy('month').mode('overwrite') \
            .parquet(f"{silver}/{self.config.get('FILES', 'TIME_BY_MONTH_SILVER')}")
        tables['time'].write.partitionBy('year').mode('overwrite') \
            .parquet(f"{silver}/{self.config.get('FILES', 'TIME_BY_YEAR_SILVER')}")

        print(f'INFO: Write songplays parquet tables.')
        tables['songplays'].write.partitionBy('month').mode('overwrite') \
            .parquet(f"{silver}/{self.config.get('FILES', 'SONGPLAYS_BY_MONTH_SILVER')}")
        tables['songplays'].write.partitionBy('year').mode('overwrite') \
            .parquet(f"{silver}/{self.config.get('FILES', 'SONGPLAYS_BY_YEAR_SILVER')}")

    def start(self):
        """Execute all pipeline phases and print time statistics."""
        print('-----------------------------------------------------')
        print('AWS EMR Spark ETL Pipeline')
        print('-----------------------------------------------------')

        # PHASE 1: Extract
        print('INFO: Extracting and repartitioning data.')
        start = timer()

        print('INFO: Extract log_data.')
        logs = self.__extract(source=self.config.get('FILES', 'LOGS_LANDING'),
                              target=self.config.get('FILES', 'LOGS_BRONZE'))

        # filter logs after repartition
        logs = logs.where(col('page') == 'NextSong')

        print('INFO: Extract song_data.')
        songs = self.__extract(source=self.config.get('FILES', 'SONGS_LANDING'),
                               target=self.config.get('FILES', 'SONGS_BRONZE'))

        extract_time = timer() - start
        print('INFO: Extract phase finished.')

        # PHASE 2: Transform
        print('-----------------------------------------------------')
        print('INFO: Transforming JSON data into tables.')
        start = timer()

        tables = self.__transform(log_data=logs, song_data=songs)

        transform_time = timer() - start
        print('INFO: Transform phase finished.')

        # PHASE 3: Load
        print('-----------------------------------------------------')
        print('INFO: Loading data into parquet tables.')
        start = timer()

        self.__load(tables=tables)

        load_time = timer() - start
        print('INFO: Load phase finished.')

        total_time = extract_time + transform_time + load_time
        # STATS: print the time statistics
        print('-----------------------------------------------------')
        print('Time Statistics')
        print('-----------------------------------------------------')
        print(f'Extract time: {round(extract_time, 2)} seconds')
        print(f'Transform time: {round(transform_time, 2)} seconds')
        print(f'Load time: {round(load_time, 2)} seconds')
        print(f'Total time: {round(total_time, 2)} seconds')

    def stop(self):
        """Stop the pipeline SparkContext."""
        self.spark.stop()


def main(local):
    """The etl.py script entry point.
    Args:
        local: If True uses the AWS EMR and S3 configurations,
            otherwise uses the local file system and the localhost
            Spark session.
    """
    # sets the session host
    config = Config(local=local)

    # run the pipeline
    pipeline = ETLPipeline(config)
    pipeline.start()
    pipeline.stop()


if __name__ == "__main__":
    # create the command line parser
    parser = argparse.ArgumentParser(description='AWS EMR Spark Pipeline')

    message = 'Loads data from the local file system and sets Spark session to localhost - default: ASW EMR'

    # set the command line arguments
    parser.add_argument('-l', '--local', action='store_true',
                        help=message,
                        default=False)

    # parse the command line arguments
    args = parser.parse_args()

    # run the pipeline
    main(args.local)
