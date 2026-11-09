FROM debian:bookworm

# 1. Actualizar repositorios e instalar herramientas (todo en una línea para optimizar capas)
RUN apt update && apt install -y nginx openssl vim curl

# 2. Crear la carpeta CORRECTA para los certificados y la del PID de NGINX
RUN mkdir -p /etc/nginx/ssl /var/run/nginx

# 3. Generar el certificado auto-firmado
RUN openssl req -x509 -nodes \
    -out /etc/nginx/ssl/inception.crt \
    -keyout /etc/nginx/ssl/inception.key \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=42/CN=vhedo-ga.42.fr/UID=vhedo-ga"

# 4. Ajustar permisos de la carpeta web
RUN chmod 755 /var/www/html
RUN chown -R www-data:www-data /var/www/html

# 5. Inyectar tu archivo de configuración
COPY conf/nginx.conf /etc/nginx/nginx.conf

# 6. El ancla de vida: Ejecutar NGINX en primer plano
CMD ["nginx", "-g", "daemon off;"]
