#基础镜像
FROM alpine:latest

MAINTAINER ayamzh "ayamzh@126.com"

#时区变量
ENV TIMEZONE="Asia/Shanghai"

#设置语言 更新软件  设置时区
RUN export LANG=zh_CN.UTF-8 && apk update && apk upgrade && apk add --update tzdata
RUN echo $TIMEZONE > /etc/timezone && ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime


#安装nginx supervisor 等软件
RUN apk add --update nginx \
openssh \
supervisor \
git \
curl \
curl-dev \
make \
zlib-dev \
build-base \
zsh \
vim \
vimdiff \
wget \
sudo

#安装PHP7
RUN apk add --update php7 \
php7-dev \
php7-mysqlnd \
php7-pdo_mysql \
php7-mysqli \
php7-mcrypt \
php7-mbstring \
php7-openssl \
php7-json \
php7-redis \
php7-mysqli \
php7-gd \
php7-fpm \
php7-bcmath \
php7-tokenizer \
php7-gettext \
php7-iconv \
php7-curl \
php7-pear \
php7-phar \
php7-memcached \
php7-opcache \
php7-pcntl \
php7-posix \
php7-sockets



#安装yac扩展
RUN pecl install yac-2.0.2 && \
echo -e "[yac] \n\
extension=yac.so \n\
yac.enable=1 \n\
yac.keys_memory_size=4M \n\
yac.values_memory_size=64M \n\
yac.compress_threshold=-1 \n\
yac.enable_cli=0" > /etc/php7/conf.d/yac.ini && \
pecl clear-cache


