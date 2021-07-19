#!/bin/sh

set -e

set_config() {
    echo "config path: $CONFIG_PATH"
    cp -f /trojan/template/server.json.template $CONFIG_PATH
    sed -i "s/{{PASS}}/$PASS/g" $CONFIG_PATH
    sed -i "s/{{HOST}}/$HOST/g" $CONFIG_PATH
    sed -i "s/{{WEBSOCKET}}/$WEBSOCKET/g" $CONFIG_PATH
    sed -i "s/{{CONFIG_PATH}}/$CONFIG_PATH/g" /etc/supervisor/conf.d/trojan.ini
}

set_bbr() {
    if [ "$BBR" != ""  ]
    then
        echo -e "net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
    fi
}

set_password() {
    if [ "$PASS" == "" ]
    then
        PASS="$(md5sum /proc/sys/kernel/random/uuid | cut -d ' ' -f1)"
    fi
    rm -f /trojan/password
    echo "$PASS" > /trojan/password
}

set_host() {
    if [ "$DOMAIN" == "" ]
    then
        HOST="$(md5sum /proc/sys/kernel/random/uuid | cut -d ' ' -f1)"
    else
        HOST=$DOMAIN
    fi
    rm -f /trojan/host
    echo "$HOST" > /trojan/host
}

set_ws() {
    if [ "$WEBSOCKET" == "" ]
    then
        WEBSOCKET="$(md5sum /proc/sys/kernel/random/uuid | cut -d ' ' -f1)"
    fi
    rm -f /trojan/websocket
    echo "$WEBSOCKET" > /trojan/websocket
}

self_signature() {
    rm -rf $TARGET/key $TARGET/cert
    ORGANIZATION="$(md5sum /proc/sys/kernel/random/uuid | cut -d ' ' -f1)"
    openssl req -newkey rsa:2048 -nodes -keyout $TARGET/key_$ORGANIZATION.pem -x509 -days 3650 -subj "/C=HK/ST=Tuen Mun District/L=Tuen Mun District/O=$ORGANIZATION/OU=$ORGANIZATION Software/CN=$HOST/emailAddress=software@$ORGANIZATION.com" -out $TARGET/cert_$ORGANIZATION.pem
    ln -s $TARGET/key_$ORGANIZATION.pem $TARGET/key
    ln -s $TARGET/cert_$ORGANIZATION.pem $TARGET/cert
}

certbot_signature() {
    rm -rf $TARGET/key $TARGET/cert
    certbot certonly --nginx -n -d $HOST --agree-tos --keep --email "$(md5sum /proc/sys/kernel/random/uuid | cut -d ' ' -f1)@gmail.com"
    ln -s /etc/letsencrypt/live/$HOST/fullchain.pem $TARGET/cert
    ln -s /etc/letsencrypt/live/$HOST/privkey.pem $TARGET/key
    
    set_auto_renew
}

set_auto_renew() {
    # set auto renew
    if [ ! -f /etc/periodic/daily/auto_cert ]
    then
        cp /trojan/template/auto_cert /etc/periodic/daily/auto_cert
        chmod +x /etc/periodic/daily/auto_cert
    else
        echo "auto_cert cron has exist"
    fi
}

renew_cert() {
    if [ ! -f $TARGET/cert -o ! -f $TARGET/key ]
    then
        echo "not found cert"
        exit 1
    fi

    OLD_KEY="$(md5sum $TARGET/key)"
    certbot renew
    NEW_KEY="$(md5sum $TARGET/key)"

    if [ "$OLD_KEY" == "$NEW_KEY" ]
    then
        echo "not need renew"
        exit
    fi

    supervisorctl restart trojan
}

set_cert() {
    if [ -f $TARGET/cert -a -f $TARGET/key ]
    then
        return
    fi

    rm -rf $TARGET
    mkdir -p $TARGET
    
    if [ "$DOMAIN" == "" ]
    then
        self_signature
    else
        certbot_signature
    fi
    cp -f /trojan/template/nginx.conf /etc/nginx/http.d/default.conf
    sed -i 's/#//g' /etc/nginx/http.d/default.conf
    supervisorctl restart nginx
}

TARGET="$2"

case $1 in
    'cert')
        set_cert
        ;;
    'renew_cert')
        renew_cert
        ;;
    'cert_self')
        self_signature
        ;;
    'certbot_signature')
        certbot_signature
        ;;
    *)
        set_password
        set_host
        set_ws
        set_cert
        set_config
        set_bbr
        ;;
esac