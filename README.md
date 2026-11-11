*vhedo-ga*

# Inception

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
├── README.es.md
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
