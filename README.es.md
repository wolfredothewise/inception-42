*vhedo-ga*

# Inception

## Descripción

Inception es una infraestructura web de tres capas construida con imágenes
Docker propias sobre Debian Bookworm. Docker Compose coordina:

- **NGINX**: única entrada pública, HTTPS en el puerto `443`, con TLS 1.2 y
  TLS 1.3.
- **WordPress + PHP-FPM**: aplicación PHP en la red privada de Docker.
- **MariaDB**: base de datos de WordPress, sin puertos publicados en el host.

Los servicios se comunican por la red bridge `inception`. Los datos persisten
en `/home/vhedo-ga/data/wordpress` y `/home/vhedo-ga/data/mariadb`. Las
variables y credenciales se guardan en `srcs/.env`, que no debe subirse al
repositorio.

```text
Navegador
    |
    | HTTPS :443
    v
 NGINX ---> WordPress/PHP-FPM :9000 ---> MariaDB :3306
                 (red bridge de Docker)
```

## Estructura

```text
.
├── Makefile
├── README.md
├── README.es.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        ├── wordpress/
        └── mariadb/
```

Cada servicio tiene su propio Dockerfile. El proceso principal se ejecuta en
primer plano y actúa como PID 1 del contenedor.

## Instrucciones

Necesitas Debian Bookworm (o compatible), Docker Engine con el plugin Compose,
Git y esta entrada en `/etc/hosts`:

```text
127.0.0.1 vhedo-ga.42.fr
```

Desde la raíz del proyecto:

```bash
cp .env.example srcs/.env
# Edita srcs/.env y cambia todas las contraseñas de ejemplo.
make
```

Abre `https://vhedo-ga.42.fr`. El certificado es autofirmado y el navegador
mostrará una advertencia local.

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs --tail=50
make down       # detener; conserva los datos
make clean      # eliminar contenedores, red y volúmenes Compose
make fclean     # limpieza completa, incluidos los datos del host
make re         # fclean y arranque desde cero
```

`make fclean` borra los datos de WordPress y MariaDB en
`/home/vhedo-ga/data`; úsalo solo para una instalación limpia.

## Recursos y uso de IA

- [Subject de Inception](https://github.com/wolfredothewise/obsidian-vault/blob/f9eca1f87e8d4e76796e279c5d85f3c489700ee0/01_42_Common_Core/Inception/Subject_inception.pdf)
- [Documentación de Docker](https://docs.docker.com/)
- [Referencia de Docker Compose](https://docs.docker.com/reference/compose-file/)
- [Documentación de NGINX](https://nginx.org/en/docs/)
- [Documentación de PHP-FPM](https://www.php.net/manual/en/install.fpm.php)
- [Documentación de MariaDB](https://mariadb.com/kb/en/documentation/)
- [Documentación de WP-CLI](https://developer.wordpress.org/cli/commands/)

Se utilizó IA para ordenar los apuntes, aclarar conceptos y revisar la
redacción. La arquitectura y los comandos se contrastaron con el repositorio,
el subject y los archivos de configuración; la IA no sustituye las pruebas ni
debe recibir credenciales reales.

## Comparaciones exigidas

### Máquina virtual frente a Docker

Una máquina virtual emula hardware y arranca un sistema operativo completo.
Docker comparte el kernel del host y aísla procesos mediante namespaces y
cgroups. La VM ofrece una frontera de sistema más pesada; los contenedores son
más ligeros y adecuados para separar NGINX, WordPress y MariaDB. En Inception,
Docker se ejecuta dentro de la VM de 42.

### Secrets frente a variables de entorno

`srcs/.env` es cómodo para inyectar configuración, pero las variables pueden
aparecer en procesos, logs, salidas de Compose o commits accidentales. Docker
Secrets ofrece un mecanismo de archivos con acceso más controlado. Este proyecto
usa `.env` porque es el mecanismo configurado en Compose; ninguna credencial
debe versionarse.

### Red bridge frente a red del host

La red `inception` proporciona DNS privado y permite que los servicios usen
`mariadb:3306` y `wordpress:9000` sin publicarlos. `network_mode: host`
compartiría el namespace de red del host y reduciría el aislamiento. Por eso
solo NGINX publica `443:443`.

### Volúmenes frente a bind mounts

Un volumen es almacenamiento persistente gestionado por Docker; un bind mount
apunta a una ruta concreta del host. Aquí se declaran volúmenes con nombre y se
usa el driver local para respaldarlos en:

```text
wordpress -> /home/vhedo-ga/data/wordpress -> /var/www/wordpress
mariadb   -> /home/vhedo-ga/data/mariadb   -> /var/lib/mysql
```

Así, los contenedores pueden recrearse sin perder datos. NGINX monta los
archivos de WordPress en modo solo lectura.

## Red teaming, brevemente

La configuración también sirve para estudiar una frontera defensiva: no publicar
MariaDB, no incluir credenciales en imágenes y evitar montajes de host
excesivos reduce la superficie de ataque. Cualquier prueba debe ser autorizada
y limitarse al entorno local.
