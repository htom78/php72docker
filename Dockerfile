#1.Base Image
FROM php:7.2-fpm-alpine

# ensure www-data user exists
#RUN set -x \
#	&& addgroup -g 82  -S www-data \
#	&& adduser -u 82 -D -S -G www-data www-data

# Environments
ENV TIMEZONE            Asia/Shanghai
ENV PHP_MEMORY_LIMIT    512M
ENV MAX_UPLOAD          50M
ENV PHP_MAX_FILE_UPLOAD 200
ENV PHP_MAX_POST        100M
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV CODE_PATH /usr/share/nginx/html
ENV PHP_ENV_FILE .env_production

#安装基本工具
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

#2.ADD-PHP-FPM
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN apk update && apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    curl-dev \
    imagemagick-dev \
    libtool \
    libxml2-dev \
    postgresql-dev \
    sqlite-dev \
    libmcrypt-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    shadow \
    libpng-dev \
  && wget https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh -O - | sh \
  && apk add --no-cache \
    curl \
    imagemagick \ 
    mysql-client \
    postgresql-libs \
  && pecl install mcrypt-1.0.1 \
  && pecl install yac-2.0.2 \
  && docker-php-ext-install zip \
  && docker-php-ext-install pdo_mysql \
  && docker-php-ext-install opcache \
  && docker-php-ext-install mysqli \
  && docker-php-ext-enable mcrypt \
  && docker-php-ext-enable yac \
  && docker-php-ext-install \
    curl \
    mbstring \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    pcntl \
    tokenizer \
    xml \
    zip \
    && docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" iconv \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" gd \
  && pecl install -o -f redis \
  && rm -rf /tmp/pear \
  && docker-php-ext-enable redis \
  && rm -r /var/cache/apk/* 

RUN mkdir -p /usr/local/var/log/php7/
RUN mkdir -p /usr/local/var/run/
COPY docker/php/php-fpm.conf /etc/php7/
COPY docker/php/php-fpm.conf /usr/local/etc/
COPY docker/php/www.conf /etc/php7/php-fpm.d/

#RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing gnu-libiconv
#ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php
#RUN rm -rf /var/cache/apk/*

# Set environments
RUN sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /usr/local/etc/php/php.ini-production && \
       sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /usr/local/etc/php/php.ini-production && \
       sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|i" /usr/local/etc/php/php.ini-production && \
       sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /usr/local/etc/php/php.ini-production && \
       sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /usr/local/etc/php/php.ini-production && \
       sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /usr/local/etc/php/php.ini-production

#3.Install-Composer
RUN curl -sS https://getcomposer.org/installer | \
    php -- --install-dir=/usr/bin/ --filename=composer


#4.ADD-NGINX
RUN apk add nginx
COPY docker/nginx/conf.d/default.conf /etc/nginx/conf.d/
COPY docker/nginx/nginx.conf /etc/nginx/
COPY docker/nginx/cert/ /etc/nginx/cert/

RUN mkdir -p /usr/share/nginx/html/public/
COPY docker/php/index.php /usr/share/nginx/html/public/
#RUN mkdir -p /run/nginx
#RUN touch /run/nginx/nginx.pid
# Expose volumes

VOLUME ["/usr/share/nginx/html", "/usr/local/var/log/php7", "/var/run/"]
WORKDIR /usr/share/nginx/html


#5.ADD-SUPERVISOR
RUN apk add supervisor \
 && rm -rf /var/cache/apk/*

# Define mountable directories.
VOLUME ["/etc/supervisor/conf.d", "/var/log/supervisor/"]
COPY docker/supervisor/conf.d/ /etc/supervisor/conf.d/

#6.ADD-CRONTABS
COPY docker/crontabs/default /var/spool/cron/crontabs/
RUN cat /var/spool/cron/crontabs/default >> /var/spool/cron/crontabs/root
RUN mkdir -p /var/log/cron \
 && touch /var/log/cron/cron.log

VOLUME /var/log/cron

#9.添加启动脚本
# Define working directory.
WORKDIR /usr/share/nginx/html
COPY docker/entrypoint.sh /usr/share/nginx/
RUN chmod +x /usr/share/nginx/entrypoint.sh

#CMD ["supervisord", "--nodaemon", "--configuration", "/etc/supervisor/conf.d/supervisord.conf"]
ENTRYPOINT ["/usr/share/nginx/entrypoint.sh"]

EXPOSE 80
