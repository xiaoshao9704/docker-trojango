#!/bin/sh
TAG=$1
if [[ "$TAG" == "" ]]
then
    TAG="latest"
fi

docker buildx build --platform linux/amd64,linux/arm64 -t xiaoshao97/trojan-server:$TAG $(cd $(dirname $0) && pwd -P) --push