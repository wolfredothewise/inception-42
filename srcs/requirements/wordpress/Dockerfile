FROM debian:bookworm

# 1. Install PHP 8.2 and necessary extensions
RUN apt update && apt install -y \
    php-fpm \
    php-mysql \
    mariadb-client \
    wget \
    curl \
    unzip

# 2. Install WP-CLI globally
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# 3. Create required directories
RUN mkdir -p /run/php /var/www/html && \
    chown -R www-data:www-data /var/www/html

# 4. Copy configuration and setup script
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup_wp.sh /usr/local/bin/setup_wp.sh
RUN chmod +x /usr/local/bin/setup_wp.sh

# 5. Set working directory and expose port
WORKDIR /var/www/html
EXPOSE 9000

# 6. Entry point
CMD ["/usr/local/bin/setup_wp.sh"]
