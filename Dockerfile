FROM php:5.6-apache

RUN sed -i s/deb.debian.org/archive.debian.org/g /etc/apt/sources.list
RUN sed -i 's|security.debian.org|archive.debian.org/|g' /etc/apt/sources.list
RUN sed -i '/stretch-updates/d' /etc/apt/sources.list

RUN apt update && apt upgrade -y && \
    apt install -y libxslt-dev zlib1g-dev libzip-dev libbz2-dev wget curl libmagick++-dev imagemagick libmcrypt-dev cmake autoconf automake libtool nasm make pkg-config jpegoptim webp optipng libwebp-dev libvpx-dev && \
    apt clean && rm -rf /var/lib/apt/lists/*

RUN wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && \
    tar xf ioncube_loaders_lin_x86-64.tar.gz && rm ioncube_loaders_lin_x86-64.tar.gz && \
    mv ioncube /opt/ioncube && \
    echo 'zend_extension = /opt/ioncube/ioncube_loader_lin_5.6.so' > /usr/local/etc/php/conf.d/00-ioncube.ini

RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/lib --with-freetype-dir=/usr/lib --with-vpx-dir && \
    docker-php-ext-install -j $(nproc) mysql mysqli xsl zip bz2 opcache soap gd pdo_mysql mcrypt

RUN pecl install imagick && \
    echo 'extension=imagick.so' > /usr/local/etc/php/conf.d/imagick.ini

RUN pecl install memcache-2.2.7 && \
    docker-php-ext-enable memcache

RUN MAKEFLAGS="-j $(nproc)" pecl install redis-2.2.8 && \
    docker-php-ext-enable redis

RUN curl -L https://download.newrelic.com/php_agent/archive/10.10.0.1/newrelic-php5-10.10.0.1-linux.tar.gz | tar -C /tmp -zx \
    && export NR_INSTALL_USE_CP_NOT_LN=1 \
    && export NR_INSTALL_SILENT=1 \
    && /tmp/newrelic-php5-10.10.0.1-linux/newrelic-install install \
    && rm -rf /tmp/newrelic-php5-* /tmp/nrinstall*

RUN mkdir /tmp/mozjpeg && cd /tmp/mozjpeg &&\
    wget https://github.com/mozilla/mozjpeg/archive/refs/tags/v4.0.3.tar.gz -O mozjpeg-master.tar.gz &&\
    tar xvzf mozjpeg-master.tar.gz &&\
    cd mozjpeg-4.0.3/ &&\
    mkdir build && cd build &&\
    cmake -G"Unix Makefiles" -DPNG_SUPPORTED=ON ../ &&\
    make install &&\
    make deb &&\
    dpkg -i mozjpeg_4.0.3_amd64.deb &&\
    ln -s /opt/mozjpeg/bin/cjpeg /usr/bin/mozjpeg &&\
    ln -s /opt/mozjpeg/bin/jpegtran /usr/bin/mozjpegtran &&\
    cd / && rm -rf /tmp/mozjpeg

#RUN echo "listen = /usr/local/var/run/php-fpm.sock\nlisten.mode = 0666\ncatch_workers_output = yes\nphp_admin_flag[log_errors] = on\npm.status_path = /status" > /usr/local/etc/php-fpm.d/zz-docker.conf

#RUN echo "pm = dynamic \npm.max_children = 100 \npm.start_servers = 60 \npm.min_spare_servers = 40 \npm.max_spare_servers = 80 \npm.max_requests = 4000" >> /usr/local/etc/php-fpm.d/zz-docker.conf

RUN echo "upload_max_filesize = 128M;\npost_max_size = 128M\ndisplay_errors = Off\nmax_input_vars = 5000\nmax_allowed_packet=8M\nmax_execution_time=60\nmax_input_vars=10000\nmemory_limit=-1" > /usr/local/etc/php/conf.d/config.ini
RUN echo 'date.timezone=Europe/Kiev' >> /usr/local/etc/php/php.ini

RUN a2enmod socache_shmcb cgi proxy_fcgi suexec rewrite actions remoteip

LABEL org.opencontainers.image.source https://github.com/MaksymBilenko/ocstore-php-fpm
