# ============================================
#   DOCKERFILE OPTIMIZADO - WORDPRESS PHP 8.3
# ============================================
FROM php:8.3-apache

# -------------------------------------------------
# 1. Instalación de dependencias necesarias
# -------------------------------------------------
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libicu-dev \
        libfreetype6-dev \
        libjpeg-dev \
        libpng-dev \
        libwebp-dev \
        libmagickwand-dev \
        libzip-dev \
        ghostscript \
        vim less curl unzip \
    ; \
    rm -rf /var/lib/apt/lists/*

# -------------------------------------------------
# 2. Extensiones PHP requeridas por WordPress
# -------------------------------------------------
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j$(nproc) \
        bcmath \
        exif \
        gd \
        intl \
        mysqli \
        pdo_mysql \
        zip; \
    pecl install imagick; \
    docker-php-ext-enable opcache imagick

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
    echo 'opcache.fast_shutdown=1'; \
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
