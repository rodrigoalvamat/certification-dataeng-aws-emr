"""Defines metadata for table schema data types and columns."""

# spark libs
from pyspark.sql.types import *

_logs_schema = StructType([
    StructField('level', StringType()),
    StructField('location', StringType()),
    StructField('userAgent', StringType()),
    StructField('sessionId', LongType()),
    StructField('itemInSession', IntegerType()),
    StructField('userId', StringType()),
    StructField('firstName', StringType()),
    StructField('lastName', StringType()),
    StructField('gender', StringType()),
    StructField('ts', LongType()),
    StructField('song', StringType()),
    StructField('artist', StringType()),
    StructField('length', DoubleType()),
    StructField('page', StringType())
])
"""Logs JSON schema."""

_songs_schema = StructType([
    StructField('song_id', StringType()),
    StructField('title', StringType()),
    StructField('year', IntegerType()),
    StructField('duration', DoubleType()),
    StructField('artist_id', StringType()),
    StructField('artist_name', StringType()),
    StructField('artist_location', StringType()),
    StructField('artist_latitude', DoubleType()),
    StructField('artist_longitude', DoubleType()),
])
"""Songs JSON schema."""

schema = {
    'logs': _logs_schema,
    'songs': _songs_schema
}
"""Defines a dictionary of table schemas."""

columns = {
    'artists': {
        'json': ['artist_id', 'artist_name', 'artist_location',
                 'artist_latitude', 'artist_longitude'],
        'table': ['artist_id', 'name', 'location', 'latitude', 'longitude']
    },
    'songplays': {
        'json': ['level', 'location', 'userAgent', 'sessionId',
                 'itemInSession', 'userId', 'ts', 'song', 'artist', 'length'],
        'table': ['songplay_id', 'level', 'location', 'user_agent', 'session_id',
                  'user_id', 'song_id', 'artist_id', 'start_time', 'year', 'month']
    },
    'songs': {
        'json': ['song_id', 'title', 'year', 'duration', 'artist_id'],
        'table': ['song_id', 'title', 'year', 'duration', 'artist_id']
    },
    'time': {
        'json': ['ts'],
        'table': ['start_time', 'hour', 'day', 'week', 'month', 'year', 'weekday']
    },
    'users': {
        'json': ['userId', 'firstName', 'lastName', 'gender', 'level'],
        'table': ['user_id', 'first_name', 'last_name', 'gender', 'level']
    }
}
"""Defines the lists of columns for each table."""
