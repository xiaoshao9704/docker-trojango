#!/bin/sh
TAG=$1
if [ "$TAG" == "" ]
then
    TAG="latest"
fi

docker build -t xiaoshao97/trojan-server:$TAG $PWD