#!/bin/bash

# get the full path of the script and its directory
SCRIPT_PATH="${BASH_SOURCE}"
while [ -L "${SCRIPT_PATH}" ]; do
  SCRIPT_DIR="$(cd -P "$(dirname "${SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
  SCRIPT_PATH="$(readlink "${SCRIPT_PATH}")"
  [[ ${SCRIPT_PATH} != /* ]] && SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_PATH}"
done
SCRIPT_PATH="$(readlink -f "${SCRIPT_PATH}")"
SCRIPT_DIR="$(cd -P "$(dirname -- "${SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"

# reads project config
PROJECT_DIR="${SCRIPT_DIR}/.."
source <(grep = "$PROJECT_DIR"/emr.cfg)

# get the full path of the script and its directory
APP_DIR="s3a://udacity-dataeng-emr/application/etl"

#--conf spark.dynamicAllocation.enabled=true \
#--conf spark.shuffle.service.enabled=true \
#--conf spark.yarn.submit.waitAppCompletion=false \
#--conf spark.driver.memoryOverhead=512 \
#--conf spark.executor.memoryOverhead=512 \

ssh -i "$KEYPAIR" "hadoop@$DNS" spark-submit --verbose \
             --master yarn \
             --deploy-mode cluster \
             "$APP_DIR/etl.py" \
             --py-files \
             "$APP_DIR/__init__.py" \
             "$APP_DIR/config.py" \
             "$APP_DIR/etl.cfg" \
             "$APP_DIR/metadata.py"