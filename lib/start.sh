#!/bin/sh
if [ ! -f "$CONFIG_PATH" ]
then
    sh /trojan/lib/init.sh "all" "/trojan/cert" 
fi

supervisord -c /etc/supervisord.conf -n