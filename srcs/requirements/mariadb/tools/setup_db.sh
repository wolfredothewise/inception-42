#!/bin/bash
set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi

if [ ! -d "/var/lib/mysql/${SQL_DATABASE}" ]; then
  mysqld --user=mysql --skip-networking &
  pid=$!

  until mariadb-admin ping >/dev/null 2>&1; do
    sleep 1
  done

  mariadb <<EOF
CREATE DATABASE IF NOT EXISTS ${SQL_DATABASE};
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${SQL_DATABASE}.* TO '${SQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

  mariadb-admin -u root -p"${SQL_ROOT_PASSWORD}" shutdown
  wait $pid
fi

exec mysqld --user=mysql