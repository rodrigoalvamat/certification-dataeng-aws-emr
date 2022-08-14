#!/bin/bash

# get the full path of the script and its directory
APP_DIR="s3a://udacity-dataeng-emr/application/src/etl"

spark-submit --master yarn \
             --deploy-mode cluster \
             --conf spark.dynamicAllocation.enabled=true \
             --conf spark.shuffle.service.enabled=true \
             --conf spark.yarn.submit.waitAppCompletion=false \
             --verbose \
             "$APP_DIR/etl.py" \
             --py-files \
             "$APP_DIR/config.py" \
             "$APP_DIR/metadata.py"