#!/bin/sh

set -e

if [ ! -f "$CONFIG_PATH" ]
then
    echo "init config"
    sh /trojan/lib/init.sh "all" "/trojan/cert" 
fi

/trojan/trojan-core/trojan -config "$CONFIG_PATH"