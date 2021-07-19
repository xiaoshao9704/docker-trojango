#!/bin/sh
set -e

if [ "$(uname)" != "Linux" ]
then
    echo "error: This operating system is not supported."
    exit 1
fi

build_trojan() {
    git clone https://github.com/p4gefau1t/trojan-go.git /trojan/trojan-core
    cd /trojan/trojan-core
    go build -tags "full" -o trojan
}

set_nginx() {
    cp -f /trojan/template/nginx.conf /etc/nginx/http.d/default.conf
    mkdir -p /run/nginx
}

set_bbr() {
    if [ "$BBR" != ""  ]
    then
        echo -e "net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
    fi
}

build_trojan
set_nginx
set_bbr