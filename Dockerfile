FROM alpine:latest

WORKDIR /trojan

ENV CONFIG_PATH /trojan/trojan-core/server.json
ENV DOMAIN ""
ENV PASS=""
ENV WEBSOCKET=""

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

RUN apk update
RUN apk add nginx openssl certbot-nginx git go supervisor --no-cache

COPY ./lib /trojan/lib
COPY ./template /trojan/template

COPY ./supervisor/supervisord.conf /etc/supervisord.conf
COPY ./supervisor/conf.d /etc/supervisor/conf.d

RUN git clone https://github.com/p4gefau1t/trojan-go.git /trojan/trojan-core && \
 cd /trojan/trojan-core && \
 go build -tags "full" -o trojan

RUN cp -f /trojan/template/nginx.conf /etc/nginx/http.d/default.conf && \
 mkdir -p /run/nginx

RUN apk del go git

EXPOSE 443 80

CMD [ "sh", "/trojan/lib/start.sh" ]