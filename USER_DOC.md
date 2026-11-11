# User documentation

## What this project provides

Inception runs a local WordPress site through an HTTPS-only NGINX entry point.
WordPress uses PHP-FPM and stores its data in MariaDB. The application and
database are reachable only through Docker's private `inception` network.

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

The initial WordPress installation creates the administrator and author
accounts described by `WP_ADMIN_*` and `WP_USER_*` in `srcs/.env`.

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
