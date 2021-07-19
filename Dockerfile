FROM alpine:latest

WORKDIR /trojan

ENV CONFIG_PATH=/trojan/trojan-core/server.json

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

RUN apk update
RUN apk add nginx openssl certbot-nginx git go supervisor --no-cache

COPY ./lib /trojan/lib
COPY ./template /trojan/template

COPY ./supervisor/supervisord.conf /etc/supervisord.conf
COPY ./supervisor/conf.d /etc/supervisor/conf.d

RUN sh /trojan/lib/install.sh

RUN apk del go git

EXPOSE 443 80

CMD [ "sh", "/trojan/lib/start.sh" ]