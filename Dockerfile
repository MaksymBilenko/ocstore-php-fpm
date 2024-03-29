FROM php:5.6-fpm

RUN apt update

RUN apt install -y libxslt-dev zlib1g-dev libzip-dev libbz2-dev wget curl libmagick++-dev imagemagick

RUN wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && \
    tar xf ioncube_loaders_lin_x86-64.tar.gz && rm ioncube_loaders_lin_x86-64.tar.gz && \
    mv ioncube /opt/ioncube && \
    echo 'zend_extension = /opt/ioncube/ioncube_loader_lin_5.6.so' > /usr/local/etc/php/conf.d/00-ioncube.ini

RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/lib --with-freetype-dir=/usr/lib && \
    docker-php-ext-install -j $(nproc) mysql mysqli xsl zip bz2 opcache soap gd

RUN pecl install imagick && \
    echo 'extension=imagick.so' > /usr/local/etc/php/conf.d/imagick.ini

RUN echo "listen = /usr/local/var/run/php-fpm.sock\nlisten.mode = 0666\ncatch_workers_output = yes\nphp_admin_flag[log_errors] = on\npm.status_path = /status" > /usr/local/etc/php-fpm.d/zz-docker.conf

RUN echo "pm = dynamic \npm.max_children = 100 \npm.start_servers = 60 \npm.min_spare_servers = 40 \npm.max_spare_servers = 80 \npm.max_requests = 4000" >> /usr/local/etc/php-fpm.d/zz-docker.conf

RUN echo "upload_max_filesize = 128M;\npost_max_size = 128M\ndisplay_errors = Off\nmax_input_vars = 5000\nmax_allowed_packet=8M\nmax_execution_time=60\nmax_input_vars=10000\nmemory_limit=-1" > /usr/local/etc/php/conf.d/config.ini
RUN echo 'date.timezone=Europe/Kiev' >> /usr/local/etc/php/php.ini
