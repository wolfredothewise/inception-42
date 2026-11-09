#!/bin/bash
set -e

# Solo inicializa los usuarios si la base de datos no existe previamente en el volumen
if [ ! -d "/var/lib/mysql/${SQL_DATABASE}" ]; then
  service mariadb start

  # Esperar a que la base de datos responda antes de lanzar los comandos SQL
  until mariadb-admin ping >/dev/null 2>&1; do
    sleep 1
  done

  # Inyección de usuarios y base de datos usando las variables del .env
  mariadb -e "CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;"
  mariadb -e "CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'%' IDENTIFIED BY '${SQL_PASSWORD}';"
  mariadb -e "GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%';"
  mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';"
  mariadb -e "FLUSH PRIVILEGES;"

  mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown
fi

# Mantener el proceso MariaDB en primer plano (PID 1)
exec mysqld_safe
