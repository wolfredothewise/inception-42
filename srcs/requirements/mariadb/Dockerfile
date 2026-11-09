FROM debian:bookworm

# 1. Instalar el servidor y cliente de MariaDB
RUN apt update && apt install -y mariadb-server mariadb-client

# 2. Crear carpetas de runtime y asegurar permisos
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

# 3. Copiar la configuración personalizada y el script de inicialización
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/setup_db.sh /usr/local/bin/setup_db.sh

# 4. Dar permisos de ejecución al script
RUN chmod +x /usr/local/bin/setup_db.sh

EXPOSE 3306

# 5. Punto de entrada (PID 1)
ENTRYPOINT ["/usr/local/bin/setup_db.sh"]
