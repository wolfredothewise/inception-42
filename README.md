*This project has been created as part of the 42 curriculum by vhedo-ga.*

# Inception

<details open>
<summary>English (default) / Español</summary>

The English documentation is displayed by default. Expand the **Español**
section at the end of this file for the Spanish version.
</details>

## Description

Inception is a small three-tier web infrastructure built from custom Docker images
on Debian Bookworm. Docker Compose orchestrates:

- **NGINX**: the only public entry point, listening on HTTPS port `443` with
  TLS 1.2 and TLS 1.3.
- **WordPress + PHP-FPM**: serves the dynamic PHP application on the private
  Docker network.
- **MariaDB**: stores the WordPress database and is never published to the host.

The services communicate through the `inception` bridge network. WordPress data
and MariaDB data persist on the host at `/home/vhedo-ga/data/wordpress` and
`/home/vhedo-ga/data/mariadb`. Runtime variables and credentials belong in the
untracked `srcs/.env` file.

```text
Browser
   |
   | HTTPS :443
   v
NGINX  --->  WordPress/PHP-FPM :9000  --->  MariaDB :3306
                 (Docker bridge network)
```

## Repository layout

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs/
    ├── .env                  # local values; never commit
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        ├── wordpress/
        └── mariadb/
```

Each service has its own Dockerfile. The containers run their main service in
the foreground, so the service remains PID 1 and Docker can supervise it.

## Project description

Docker is used to package and isolate each infrastructure component while
Docker Compose describes their shared network, startup dependencies, port
exposure, environment, and persistent storage. The project deliberately builds
the service images itself from `debian:bookworm` rather than using pre-built
WordPress, NGINX, or MariaDB service images.

The included project sources are:

- `srcs/requirements/nginx/Dockerfile` and `conf/nginx.conf`: HTTPS entry point,
  self-signed certificate, TLS 1.2/1.3, static files, and FastCGI forwarding.
- `srcs/requirements/wordpress/Dockerfile`, `conf/www.conf`, and
  `tools/setup_wp.sh`: PHP-FPM, WP-CLI installation, and idempotent WordPress
  setup.
- `srcs/requirements/mariadb/Dockerfile`, `conf/50-server.cnf`, and
  `tools/setup_db.sh`: MariaDB configuration and database initialization.
- `srcs/docker-compose.yml`: services, the private bridge network, environment
  loading, restart policy, and named volumes backed by the required host paths.
- `Makefile`: repeatable build, start, stop, cleanup, and reset commands.

## Instructions

### Prerequisites

- Debian Bookworm or a compatible Debian host
- Docker Engine with the Compose plugin
- Git
- A host entry for the project domain:

  ```text
  127.0.0.1 vhedo-ga.42.fr
  ```

### Configure and start

From the repository root:

```bash
cp .env.example srcs/.env
# Edit srcs/.env and replace every example password.
make
```

The first build creates the host directories and starts all services in
detached mode. Open `https://vhedo-ga.42.fr`. The certificate is self-signed,
so a browser will display a warning during local development.

Useful commands:

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs --tail=50
make down       # stop containers; keep persistent data
make clean      # remove containers, network and Compose volumes
make fclean     # clean Docker resources and /home/vhedo-ga/data
make re         # fclean followed by a fresh build
```

`make fclean` is destructive: it removes the local WordPress and MariaDB data.
Use it only when a clean installation is intended.

## Resources

- [42 Inception subject](https://github.com/wolfredothewise/obsidian-vault/blob/f9eca1f87e8d4e76796e279c5d85f3c489700ee0/01_42_Common_Core/Inception/Subject_inception.pdf)
- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [PHP-FPM documentation](https://www.php.net/manual/en/install.fpm.php)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress WP-CLI documentation](https://developer.wordpress.org/cli/commands/)

### Use of AI

AI was used as a documentation assistant to organize the project notes,
clarify Docker concepts, compare deployment alternatives, and improve wording.
The resulting commands and architecture were checked against this repository's
`Makefile`, Compose file, Dockerfiles, configuration files, and the 42 subject.
AI was not used as a substitute for testing the stack or for storing secrets.

## Required comparisons

### Virtual machine vs Docker

| Virtual machine | Docker container |
|---|---|
| Emulates hardware and boots a complete guest OS. | Isolates processes while sharing the host kernel. |
| Stronger OS boundary, but higher CPU, RAM, and disk cost. | Lightweight and fast to build and start. |
| Each VM needs its own OS updates and services. | Each Inception service has a focused image and lifecycle. |

Inception still runs inside a VM in the 42 environment, but Docker provides the
service-level isolation inside that VM.

### Secrets vs environment variables

Environment variables are convenient configuration inputs and are used here
through `srcs/.env`. They are not a secure secret store: they can be exposed by
process inspection, Compose output, logs, or accidental commits. Docker secrets
provide a more suitable file-based mechanism with controlled access, but are
not required by this project and are not implemented by the current Compose
configuration. In either case, credentials must never be committed.

### Network vs host

The `inception` bridge network gives containers private DNS names and internal
connectivity (`wordpress` reaches `mariadb:3306`, and NGINX reaches
`wordpress:9000`). `network_mode: host` would remove that network isolation and
make a container share the host's network namespace. The project therefore
publishes only `443:443` from NGINX and keeps the application and database
ports internal.

### Volumes vs bind mounts

A Docker volume is Docker-managed persistent storage. A bind mount maps an
explicit host path. This project declares named volumes in Compose but backs
them with local bind drivers so the required host locations are explicit:

```text
wordpress -> /home/vhedo-ga/data/wordpress -> /var/www/wordpress
mariadb   -> /home/vhedo-ga/data/mariadb   -> /var/lib/mysql
```

The important distinction is that container filesystems are disposable while
these mounted paths survive container recreation. A read-only WordPress mount
is used by NGINX.

## Brief red-team relevance

This stack is also a useful defensive study target: exposed database ports,
hard-coded credentials, unsafe host mounts, excessive container privileges, or
weak TLS would expand the attack surface. In this project the intended boundary
is NGINX on port 443; security testing must remain authorized and local.

<details>
<summary>Español</summary>

## Descripción

Inception es una infraestructura web de tres capas construida con imágenes
Docker propias sobre Debian Bookworm. Docker Compose coordina NGINX, WordPress
con PHP-FPM y MariaDB. NGINX es la única entrada pública por HTTPS `443`;
WordPress y MariaDB se comunican mediante la red privada `inception`.

Los datos persisten en `/home/vhedo-ga/data/wordpress` y
`/home/vhedo-ga/data/mariadb`. Las variables y credenciales se guardan en
`srcs/.env`, que no debe subirse al repositorio.

## Descripción del proyecto

Docker permite empaquetar y aislar cada componente, mientras Docker Compose
define los servicios, sus dependencias, la red, los puertos, las variables y
el almacenamiento. Las imágenes se construyen desde `debian:bookworm` con
Dockerfiles propios. Las fuentes incluidas son los Dockerfiles, configuraciones
y scripts de `srcs/requirements/`, el `docker-compose.yml` y el `Makefile`.

## Instrucciones

Requisitos: Debian Bookworm (o compatible), Docker Engine con el plugin Compose,
Git y esta entrada en `/etc/hosts`:

```text
127.0.0.1 vhedo-ga.42.fr
```

Desde la raíz:

```bash
cp .env.example srcs/.env
# Edita srcs/.env y cambia todas las contraseñas de ejemplo.
make
```

Abre `https://vhedo-ga.42.fr`. El certificado local es autofirmado.

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs --tail=50
make down       # detener y conservar datos
make clean      # eliminar contenedores, red y volúmenes Compose
make fclean     # limpieza destructiva, incluidos los datos del host
make re         # fclean y arranque desde cero
```

## Recursos y uso de IA

Consulta el [subject de Inception](https://github.com/wolfredothewise/obsidian-vault/blob/f9eca1f87e8d4e76796e279c5d85f3c489700ee0/01_42_Common_Core/Inception/Subject_inception.pdf),
la [documentación de Docker](https://docs.docker.com/), la [referencia de
Compose](https://docs.docker.com/reference/compose-file/), la
[documentación de NGINX](https://nginx.org/en/docs/), [PHP-FPM](https://www.php.net/manual/en/install.fpm.php),
[MariaDB](https://mariadb.com/kb/en/documentation/) y
[WP-CLI](https://developer.wordpress.org/cli/commands/).

La IA se utilizó para organizar los apuntes, aclarar conceptos Docker,
comparar alternativas y revisar la redacción de esta documentación. La
arquitectura y los comandos se contrastaron con el repositorio, el subject y
los archivos de configuración; no se usó IA para almacenar credenciales.

## Comparaciones

### Máquina virtual frente a Docker

Una VM emula hardware y arranca un sistema operativo completo. Docker comparte
el kernel del host y aísla procesos con namespaces y cgroups. La VM ofrece una
frontera más pesada; Docker es más ligero y separa cada servicio de Inception.

### Secrets frente a variables de entorno

`srcs/.env` es cómodo para inyectar configuración, pero las variables pueden
aparecer en procesos, logs o salidas de Compose. Docker Secrets ofrece un
mecanismo de archivos más controlado. Ninguna credencial debe versionarse.

### Red Docker frente a red del host

La red bridge `inception` proporciona DNS privado para `mariadb:3306` y
`wordpress:9000`. `network_mode: host` compartiría el namespace de red del
host y reduciría el aislamiento. Por eso solo NGINX publica `443:443`.

### Volúmenes frente a bind mounts

Un volumen es almacenamiento persistente gestionado por Docker; un bind mount
apunta a una ruta explícita del host. Aquí los volúmenes nombrados se respaldan
en `/home/vhedo-ga/data/wordpress` y `/home/vhedo-ga/data/mariadb`, por lo que
los contenedores pueden recrearse sin perder datos.

## Red teaming, brevemente

No publicar MariaDB, no incluir credenciales en las imágenes y evitar montajes
de host excesivos reduce la superficie de ataque. Cualquier prueba debe estar
autorizada y limitarse al laboratorio local.

</details>
