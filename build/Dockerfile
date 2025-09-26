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
    cron \
    rsyslog \
    nano \
    vim \
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
    && mkdir -p /var/log/crontasks \
    && mkdir -p /www \
    && mkdir -p /etc/supervisor/conf.d \
    && mkdir -p /etc/crontasks \
    && mkdir -p /usr/local/bin/cron-scripts

# 创建 Nginx 配置目录
RUN mkdir -p /etc/nginx/conf.d

# 设置工作目录
WORKDIR /www

# 确保工作目录存在且权限正确
RUN mkdir -p /www && chown -R www-data:www-data /www

# 复制配置文件
COPY conf/php.ini /usr/local/etc/php/php.ini
COPY conf/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY supervisor/supervisor.d/ /etc/supervisor/conf.d/
COPY crontab-template.conf /etc/crontasks/crontab.conf

# 创建定时任务管理脚本
RUN echo '#!/bin/bash' > /usr/local/bin/cron-manager \
    && echo '# 定时任务管理脚本' >> /usr/local/bin/cron-manager \
    && echo 'CONFIG_FILE="/etc/crontasks/crontab.conf"' >> /usr/local/bin/cron-manager \
    && echo 'LOG_DIR="/var/log/crontasks"' >> /usr/local/bin/cron-manager \
    && echo 'case "$1" in' >> /usr/local/bin/cron-manager \
    && echo '  reload)' >> /usr/local/bin/cron-manager \
    && echo '    echo "重载定时任务..."' >> /usr/local/bin/cron-manager \
    && echo '    crontab -r 2>/dev/null || true' >> /usr/local/bin/cron-manager \
    && echo '    [ -f "$CONFIG_FILE" ] && crontab "$CONFIG_FILE"' >> /usr/local/bin/cron-manager \
    && echo '    echo "定时任务重载完成"' >> /usr/local/bin/cron-manager \
    && echo '    ;;' >> /usr/local/bin/cron-manager \
    && echo '  status)' >> /usr/local/bin/cron-manager \
    && echo '    echo "当前定时任务:"' >> /usr/local/bin/cron-manager \
    && echo '    crontab -l 2>/dev/null || echo "无定时任务"' >> /usr/local/bin/cron-manager \
    && echo '    ;;' >> /usr/local/bin/cron-manager \
    && echo '  auto-load)' >> /usr/local/bin/cron-manager \
    && echo '    echo "自动加载定时任务..."' >> /usr/local/bin/cron-manager \
    && echo '    [ -f "$CONFIG_FILE" ] && crontab "$CONFIG_FILE" && echo "配置文件自动加载完成" || echo "配置文件不存在"' >> /usr/local/bin/cron-manager \
    && echo '    ;;' >> /usr/local/bin/cron-manager \
    && echo '  *)' >> /usr/local/bin/cron-manager \
    && echo '    echo "用法: $0 {reload|status|auto-load}"' >> /usr/local/bin/cron-manager \
    && echo '    ;;' >> /usr/local/bin/cron-manager \
    && echo 'esac' >> /usr/local/bin/cron-manager \
    && chmod +x /usr/local/bin/cron-manager

# 创建启动脚本自动加载定时任务
RUN echo '#!/bin/bash' > /usr/local/bin/auto-load-cron \
    && echo '# 等待cron服务启动' >> /usr/local/bin/auto-load-cron \
    && echo 'sleep 5' >> /usr/local/bin/auto-load-cron \
    && echo '# 自动加载定时任务配置' >> /usr/local/bin/auto-load-cron \
    && echo '/usr/local/bin/cron-manager auto-load' >> /usr/local/bin/auto-load-cron \
    && chmod +x /usr/local/bin/auto-load-cron

# 注意：配置文件已通过 COPY 复制，不需要重复创建

# 复制cron脚本目录
COPY scripts/cron /usr/local/bin/cron-scripts

# 设置权限
RUN chown -R www-data:www-data /www \
    && chmod -R 777 /www \
    && chown -R www-data:www-data /var/log/php-fpm \
    && chown -R www-data:www-data /var/log/nginx \
    && chmod +x /usr/local/bin/cron-scripts/*.sh \
    && chown -R root:root /var/log/crontasks \
    && chmod -R 755 /var/log/crontasks \
    && chmod -R 644 /etc/crontasks \
    && chmod 755 /etc/crontasks

# 暴露端口
EXPOSE 80 9000

# 启动 supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
