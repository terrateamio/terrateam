FROM alpine:3.13

RUN apk add --no-cache aws-cli
RUN apk add --no-cache gmp
RUN apk add --no-cache libffi
RUN apk add --no-cache libressl3.1-libtls
RUN apk add --no-cache libtls-standalone
RUN apk add --no-cache nginx
RUN apk add --no-cache runit

RUN mkdir -p /usr/local/bin
RUN mkdir -p /etc/service/terrat
RUN mkdir -p /etc/service/nginx

COPY terrat.tar.gz /tmp/terrat.tar.gz
RUN tar -C / -zxvf /tmp/terrat.tar.gz

COPY service/terrat /etc/service/terrat/run
COPY service/nginx /etc/service/nginx/run

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080
EXPOSE 8081

CMD ["runsvdir", "/etc/service"]
