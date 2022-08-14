# AWS S3 Data Lake & AWS EMR Spark Processing

Each of the five tables are written to parquet files in a separate analytics directory on S3.

Each table has its own folder within the directory.

Songs table files are partitioned by year and then artist.

Time table files are partitioned by year and month.

Songplays table files are partitioned by year and month.
