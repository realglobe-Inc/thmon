#!/bin/sh

image_url="http://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2020-05-28/2020-05-27-raspios-buster-lite-armhf.zip"
torrent_url="http://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2020-05-28/2020-05-27-raspios-buster-lite-armhf.zip.torrent"
archive="./2020-05-27-raspios-buster-lite-armhf.zip"
image="./2020-05-27-raspios-buster-lite-armhf.img"
sha256="f5786604be4b41e292c5b3c711e2efa64b25a5b51869ea8313d58da0b46afc64"

sudo printf ''  # sudoをいちどキックしておく

# ディスクイメージがなければダウンロードする
if ! [ -f "${image}" ] ; then
  if ! aria2c -h > /dev/null; then
    echo "aria2c をインストールしてください"
    exit 1
  fi
  aria2c --seed-time=1 "${torrent_url}"
  unzip "${archive}"
fi

while ! diskutil info /dev/disk2 > /dev/null; do
  echo "waiting /dev/disk2 ..."
  sleep 1
done
echo "/dev/disk2 found!"

diskutil unmountDisk /dev/disk2

echo "ディスクイメージを書き込みます..."
dd if="${image}" bs=1m | pv | sudo dd of=/dev/rdisk2 bs=1m
say 'オワッタヨ'

while :; do
  echo "waiting /Volumes/boot ..."
  test -d /Volumes/boot && break
  sleep 1
done
echo "/Volumes/boot found!"

touch /Volumes/boot/ssh
diskutil eject /dev/disk2
