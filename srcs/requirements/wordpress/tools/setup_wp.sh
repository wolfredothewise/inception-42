#!/bin/bash
set -e

# Wait for MariaDB to be fully ready before trying to connect
until mariadb -h mariadb -u "${SQL_USER}" -p"${SQL_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; do
  echo "Waiting for MariaDB..."
  sleep 2
done

# If wp-config.php doesn't exist, WordPress is not installed in the volume
if [ ! -f "/var/www/html/wp-config.php" ]; then
  echo "Downloading and configuring WordPress..."

  # Download WordPress core
  wp core download --allow-root

  # Create wp-config.php linking to MariaDB
  wp config create --allow-root \
    --dbname="${SQL_DATABASE}" \
    --dbuser="${SQL_USER}" \
    --dbpass="${SQL_PASSWORD}" \
    --dbhost="mariadb:3306"

  # Install the main site and Admin user
  wp core install --allow-root \
    --url="https://${DOMAIN_NAME}" \
    --title="${SITE_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}"

  # Create the second required user (Editor/Author)
  wp user create --allow-root \
    "${WP_USER_LOGIN}" \
    "${WP_USER_EMAIL}" \
    --user_pass="${WP_USER_PASSWORD}" \
    --role=author

  # Ensure correct permissions after installation
  chown -R www-data:www-data /var/www/html
fi

echo "Starting PHP-FPM..."
# Execute PHP-FPM in the foreground
exec /usr/sbin/php-fpm8.2 -F
