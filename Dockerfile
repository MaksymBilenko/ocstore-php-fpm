FROM php:8.1-apache

RUN apt update && apt install -y libxslt-dev zlib1g-dev libzip-dev libbz2-dev wget curl libmagick++-dev imagemagick libmemcached-dev libwebp-dev zlib1g-dev && apt clean

RUN wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && \
    tar xf ioncube_loaders_lin_x86-64.tar.gz && rm ioncube_loaders_lin_x86-64.tar.gz && \
    mv ioncube /opt/ioncube && \
    echo 'zend_extension = /opt/ioncube/ioncube_loader_lin_8.1.so' > /usr/local/etc/php/conf.d/00-ioncube.ini

RUN docker-php-ext-configure gd --with-jpeg --with-freetype --with-webp &&\
    MAKEFLAGS="-j $(nproc)" docker-php-ext-install mysqli xsl zip bz2 opcache soap gd pdo_mysql ffi

RUN MAKEFLAGS="-j $(nproc)" pecl install imagick && \
    docker-php-ext-enable imagick

RUN MAKEFLAGS="-j $(nproc)" pecl install memcached && \
    docker-php-ext-enable memcached

RUN MAKEFLAGS="-j $(nproc)" pecl install memcache && \
    docker-php-ext-enable memcache

RUN MAKEFLAGS="-j $(nproc)" pecl install redis && \
    docker-php-ext-enable redis

RUN MAKEFLAGS="-j $(nproc)" pecl install grpc && \
    docker-php-ext-enable grpc

RUN MAKEFLAGS="-j $(nproc)" pecl install protobuf && \
    docker-php-ext-enable protobuf

RUN MAKEFLAGS="-j $(nproc)" pecl install opentelemetry-beta && \
    docker-php-ext-enable opentelemetry

RUN echo "upload_max_filesize = 128M;\npost_max_size = 128M\ndisplay_errors = Off\nmax_input_vars = 5000\nmax_allowed_packet=8M\nmax_execution_time=60\nmax_input_vars=10000\nmemory_limit=-1" > /usr/local/etc/php/conf.d/config.ini
RUN echo 'date.timezone=Europe/Kiev' >> /usr/local/etc/php/php.ini

RUN a2enmod socache_shmcb cgi proxy_fcgi suexec rewrite actions remoteip

LABEL org.opencontainers.image.source https://github.com/MaksymBilenko/ocstore-php-fpm
