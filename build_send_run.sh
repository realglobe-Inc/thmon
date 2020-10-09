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
    ssh "${TARGET_HOST}" docker image load) &&
  ssh "${TARGET_HOST}" '
    sudo systemctl stop thmon.service;
    docker stop '"${CONTAINER_NAME}"';
    docker run -d --privileged --rm -v /var/local/thmon:/var/local/thmon --name '"${CONTAINER_NAME}"' thmon /sbin/init'
