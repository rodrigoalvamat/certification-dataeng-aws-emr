"""Defines the lists of columns for each table."""

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
