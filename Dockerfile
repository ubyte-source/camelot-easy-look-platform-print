FROM amd64/alpine:3.16

ENV STARTUP_COMMAND_RUN_PHP="php-fpm81 -F" \
    STARTUP_COMMAND_RUN_NGINX="nginx" \
    CHROME_BIN="/usr/bin/chromium-browser" \
    CHROME_PATH="/usr/lib/chromium/"

ARG APPLICATION="chrome" \
    PHP_FPM_USER="www" \
    PHP_FPM_GROUP="www" \
    PHP_FPM_LISTEN_MODE="0660" \
    PHP_MEMORY_LIMIT="32M" \
    PHP_MAX_UPLOAD="4M" \
    PHP_MAX_FILE_UPLOAD="1" \
    PHP_MAX_POST="8M" \
    PHP_DISPLAY_ERRORS="On" \
    PHP_DISPLAY_STARTUP_ERRORS="On" \
    PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR" \
    PHP_FPM_CLEAR_ENVIRONMENT="no" \
    PHP_CGI_FIX_PATHINFO="0" \
    TIMEZONE="UTC"

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" > /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/v3.12/main" >> /etc/apk/repositories && \
    apk upgrade -U -a && \
    apk add --no-cache nginx ghostscript poppler-utils bash grep && \
    apk add --no-cache php81-fpm php81-openssl php81-zip php81-curl php81-ctype php81-common php81-mbstring php81-fileinfo && \
    apk add --no-cache alsa-lib at-spi2-atk at-spi2-core atk cairo cups-libs dbus-libs eudev-libs expat ffmpeg-libs flac font-opensans fontconfig freetype glib gtk+3.0 harfbuzz lcms2 libatomic && \
    apk add --no-cache libdrm libevent libgcc libjpeg-turbo libpng libpulse libstdc++ libwebp libx11 libxcb libxcomposite libxdamage libxext libxfixes libxkbcommon libxml2 libxrandr libxslt && \
    apk add --no-cache mesa-gbm musl nspr nss opus pango re2 snappy wayland-libs-client xdg-utils zlib && \
    apk add --no-cache harfbuzz font-noto-emoji wqy-zenhei chromium wait4ports ttf-freefont chromium-chromedriver chromium-lang chromium-angle chromium-swiftshader && \
    apk add --no-cache tzdata && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /app && \
    mkdir -p /rendering

COPY ./ /app
COPY ./wrapper.sh /wrapper.sh
COPY ./local.conf /etc/fonts/local.conf
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./ssl/certificate.key /etc/ssl/certificate.key
COPY ./ssl/certificate.pem /etc/ssl/certificate.pem

RUN adduser -D -g www www && \
    chown -R www:www /var/lib/nginx /var/log/nginx /app /var/log/php81 && \
    chmod +x /wrapper.sh /app/rendering.sh && \
    rm -Rf /app/ssl /app/wrapper.sh /app/nginx.conf /app/local.conf /etc/nginx/sites-enabled /etc/nginx/sites-available && \
    cp -r /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "127.0.0.1 ${APPLICATION}.energia-europa.com" >> /etc/hosts && \
    echo "${TIMEZONE}" > /etc/timezone

RUN sed -i "s|;*listen.owner\s*=\s*.*|listen.owner = ${PHP_FPM_USER}|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*listen.group\s*=\s*.*|listen.group = ${PHP_FPM_GROUP}|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*listen.mode\s*=\s*.*|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*clear_env\s*=\s*.*|clear_env = ${PHP_FPM_CLEAR_ENVIRONMENT}|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*user\s*=\s*.*|user = ${PHP_FPM_USER}|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*group\s*=\s*.*|group = ${PHP_FPM_GROUP}|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*log_level\s*=\s*.*|log_level = notice|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*display_errors\s*=\s*.*|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php81/php.ini && \
    sed -i "s|;*display_startup_errors\s*=\s*.*|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php81/php.ini && \
    sed -i "s|;*error_reporting\s*=\s*.*|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php81/php.ini && \
    sed -i "s|;*memory_limit\s*=\s*.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php81/php.ini && \
    sed -i "s|;*upload_max_filesize\s*=\s*.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php81/php.ini && \
    sed -i "s|;*max_file_uploads\s*=\s*.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php81/php.ini && \
    sed -i "s|;*post_max_size\s*=\s*.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php81/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo\s*=\s*.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php81/php.ini && \
    sed -i "s|;*date.timezone\s*=\s*.*|date.timezone = ${TIMEZONE}|i" /etc/php81/php.ini

EXPOSE 8080 8443

WORKDIR /usr/src/app

USER www

ENTRYPOINT /wrapper.sh
