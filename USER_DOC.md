# User documentation

## What this project provides

Inception runs a local WordPress site through an HTTPS-only NGINX entry point.
WordPress uses PHP-FPM and stores its data in MariaDB. The application and
database are reachable only through Docker's private `inception` network.

The three services have distinct roles:

- **NGINX** terminates TLS and is the only service exposed to the host.
- **WordPress/PHP-FPM** serves the website and processes PHP requests.
- **MariaDB** stores WordPress content, users, and configuration data.

## First installation

1. Install Docker Engine and the Docker Compose plugin.
2. Add the domain to `/etc/hosts`:

   ```text
   127.0.0.1 vhedo-ga.42.fr
   ```

3. Create the local environment file:

   ```bash
   cp .env.example srcs/.env
   ```

4. Edit `srcs/.env`. Set the domain and unique passwords before starting the
   stack. Never publish this file.
5. Start the project:

   ```bash
   make
   ```

6. Visit `https://vhedo-ga.42.fr`. Accept the browser warning for the
   self-signed development certificate.
7. Open `https://vhedo-ga.42.fr/wp-admin` to reach the WordPress
   administration panel.

The initial WordPress installation creates the administrator and author
accounts described by `WP_ADMIN_*` and `WP_USER_*` in `srcs/.env`.

## Credentials

The local credential source is `srcs/.env`, which is ignored by Git. The
database values are `SQL_DATABASE`, `SQL_USER`, `SQL_PASSWORD`, and
`SQL_ROOT_PASSWORD`. The WordPress administrator uses `WP_ADMIN_USER`,
`WP_ADMIN_PASSWORD`, and `WP_ADMIN_EMAIL`; the additional user uses
`WP_USER_LOGIN`, `WP_USER_PASSWORD`, and `WP_USER_EMAIL`.

Manage credentials by editing `srcs/.env`, restricting its permissions
(`chmod 600 srcs/.env`), and recreating the containers:

```bash
make down
make
```

Do not paste real passwords into issues, screenshots, logs, Dockerfiles, or
tracked files. Changing an already-installed WordPress password may also
require changing it from `/wp-admin` or with WP-CLI; changing `.env` alone does
not rewrite existing database users.

## Daily operation

```bash
make down
make
```

Stopping and starting the services preserves the data in
`/home/vhedo-ga/data`. To inspect the state or logs:

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs --tail=50 nginx
docker compose -f srcs/docker-compose.yml logs --tail=50 wordpress
docker compose -f srcs/docker-compose.yml logs --tail=50 mariadb
```

Only NGINX is expected to appear with a host port (`443`). Ports `9000` and
`3306` are internal service ports.

## Data and cleanup

| Data | Host location | Container location |
|---|---|---|
| WordPress files | `/home/vhedo-ga/data/wordpress` | `/var/www/wordpress` |
| MariaDB database | `/home/vhedo-ga/data/mariadb` | `/var/lib/mysql` |

Use `make clean` to remove Compose containers, network, and named volumes while
leaving the host data directories available. Use `make fclean` only when you
want to delete the host data and unused Docker resources as well.

## Troubleshooting

### The browser cannot connect

- Confirm the stack is running with `docker compose -f srcs/docker-compose.yml ps`.
- Confirm `/etc/hosts` maps `vhedo-ga.42.fr` to `127.0.0.1`.
- Use `https://`, not `http://`; port 80 is intentionally not configured.
- Read the NGINX logs.

### WordPress is not ready

MariaDB must become available before the WordPress setup script can complete.
Inspect both service logs and wait for the first initialization to finish.

### I changed `.env`

Environment values are read when containers are created. Recreate them after a
change:

```bash
make down
make
```

### I need a clean reinstall

```bash
make fclean
make
```

This permanently removes the local WordPress site and MariaDB contents.

## Authorized red-team checks

For this local lab, the main defensive boundary is easy to verify:

```bash
docker ps
docker port nginx
docker network inspect srcs_inception
```

Only NGINX should publish host port `443`; PHP-FPM `9000` and MariaDB `3306`
must remain internal. Never test this stack or attempt exploitation outside an
authorized environment.
