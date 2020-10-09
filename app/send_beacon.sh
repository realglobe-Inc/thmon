#!/bin/sh

set -eu

# curlがなぜかca-certificates.crtを読み込んでくれない問題のワークアラウンド
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

on_exit() {
  rm -rf "${tmp}"
}

error_handler() {
  # エラー時の処理
  on_exit
}

cmdname=$(basename "${0}")
error() {
  printf '\e[31m%s: エラー: %s\e[m\n' "${cmdname}" "${1}" 1>&2
  printf '\e[31m%s: 終了します\e[m\n' "${cmdname}" 1>&2
  exit 1
}

trap error_handler EXIT

# ここで通常の処理
tmp="$(mktemp -d)"

curl -h > /dev/null 2>&1 || error 'curl が見つかりません'
jq -h > /dev/null 2>&1 || error 'jq が見つかりません'

endpoint_info="/var/local/co2mon/DATA/endpoint_info"
info_url="$(cat "${endpoint_info}" | grep '^infoUrl: ' | cut -d ' ' -f 2 | tr -d '\r')"
type="$(cat "${endpoint_info}" | grep '^type: ' | cut -d ' ' -f 2 | tr -d '\r')"
token="$(cat "${endpoint_info}" | grep '^token: ' | cut -d ' ' -f 2 | tr -d '\r')"
if [ -z "${info_url}" ] || [ -z "${token}" ]; then
  error 'endpoint_info が正しくありません'
fi

co2="$(tail -n 1 /var/local/co2mon/DATA/log/co2/latest | cut -d ' ' -f 2 | cut -d '=' -f 2 | cut -d ';' -f 1 | tr -d '\r')"
if tail -n 1 /var/local/co2mon/DATA/log/gps_tpv | grep '.'; then
  lat="$(tail -n 1 /var/local/co2mon/DATA/log/gps_tpv | cut -d ' ' -f 2 | jq -r .lat)"
  lng="$(tail -n 1 /var/local/co2mon/DATA/log/gps_tpv | cut -d ' ' -f 2 | jq -r .lon)"
  lat="$(tail -n 1 /var/local/co2mon/DATA/log/gps_tpv | cut -d ' ' -f 2 | jq -r .alt)"
elif cat /var/local/co2mon/DATA/location | grep '.'; then
  lat="$(cat /var/local/co2mon/DATA/location | cut -d ',' -f 1)"
  lng="$(cat /var/local/co2mon/DATA/location | cut -d ',' -f 2)"
  alt="$(cat /var/local/co2mon/DATA/location | cut -d ',' -f 3)"
else
  lat="0"
  lng="0"
  alt="0"
fi

printf '{"lat": %s, "lng": %s, "alt": %s}\n' "${lat}" "${lng}" "${alt}" |
  jq --arg type "default" '. + {"type": $type}' |
  jq --arg co2 "${co2}" '. + {"additional": {"info": {"co2": $co2}}}' |
  curl -s -w '\n' -H "Content-type: application/json" -d @- "${info_url}?token=${token}"

# ここで通常の終了処理
on_exit

# 異常終了時ハンドラの解除
trap '' EXIT
