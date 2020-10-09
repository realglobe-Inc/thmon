#!/bin/sh

#
# pvのインストール:
#   brew install pv
#

set -eu

TARGET_HOST="${1}"
CONTAINER_NAME="thmon"

pv --version > /dev/null || (echo "pvが見当たりません" >&2; exit 1)

./docker_build.sh &&
  (docker image save thmon |
    pv |
    ssh "${TARGET_HOST}" docker image load)
