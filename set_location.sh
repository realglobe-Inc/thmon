#!/bin/sh

#
# 使い方:
#   ./set_location.sh target lat lng
#

set -eu

: ${1}
: ${2}
: ${3}

target="${1}"
lat="${2}"
lng="${3}"

ssh "${target}" "docker run --rm -v /var/local/thmon:/var/local/thmon thmon /workdir/app/set_location.sh \"${lat}\" \"${lng}\""
