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
source <(grep = "$PROJECT_DIR"/config/emr.cfg)

# get the full path of the script and its directory
APP_DIR="s3://udacity-dataeng-emr/application/dist"

ssh -i "$KEYPAIR" "hadoop@$DNS" spark-submit \
  --py-files "$APP_DIR/datadiver_aws_emr-0.1.0-py3-none-any.whl" \
  "$APP_DIR/driver.py" main
