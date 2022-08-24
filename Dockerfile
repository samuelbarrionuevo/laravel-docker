FROM php:8.1-fpm-bullseye AS base

WORKDIR /data

ENV TZ=UTC \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8 \
  COMPOSER_ALLOW_SUPERUSER=1 \
  COMPOSER_HOME=/composer

COPY --from=composer:2.3 /usr/bin/composer /usr/bin/composer

RUN apt-get update \
  && apt-get -y install --no-install-recommends \
    locales \
    git \
    unzip \
    libzip-dev \
    libicu-dev \
    libonig-dev \
    libpq-dev \
    vim \
    nano \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8 \
  && localedef -f UTF-8 -i en_US en_US.UTF-8 \

  && composer config -g process-timeout 3600 \
  && composer config -g repos.packagist composer https://packagist.org

RUN docker-php-ext-install \
  pgsql \
  pdo_pgsql \
  bcmath \
  mbstring  \
  exif \
  pcntl && \
  docker-php-ext-enable pgsql \
  pdo_pgsql \
  bcmath \
  mbstring  \
  exif \
  pcntl 

RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash - \
  && apt-get install -y nodejs

FROM base AS development

COPY ./config/php.development.ini /usr/local/etc/php/php.ini

FROM development AS development-xdebug

RUN pecl install xdebug && \
  docker-php-ext-enable xdebug

COPY ./config/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

FROM base AS deploy

COPY ./src /data

EXPOSE 9000
