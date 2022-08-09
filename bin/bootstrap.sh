#!/bin/bash

sudo amazon-linux-extras install epel -y
sudo yum install s3fs-fuse -y

sudo wget https://github.com/kahing/goofys/releases/latest/download/goofys -P /usr/bin/
sudo chmod ugo+x /usr/bin/goofys

# change the bucket name
aws s3 cp s3://udacity-dataeng-emr/application/bootstraps $HOME/bootstraps --recursive

# Set spark home (so that findspark finds spark)
echo '
# added by bootstrap.sh
export SPARK_HOME=/usr/lib/spark
' >> $HOME/.bashrc