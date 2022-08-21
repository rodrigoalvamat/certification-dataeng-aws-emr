#!/bin/bash

# This bootstrap script is based on the AWS EMR recommendations to
# avoid the "small files problem" during Spark processing.
# It will copy and merge JSON files using the AWS S3 DistCop
# instead of using Spark repartition or coalesce.
# https://docs.aws.amazon.com/pt_br/emr/latest/ReleaseGuide/UsingEMR_s3distcp.html

# check if it is master node
if grep isMaster /mnt/var/lib/info/instance.json | grep false;
then
    echo "This is not master node, do nothing, exiting"
    exit 0
fi
echo "This is master, load file prefix list"

# root paths
SOURCE_BUCKET="s3://udacity-dend"
TARGET_DIR="s3://udacity-dataeng-emr/application/data/bronze"
PREFIX_DIR="$HOME/tmp-prefix"

# logs paths
LOGS_SOURCE="$SOURCE_BUCKET/log_data"
LOGS_PREFIX="$PREFIX_DIR/log_data_prefix.txt"
LOGS_TARGET="$TARGET_DIR/logs.json"

# songs paths
SONGS_SOURCE="$SOURCE_BUCKET/song_data"
SONGS_PREFIX="$PREFIX_DIR/song_data_prefix.txt"
SONGS_TARGET="$TARGET_DIR/songs.json"

# sed regexp to clean aws s3 ls output
REGEXP="s/.+[[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}[[:space:]]+[[:digit:]]+[[:space:]]{1}(.+)(\/|\/.+\.json)/s3:\/\/udacity-dend\/\1/g"

# temp dir to store prefix files
mkdir "$PREFIX_DIR"

# list all JSON log and song files and store in prefix txt files
aws s3 ls "$LOGS_SOURCE" --recursive > "$LOGS_PREFIX"
aws s3 ls "$SONGS_SOURCE" --recursive > "$SONGS_PREFIX"

# clean prefix files to get a list of directories
find "$PREFIX_DIR" -name '*.txt' -print0 | xargs -0 sed -i -r  "$REGEXP"

# remove duplicate lines
awk '!seen[$$0]++' "$LOGS_PREFIX" > tmp_logs.txt && mv tmp_logs.txt "$LOGS_PREFIX"
cat "$LOGS_PREFIX"
awk '!seen[$$0]++' "$SONGS_PREFIX" > tmp_songs.txt && mv tmp_songs.txt "$SONGS_PREFIX"
cat "$SONGS_PREFIX"

# s3 distributed copy and merge of the log_data JSON files
s3-dist-cp --src "$LOGS_SOURCE" --dest "$LOGS_TARGET" --srcPrefixesFile "$LOGS_PREFIX" --groupBy "'.*/(log_data)/.*'"

# s3 distributed copy and merge of the song_data JSON files
s3-dist-cp --src "$SONGS_SOURCE" --dest "$SONGS_TARGET" --srcPrefixesFile "$SONGS_PREFIX" --groupBy "'.*/(song_data)/.*'"

# clean prefix dir
rm -rf "$PREFIX_DIR"
