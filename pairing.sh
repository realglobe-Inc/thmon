#!/bin/sh

target="${1}"
pairing_url="${2}"

set -eu
: ${target}
: ${pairing_url}

ssh "${target}" "docker run --rm -v /var/local/thmon:/var/local/thmon thmon /workdir/app/pairing.sh \"${pairing_url}\""
