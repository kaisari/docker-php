FROM php:7.2-fpm-alpine
LABEL mantainer="Cesar Vieira <cesar@kaisari.com.br>"

RUN apk add --update \
        openssh \
        curl \
        git \
        libmemcached-dev \
        libpng-dev \
        libmcrypt-dev \
        unzip \
        zip \
        libzip-dev \
        gettext \
        libintl \
        exiftool \
        openssl-dev \
        libmcrypt-dev \
        gettext \
        $PHPIZE_DEPS

ENV MUSL_LOCALE_DEPS cmake make musl-dev gcc gettext-dev libintl
ENV MUSL_LOCPATH /usr/share/i18n/locales/musl
RUN apk add --no-cache $MUSL_LOCALE_DEPS \
    && wget https://gitlab.com/rilian-la-te/musl-locales/-/archive/master/musl-locales-master.zip \
    && unzip musl-locales-master.zip \
    && cd musl-locales-master \
    && cmake -DLOCALE_PROFILE=OFF -D CMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install \
    && cd .. && rm -r musl-locales-master

# Install the PHP mcrypt extention
RUN echo "" | pecl install mcrypt-1.0.1 && docker-php-ext-enable mcrypt.so

# Install the PHP pdo_mysql extention
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Install the PHP soap extention
RUN apk add --update libxml2-dev php-soap && docker-php-ext-install soap

# Install the PHP Symfony Intl Component
RUN apk add --update icu-dev && docker-php-ext-configure intl && docker-php-ext-install intl

# Install the PHP gd library
RUN apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) gd
RUN apk add --update --no-cache autoconf g++ imagemagick imagemagick-dev libtool make pcre-dev \
    && echo "" | pecl install imagick \
    && docker-php-ext-enable imagick

# Install the PHP zip extention
RUN docker-php-ext-install zip && docker-php-ext-enable zip

# Install exif
RUN docker-php-ext-configure exif && docker-php-ext-install exif && docker-php-ext-enable exif

# Install BCMath
RUN docker-php-ext-install bcmath

# Install OPcache
RUN docker-php-ext-install opcache

# Install Sockets
RUN docker-php-ext-install sockets

# MongoDB
RUN pecl install mongodb && docker-php-ext-enable mongodb

# Install the PHP xdebug extention
RUN pecl install xdebug-2.9.8 && docker-php-ext-enable xdebug

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --filename=composer --install-dir=/bin
ENV PATH /root/.composer/vendor/bin:$PATH

COPY bashrc.sh /etc/profile.d/
ENV ENV="/etc/profile"

CMD php-fpm