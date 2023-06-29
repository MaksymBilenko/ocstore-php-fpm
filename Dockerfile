FROM php:7.2-apache

RUN apt update && apt upgrade -y && \
    apt install -y libxslt-dev zlib1g-dev libzip-dev libbz2-dev wget curl libmagick++-dev imagemagick libmemcached-dev zlib1g-dev cmake autoconf automake libtool nasm make pkg-config jpegoptim optipng libvpx-dev libmcrypt-dev && \
    apt clean && rm -rf /var/lib/apt/lists/*

RUN wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && \
    tar xf ioncube_loaders_lin_x86-64.tar.gz && rm ioncube_loaders_lin_x86-64.tar.gz && \
    mv ioncube /opt/ioncube && \
    echo 'zend_extension = /opt/ioncube/ioncube_loader_lin_7.2.so' > /usr/local/etc/php/conf.d/00-ioncube.ini

RUN mkdir /tmp/webp && cd /tmp/webp && wget https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.3.1.tar.gz && \
    tar xf libwebp-1.3.1.tar.gz && cd libwebp-1.3.1 && \
    ./configure --prefix /usr && \
    make -j $(nproc) && \
    make install && \
    cd / && rm -rf /tmp/webp

RUN pecl channel-update pecl.php.net

RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/include/ --with-freetype-dir=/usr/include/ --with-webp-dir=/usr/include/ &&\
    docker-php-ext-install mysqli xsl zip bz2 opcache soap gd pdo_mysql

RUN MAKEFLAGS="-j $(nproc)" pecl install mcrypt && \
    docker-php-ext-enable mcrypt

RUN MAKEFLAGS="-j $(nproc)" pecl install imagick && \
    docker-php-ext-enable imagick

RUN MAKEFLAGS="-j $(nproc)" pecl install memcached && \
    docker-php-ext-enable memcached

RUN MAKEFLAGS="-j $(nproc)" pecl install memcache-4.0.5.2 && \
    docker-php-ext-enable memcache

RUN MAKEFLAGS="-j $(nproc)" pecl install redis && \
    docker-php-ext-enable redis

RUN MAKEFLAGS="-j $(nproc)" pecl install grpc && \
    docker-php-ext-enable grpc

RUN MAKEFLAGS="-j $(nproc)" pecl install protobuf && \
    docker-php-ext-enable protobuf

RUN pecl install --onlyreqdeps --nobuild apcu && \
    cd "$(pecl config-get temp_dir)/apcu" && \
    phpize && ./configure --disable-apcu-mmap && \
    make && make install && \
    docker-php-ext-enable apcu

RUN MAKEFLAGS="-j $(nproc)" pecl install apcu_bc && \
    echo 'extension=apc' > /usr/local/etc/php/conf.d/zdocker-php-ext-apc.ini

RUN curl -L https://download.newrelic.com/php_agent/archive/10.2.0.314/newrelic-php5-10.2.0.314-linux.tar.gz | tar -C /tmp -zx \
    && export NR_INSTALL_USE_CP_NOT_LN=1 \
    && export NR_INSTALL_SILENT=1 \
    && /tmp/newrelic-php5-10.2.0.314-linux/newrelic-install install \
    && rm -rf /tmp/newrelic-php5-* /tmp/nrinstall*

RUN mkdir /tmp/mozjpeg && cd /tmp/mozjpeg &&\
    wget https://github.com/mozilla/mozjpeg/archive/refs/tags/v4.1.1.tar.gz -O mozjpeg-master.tar.gz &&\
    tar xvzf mozjpeg-master.tar.gz &&\
    cd mozjpeg-4.1.1/ &&\
    mkdir build && cd build &&\
    cmake -G"Unix Makefiles" -DPNG_SUPPORTED=ON ../ &&\
    make install &&\
    make deb &&\
    dpkg -i mozjpeg_4.1.1_amd64.deb &&\
    ln -s /opt/mozjpeg/bin/cjpeg /usr/bin/mozjpeg &&\
    ln -s /opt/mozjpeg/bin/jpegtran /usr/bin/mozjpegtran &&\
    cd / && rm -rf /tmp/mozjpeg

#RUN echo "listen = /usr/local/var/run/php-fpm.sock\nlisten.mode = 0666\ncatch_workers_output = yes\nphp_admin_flag[log_errors] = on\npm.status_path = /status" > /usr/local/etc/php-fpm.d/zz-docker.conf

#RUN echo "pm = dynamic \npm.max_children = 100 \npm.start_servers = 60 \npm.min_spare_servers = 40 \npm.max_spare_servers = 80 \npm.max_requests = 4000" >> /usr/local/etc/php-fpm.d/zz-docker.conf

RUN echo "upload_max_filesize = 128M;\npost_max_size = 128M\ndisplay_errors = Off\nmax_input_vars = 5000\nmax_allowed_packet=8M\nmax_execution_time=60\nmax_input_vars=10000\nmemory_limit=-1" > /usr/local/etc/php/conf.d/config.ini
RUN echo 'date.timezone=Europe/Kiev' >> /usr/local/etc/php/php.ini

RUN a2enmod socache_shmcb cgi proxy_fcgi suexec rewrite actions remoteip

LABEL org.opencontainers.image.source https://github.com/MaksymBilenko/ocstore-php-fpm:7.2