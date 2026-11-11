# Developer documentation

## Architecture

The project is a Compose application with three custom Debian Bookworm images:

| Service | Build context | Main process | Internal port |
|---|---|---|---|
| `nginx` | `srcs/requirements/nginx` | `nginx -g "daemon off;"` | `443` |
| `wordpress` | `srcs/requirements/wordpress` | `setup_wp.sh` then `php-fpm8.2 -F` | `9000` |
| `mariadb` | `srcs/requirements/mariadb` | `setup_db.sh` then `mysqld` | `3306` |

Compose creates the `inception` bridge network and starts WordPress after
MariaDB, then NGINX after WordPress. Docker's service DNS resolves the names
`mariadb` and `wordpress` inside that network.

Only this mapping crosses the host boundary:

```yaml
ports:
  - "443:443"
```

The application and database use `expose` for documentation/internal
connectivity, not host publication.

## Configuration flow

`srcs/docker-compose.yml` reads `srcs/.env` through `env_file`. The tracked
`.env.example` is a template for creating that local file. Do not put real
credentials in Dockerfiles, Compose YAML, scripts, or Git history.

The WordPress setup script:

1. waits until MariaDB accepts a query;
2. downloads WordPress if the volume is empty;
3. creates `wp-config.php` from the database variables;
4. installs WordPress if it is not installed;
5. creates the configured author account if absent;
6. changes ownership to `www-data`;
7. replaces the shell process with foreground PHP-FPM using `exec`.

The MariaDB setup script initializes the data directory once, creates the
database and application user, sets the root password, and finally replaces
itself with foreground `mysqld`.

## NGINX request flow

NGINX listens only on TLS port `443`, accepts TLS 1.2 and TLS 1.3, and serves
the WordPress volume at `/var/www/wordpress`. Requests for PHP files are sent
to `wordpress:9000` using FastCGI. The WordPress volume is mounted read-only
in NGINX; PHP-FPM owns the writable application volume.

The certificate is generated during the NGINX image build for the local
domain. It is self-signed and intended for the 42 development environment, not
for production.

## Storage design

Compose declares named volumes backed by explicit local driver options:

```text
srcs_mariadb   -> /home/vhedo-ga/data/mariadb
srcs_wordpress -> /home/vhedo-ga/data/wordpress
```

This combines stable Compose volume names with the path required by the
subject. Removing containers does not remove these host directories. The
`fclean` Makefile target explicitly does, so it must be treated as destructive.

## Lifecycle and PID 1

Containers must stay alive because their main service remains in the foreground:

- NGINX uses `daemon off;`.
- PHP-FPM uses `-F`.
- MariaDB is launched as the final process by `exec`.

Do not use `tail -f`, `sleep infinity`, `while true`, or a background daemon as
a container keep-alive mechanism. The short `until ... sleep` loops in the
initialization scripts are bounded readiness checks; they end when the
dependency is available.

## Development workflow

```bash
make                 # build and start
make down            # stop and remove containers/network
make clean           # remove Compose volumes too
make fclean          # destructive reset
make re              # destructive reset and rebuild
```

Useful validation commands:

```bash
docker compose -f srcs/docker-compose.yml config
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs --tail=100
docker exec nginx nginx -t
docker exec wordpress php-fpm8.2 -v
docker exec mariadb mariadb-admin ping
docker network inspect srcs_inception
docker volume inspect srcs_mariadb srcs_wordpress
```

After changing a Dockerfile or configuration, recreate the services with
`make down && make`. After changing only a local environment value, the same
recreation is required because Compose injects variables when containers are
created.

## From-scratch setup

1. Install Debian Bookworm, Docker Engine, the Docker Compose plugin, Git, and
   the usual shell utilities.
2. Clone the repository and enter its root directory.
3. Add `127.0.0.1 vhedo-ga.42.fr` to `/etc/hosts`.
4. Create `srcs/.env` from `.env.example` and replace all example values:

   ```bash
   cp .env.example srcs/.env
   chmod 600 srcs/.env
   ```

5. Confirm that `srcs/.env` is not tracked, then build and launch:

   ```bash
   make
   ```

Compose injects the environment file into all three services. The Makefile
creates `/home/vhedo-ga/data/mariadb` and
`/home/vhedo-ga/data/wordpress` before Compose starts.

## Container and volume management

Use these commands when diagnosing or maintaining the deployment:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
docker compose -f srcs/docker-compose.yml stop
docker compose -f srcs/docker-compose.yml start
docker compose -f srcs/docker-compose.yml restart
docker compose -f srcs/docker-compose.yml down
docker compose -f srcs/docker-compose.yml down -v
docker ps
docker logs nginx
docker exec -it wordpress bash
docker volume ls
docker volume inspect srcs_mariadb srcs_wordpress
```

`down` removes containers and the Compose network but keeps the host data.
`down -v` removes the named volume objects; the local driver paths remain until
they are explicitly deleted. `make fclean` additionally removes both host data
directories and prunes unused Docker resources.

## Port-change checklist

If a reviewer asks for a port change, update every endpoint in the path:

- NGINX: `listen`, Compose `ports`, and the URL used by WordPress.
- PHP-FPM: `www.conf`, NGINX `fastcgi_pass`, and Compose `expose`.
- MariaDB: `50-server.cnf`, the WordPress readiness check, and `DB_HOST`.

Rebuild and verify the host port is free before testing. Do not expose PHP-FPM
or MariaDB to the host.

## Security notes

Keep `srcs/.env` untracked and replace example credentials locally. Review
volume paths and permissions before extending the project. The Docker bridge
network is an application boundary, not a replacement for authentication,
patching, or authorization. Red-team testing should remain authorized and
limited to the local lab.

## Authorized red-team perspective

The stack models a common assessment path without turning this repository into
an exploit guide: NGINX is the exposed edge, WordPress is the application tier,
and MariaDB is the internal data tier. A configuration review should confirm
that only port `443` is published, `.env` is not committed, PHP-FPM and MariaDB
are reachable only through the bridge network, and host mounts are limited to
the two required data directories. These checks are defensive and must only be
performed with authorization.
