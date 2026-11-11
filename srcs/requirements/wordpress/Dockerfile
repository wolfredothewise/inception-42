FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-zip php-intl \
    mariadb-client wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /run/php /var/www/wordpress

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup_wp.sh /usr/local/bin/setup_wp.sh
RUN chmod +x /usr/local/bin/setup_wp.sh

WORKDIR /var/www/wordpress
EXPOSE 9000
CMD ["/usr/local/bin/setup_wp.sh"]