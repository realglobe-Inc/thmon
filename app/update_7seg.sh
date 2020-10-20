#!/bin/sh

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

stty -F "/dev/serial/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2:1.0" raw 9600

th="$(tail -n 1 /var/local/thmon/DATA/log/th/latest |
  cut -d ' ' -f 2 |
  tr -d '\r' |
  sed -n 's/\(^.*\)\(temp=\)\([0-9][0-9]*\)\(.*$\)/\3/p')"
if [ -n "${th}" ]; then
  echo $th > "/dev/serial/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2:1.0"
fi

# ここで通常の終了処理
on_exit

# 異常終了時ハンドラの解除
trap '' EXIT
