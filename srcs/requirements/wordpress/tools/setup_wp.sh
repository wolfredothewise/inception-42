#!/bin/bash
set -e


until mariadb -h mariadb -u "${SQL_USER}" -p"${SQL_PASSWORD}" "${SQL_DATABASE}" -e "SELECT 1;" >/dev/null 2>&1; do
  echo "Waiting for MariaDB..."
  sleep 2
done

cd /var/www/wordpress

[ -f wp-settings.php ] || wp core download --allow-root

[ -f wp-config.php ] || wp config create --allow-root \
  --dbname="${SQL_DATABASE}" \
  --dbuser="${SQL_USER}" \
  --dbpass="${SQL_PASSWORD}" \
  --dbhost="mariadb:3306"

if ! wp core is-installed --allow-root; then
  wp core install --allow-root \
    --url="https://${DOMAIN_NAME}" \
    --title="${SITE_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}"
fi

wp user get "${WP_USER_LOGIN}" --allow-root >/dev/null 2>&1 || \
  wp user create --allow-root "${WP_USER_LOGIN}" "${WP_USER_EMAIL}" \
    --user_pass="${WP_USER_PASSWORD}" --role=author

chown -R www-data:www-data /var/www/wordpress

exec /usr/sbin/php-fpm8.2 -F