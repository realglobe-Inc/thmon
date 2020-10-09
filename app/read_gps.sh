#!/bin/sh

echo "read_gps.sh started" >&2

# rotateは別プロセスで
log_dir="/var/local/co2mon/DATA/log"
log="${log_dir}/gps_tpv"

mkdir -p "${log_dir}"

gpspipe -w |
  jq -c --unbuffered 'select(.class == "TPV")' |
  while read -r l; do
    printf '%s %s\n' "$(date +%s)" "${l}"
  done >> "${log}"
