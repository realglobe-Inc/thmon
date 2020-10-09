#!/bin/sh

#
# 使い方:
#   ./deploy.sh <target> <paring_url> <lat> <lng>
#

set -eu

: ${1}
: ${2}
: ${3}
: ${4}

target_host="${1}"
pairing_url="${2}"
lat="${3}"
lng="${4}"

pv --version > /dev/null || (echo "pvが見当たりません" >&2; exit 1)

./docker_build.sh
ssh "${target_host}" "sudo systemctl stop thmon.service"
docker image save thmon |
  pv |
  ssh "${target_host}" docker image load
./pairing.sh "${target_host}" "${pairing_url}"
./set_location.sh "${target_host}" "${lat}" "${lng}"
ssh "${target_host}" "sudo systemctl start thmon.service"

say 'オワッタヨ'
