#!/bin/sh

#
# --load をつけないとbuildxでビルドしたイメージをMac側に引っ張ってこれない
#

docker buildx build --platform linux/arm/v7 --load -t thmon .
