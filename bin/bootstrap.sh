#!/bin/bash

# This bootstrap script is based on the AWS EMR recommendations to
# avoid the "small files problem" during Spark processing.
# It will generate the S3DistCp prefixes files called by the step functions
# declared in terraform (emr.tf) to avoid using Spark repartition or coalesce.
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
S3_PREFIX_DIR="s3://udacity-dataeng-emr/application/data/prefix"
PREFIX_DIR="$HOME/prefix"

# logs paths
LOGS_SOURCE="$SOURCE_BUCKET/log_data"
LOGS_PREFIX="$PREFIX_DIR/log_data_prefix.txt"

# songs paths
SONGS_SOURCE="$SOURCE_BUCKET/song_data"
SONGS_PREFIX="$PREFIX_DIR/song_data_prefix.txt"

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

# upload prefixes to S3
aws s3 cp "$PREFIX_DIR" "$S3_PREFIX_DIR" --recursive

# clean prefix dir
rm -rf "$PREFIX_DIR"
