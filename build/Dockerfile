# 基于官方 PHP 8.3 FPM 镜像
FROM php:8.3-fpm

# 设置维护者信息
LABEL maintainer="your-email@example.com"
LABEL description="Custom PHP 8.3 + OpenResty environment with supervisord"

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 更新包列表并安装必要的软件包
RUN apt-get update && apt-get install -y \
    git \
    supervisor \
    wget \
    curl \
    gnupg2 \
    ca-certificates \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libbz2-dev \
    libgmp-dev \
    libreadline-dev \
    libssl-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    libsqlite3-dev \
    libedit-dev \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# 安装 PHP 扩展
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        bz2 \
        curl \
        gd \
        gettext \
        gmp \
        iconv \
        intl \
        mbstring \
        mysqli \
        opcache \
        pcntl \
        pdo \
        pdo_mysql \
        pdo_sqlite \
        posix \
        shmop \
        soap \
        sockets \
        zip

# 安装 Redis 扩展
RUN pecl install redis igbinary \
    && docker-php-ext-enable redis igbinary

# 安装 Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer

# 创建必要的目录
RUN mkdir -p /var/log/supervisor \
    && mkdir -p /var/log/php-fpm \
    && mkdir -p /var/log/nginx \
    && mkdir -p /www \
    && mkdir -p /etc/supervisor/conf.d

# 创建 Nginx 配置目录
RUN mkdir -p /etc/nginx/conf.d

# 设置工作目录
WORKDIR /www

# 复制配置文件
COPY conf/php.ini /usr/local/etc/php/php.ini
COPY conf/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY supervisor/supervisor.d/ /etc/supervisor/conf.d/

# 设置权限
RUN chown -R www-data:www-data /www \
    && chmod -R 755 /www \
    && chown -R www-data:www-data /var/log/php-fpm \
    && chown -R www-data:www-data /var/log/nginx

# 暴露端口
EXPOSE 80 9000

# 启动 supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
