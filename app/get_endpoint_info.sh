#!/bin/sh

# curlがなぜかca-certificates.crtを読み込んでくれない問題のワークアラウンド
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

set -eu

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

jq -h > /dev/null 2>&1 || error 'jq が見つかりません'

URL="${1}"

## 短縮されたURLから元のURLを取得する
curl -sD - "${URL}" > "${tmp}"/original_location ||
  error 'original_location の取得に失敗しました'
grep '[Ll]ocation' < "${tmp}"/original_location |
  cut -d ' ' -f2  |
  tr -d '\r'      |
  sed 's/^hec-eye-camera:/https:/' > "${tmp}"/original_url

if [ -z "$(cat "${tmp}"/original_url)" ]; then
  error 'original_url を取得できていません'
fi

## エンドポイント情報を取得する
curl -sX POST "$(cat "${tmp}"/original_url)" > "${tmp}"/endpoint_json ||
  error 'endpoint_json の取得に失敗しました'
jq -r 'to_entries | map("\(.key): \(.value)") | .[]' < "${tmp}"/endpoint_json |
  tr -d '\r'

# ここで通常の終了処理
on_exit

# 異常終了時ハンドラの解除
trap '' EXIT
