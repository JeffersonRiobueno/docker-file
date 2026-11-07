# ============================================
#   DOCKERFILE OPTIMIZADO - WORDPRESS PHP 8.4
# ============================================
# 8.4.27 corrige CVE-2026-109618 y CVE-2026-109619 (RCE, php.net 2026-10-21).
# No bajar de esta version. Construir con: docker build --pull
FROM php:8.4.27-apache

# -------------------------------------------------
# 1. Dependencias de runtime, compilación de extensiones PHP y limpieza
#    (los paquetes *-dev y el toolchain se compilan y se purgan en la misma capa)
# -------------------------------------------------
RUN set -eux; \
    apt-get update; \
    apt-get upgrade -y --no-install-recommends; \
    # herramientas y codecs de ImageMagick de runtime (svg, djvu, openexr...): se instalan primero para que queden marcadas como manuales
    apt-get install -y --no-install-recommends \
        ghostscript \
        vim less curl unzip \
        libmagickcore-7.q16-10-extra \
    ; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get install -y --no-install-recommends \
        libicu-dev \
        libfreetype6-dev \
        libjpeg-dev \
        libpng-dev \
        libwebp-dev \
        libmagickwand-dev \
        libzip-dev \
    ; \
    # Extensiones PHP requeridas por WordPress
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j"$(nproc)" \
        bcmath \
        exif \
        gd \
        intl \
        mysqli \
        pdo_mysql \
        zip; \
    pecl install imagick; \
    docker-php-ext-enable opcache imagick; \
    rm -rf /tmp/pear; \
    # Marca todo como auto, restaura lo manual previo y las librerias de runtime que usan las extensiones
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
    find /usr/local -type f \( -executable -o -name '*.so' \) -exec ldd '{}' ';' \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
        | sort -u \
        | xargs -r dpkg-query --search \
        | grep -v '^diversion' \
        | sed 's/: .*$//; s/, /\n/g' \
        | grep -v -E -- '-dev(:|$)' \
        | sort -u \
        | xargs -rt apt-mark manual; \
    # El toolchain de la imagen base (PHPIZE_DEPS) ya no hace falta: libc6-dev arrastra linux-libc-dev
    apt-mark auto autoconf dpkg-dev file g++ gcc libc6-dev make pkg-config re2c > /dev/null; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

# -------------------------------------------------
# 3. Configuración de OPcache (mejora rendimiento PHP)
# -------------------------------------------------
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=512'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.validate_timestamps=1'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# -------------------------------------------------
# 4. Configuración de errores PHP (seguridad)
# -------------------------------------------------
RUN { \
    echo 'display_errors = Off'; \
    echo 'display_startup_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_log = /dev/stderr'; \
    echo 'log_errors_max_len = 1024'; \
    echo 'ignore_repeated_errors = On'; \
    echo 'html_errors = Off'; \
    } > /usr/local/etc/php/conf.d/error-logging.ini

# -------------------------------------------------
# 5. Habilitar módulos de Apache y optimizar headers
# -------------------------------------------------
RUN set -eux; \
    a2enmod rewrite expires headers deflate remoteip; \
    { \
        echo 'RemoteIPHeader X-Forwarded-For'; \
        echo 'RemoteIPTrustedProxy 10.0.0.0/8'; \
        echo 'RemoteIPTrustedProxy 172.16.0.0/12'; \
        echo 'RemoteIPTrustedProxy 192.168.0.0/16'; \
        echo 'RemoteIPTrustedProxy 169.254.0.0/16'; \
        echo 'RemoteIPTrustedProxy 127.0.0.0/8'; \
    } > /etc/apache2/conf-available/remoteip.conf; \
    a2enconf remoteip

# -------------------------------------------------
# 6. Configuración de compresión y cache HTTP
# -------------------------------------------------
RUN { \
    echo '<IfModule mod_deflate.c>'; \
    echo '  AddOutputFilterByType DEFLATE text/plain text/html text/xml text/css text/javascript application/javascript application/json'; \
    echo '</IfModule>'; \
    echo '<IfModule mod_expires.c>'; \
    echo '  ExpiresActive On'; \
    echo '  ExpiresByType image/jpg "access plus 1 year"'; \
    echo '  ExpiresByType image/jpeg "access plus 1 year"'; \
    echo '  ExpiresByType image/gif "access plus 1 year"'; \
    echo '  ExpiresByType image/png "access plus 1 year"'; \
    echo '  ExpiresByType text/css "access plus 1 month"'; \
    echo '  ExpiresByType text/javascript "access plus 1 month"'; \
    echo '  ExpiresByType application/javascript "access plus 1 month"'; \
    echo '</IfModule>'; \
    echo '<IfModule mod_headers.c>'; \
    echo '  Header always set X-Content-Type-Options "nosniff"'; \
    echo '  Header always set X-Frame-Options "SAMEORIGIN"'; \
    echo '  Header always set X-XSS-Protection "1; mode=block"'; \
    echo '</IfModule>'; \
    } > /etc/apache2/conf-available/performance.conf; \
    a2enconf performance

# -------------------------------------------------
# 7. Ajustes de Apache (timeout y keep-alive)
# -------------------------------------------------
RUN { \
    echo 'ServerTokens Prod'; \
    echo 'ServerSignature Off'; \
    echo 'KeepAlive On'; \
    echo 'MaxKeepAliveRequests 100'; \
    echo 'KeepAliveTimeout 3'; \
    echo 'Timeout 30'; \
    echo 'Protocols http/1.1'; \
    } >> /etc/apache2/apache2.conf

# -------------------------------------------------
# 8. Configuración por defecto del sitio
# -------------------------------------------------
RUN { \
    echo '<Directory /var/www/html>'; \
    echo '  Options +FollowSymLinks'; \
    echo '  AllowOverride All'; \
    echo '  Require all granted'; \
    echo '</Directory>'; \
    } > /etc/apache2/conf-available/wordpress.conf; \
    a2enconf wordpress

# -------------------------------------------------
# 9. Permisos y limpieza final
# -------------------------------------------------
RUN chown -R www-data:www-data /var/www/html && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# -------------------------------------------------
# 10. CMD final
# -------------------------------------------------
CMD ["apache2-foreground"]
