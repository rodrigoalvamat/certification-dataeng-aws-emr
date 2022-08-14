#!/bin/bash

# copy the bucket files
aws s3 cp s3://udacity-dataeng-emr/application/bootstraps $HOME/bootstraps --recursive

# Set spark home (so that findspark finds spark)
echo '
# added by bootstrap.sh
# export SPARK_HOME=/usr/lib/spark
# export PYSPARK_PYTHON="/usr/bin/python3
# export PYSPARK_DRIVER_PYTHON="/usr/bin/python3"
' >> $HOME/.bashrc