#!/bin/sh

set -eu

PLOT_INTERVAL=21600  # 6h

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

date="$(date +%s)"

curl -h > /dev/null 2>&1 || error 'curl が見つかりません'
jq -h > /dev/null 2>&1 || error 'jq が見つかりません'

endpoint_info="/var/local/thmon/DATA/endpoint_info"
image_url="$(cat "${endpoint_info}" | grep 'imageUrl: ' | cut -d ' ' -f 2 | tr -d '\r')"
name="$(cat "${endpoint_info}" | grep 'name: ' | cut -d ' ' -f 2- | tr -d '\r')"
token="$(cat "${endpoint_info}" | grep '^token: ' | cut -d ' ' -f 2 | tr -d '\r')"
#if [ -z "${info_url}" ] || [ -z "${token}" ]; then
if [ -z "${image_url}" ] || [ -z "${token}" ]; then
  error 'endpoint_info が正しくありません'
fi

## 過去6時間ぶんのCO2濃度履歴を取得する
tail -n 22000 /var/local/thmon/DATA/log/th/latest |
  tr -d '\r' |
  awk -v pt="$((date - 21600))" '$1 > pt' > "${tmp}"/th_last_6h
cut -d ' ' -f 1 < "${tmp}"/th_last_6h | TZ="JST-9" /workdir/app/utconv -r > "${tmp}"/th_last_6h.jstdate
sed -n 's/\(^[0-9][0-9]*\)\(.*\)\(temp=\)\([0-9][0-9]*\)\(.*$\)/\1 \4/p' < "${tmp}"/th_last_6h > "${tmp}"/th_last_6h.temp
sed -n 's/\(^[0-9][0-9]*\)\(.*\)\(hum=\)\([0-9][0-9]*\)\(.*$\)/\1 \4/p' < "${tmp}"/th_last_6h > "${tmp}"/th_last_6h.hum
paste "${tmp}"/th_last_6h.jstdate "${tmp}"/th_last_6h.temp "${tmp}"/th_last_6h.hum > "${tmp}"/th_last_6h.jstdate_temp_hum

## グラフを描画する
tail_date_t="${date}"
head_date_t="$((tail_date_t - PLOT_INTERVAL))"
tail_date="$(TZ="JST-9" /workdir/app/utconv -r ${tail_date_t})"
head_date="$(TZ="JST-9" /workdir/app/utconv -r ${head_date_t})"
echo "${head_date}" >&2
echo "${head_date_t}" >&2
tail_date_Y="$(echo "${tail_date}" | cut -c 1-4)"
tail_date_m="$(echo "${tail_date}" | cut -c 5-6)"
tail_date_d="$(echo "${tail_date}" | cut -c 7-8)"
tail_date_H="$(echo "${tail_date}" | cut -c 9-10 | sed 's/^0//')"
title="$(printf '%s のCO2濃度\\n(%s/%s/%s %s時現在, 過去6時間)' "${name}" "${tail_date_Y}" "${tail_date_m}" "${tail_date_d}" "${tail_date_H}")"
gnuplot -p <<EOF
# 共通の設定
set title "${title}"
set nokey
set timefmt "%Y%m%d%H%M%S"
# x軸の設定
set format x "%m/%d\n%k時"
set xdata time
set xrange ["${head_date}":"${tail_date}"]
set xtics "${head_date}", 3600
# y軸の設定
set ylabel 'CO2濃度(ppm)'
set yrange [300:2000]
# PNGの描画
set terminal pngcairo size 1024,768 font 'Verdana,22'
set output '${tmp}/graph.png'
plot '${tmp}/th_last_6h.jstdate_temp_hum' using 1:2 with lines lc '#0000ff'
EOF

cp "${tmp}"/graph.png /var/local/thmon/DATA/graph.png

## グラフ画像を送信する
curl -s -w '\n' -X POST -F "file=@${tmp}/graph.png" "${image_url}?token=${token}"

# ここで通常の終了処理
on_exit

# 異常終了時ハンドラの解除
trap '' EXIT
