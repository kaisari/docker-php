FROM php:8.1-fpm-alpine
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

# Install the PHP pdo_mysql extention
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Install the PHP soap extention
RUN apk add --update libxml2-dev php-soap && docker-php-ext-install soap

# Install the PHP Symfony Intl Component
RUN apk add --update icu-dev && docker-php-ext-configure intl && docker-php-ext-install intl

# Install the PHP gd library
RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev imagemagick-dev imagemagick \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && docker-php-ext-install -j${NPROC} gd \
    && git clone https://github.com/Imagick/imagick \
    && cd imagick \
    && phpize && ./configure \
    && make \
    && make install \
#    && echo "" | pecl install imagick \
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

RUN docker-php-ext-configure calendar && docker-php-ext-install calendar

# Install the PHP xdebug extention
RUN pecl install xdebug

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --filename=composer --install-dir=/bin
ENV PATH /root/.composer/vendor/bin:$PATH

#Octane
#RUN echo "" | pecl install swoole \
#    && apk add php-cli \
#    && docker-php-ext-install pcntl \
#    && touch /usr/local/etc/php/conf.d/swoole.ini \
#    && echo 'extension=swoole.so' > /usr/local/etc/php/conf.d/swoole.ini \
#    && apk add  --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.7/main/ nodejs=8.9.3-r1

COPY bashrc.sh /etc/profile.d/
ENV ENV="/etc/profile"

CMD php-fpm
