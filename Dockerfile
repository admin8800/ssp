ARG PHP_VERSION=8.3
ARG SSP_REPO=https://github.com/Anankke/SSPanel-UIM.git
ARG SSP_BRANCH=master

FROM php:${PHP_VERSION}-cli-alpine AS builder

ARG SSP_REPO
ARG SSP_BRANCH

WORKDIR /app

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN apk add --no-cache \
        git \
        unzip \
        curl \
        yaml-dev \
        gmp-dev \
        libzip-dev \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis yaml \
    && docker-php-ext-enable redis yaml \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        mysqli \
        gmp \
        zip \
    && apk del .build-deps \
    && git clone --depth=1 -b ${SSP_BRANCH} ${SSP_REPO} . \
    && cp config/appprofile.example.php config/appprofile.php

COPY .config.php config/.config.php

RUN composer install \
        --no-dev \
        --prefer-dist \
        --optimize-autoloader \
        --no-interaction \
        --no-progress

FROM php:${PHP_VERSION}-fpm-alpine

WORKDIR /var/www/html

RUN apk add --no-cache \
        nginx \
        supervisor \
        dcron \
        tzdata \
        unzip \
        curl \
        icu-dev \
        libzip-dev \
        imap-dev \
        krb5-dev \
        openssl-dev \
        yaml-dev \
        oniguruma-dev \
        gmp-dev \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libxml2-dev \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis yaml \
    && docker-php-ext-enable redis yaml opcache \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        mysqli \
        bcmath \
        zip \
        imap \
        intl \
        mbstring \
        gmp \
        gd \
        soap \
    && apk del .build-deps

COPY --from=builder /app /var/www/html

COPY nginx.conf /etc/nginx/http.d/default.conf
COPY supervisord.conf /etc/supervisord.conf
COPY crontab /etc/crontabs/root

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && { \
        echo "memory_limit=2048M"; \
        echo "upload_max_filesize=100M"; \
        echo "post_max_size=100M"; \
        echo "date.timezone=Asia/Shanghai"; \
        echo "log_errors=On"; \
        echo "display_errors=Off"; \
        echo "display_startup_errors=Off"; \
        echo "error_reporting=E_ALL"; \
        echo "error_log=/proc/self/fd/2"; \
      } > /usr/local/etc/php/conf.d/custom.ini \
    && { \
        echo "opcache.enable=1"; \
        echo "opcache.enable_cli=1"; \
        echo "opcache.memory_consumption=128"; \
        echo "opcache.interned_strings_buffer=16"; \
        echo "opcache.max_accelerated_files=10000"; \
        echo "opcache.validate_timestamps=0"; \
        echo "opcache.jit_buffer_size=64M"; \
        echo "opcache.jit=tracing"; \
      } > /usr/local/etc/php/conf.d/opcache.ini \
    && { \
        echo "[global]"; \
        echo "error_log = /proc/self/fd/2"; \
        echo "log_level = notice"; \
        echo ""; \
        echo "[www]"; \
        echo "catch_workers_output = yes"; \
        echo "decorate_workers_output = no"; \
      } > /usr/local/etc/php-fpm.d/zz-log.conf \
    && sed -i 's|listen = 9000|listen = 127.0.0.1:9000|' /usr/local/etc/php-fpm.d/www.conf \
    && mkdir -p \
        /var/www/html/storage/framework/smarty/cache \
        /var/www/html/storage/framework/smarty/compile \
        /var/www/html/storage/framework/twig/cache \
        /var/www/html/public/clients \
    && chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && chmod -R 775 /var/www/html/storage /var/www/html/public/clients \
    && chmod 664 /var/www/html/config/.config.php /var/www/html/config/appprofile.php \
    && chmod 600 /etc/crontabs/root

ENV TZ=Asia/Shanghai

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
