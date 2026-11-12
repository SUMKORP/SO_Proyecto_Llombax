#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require_podman
load_env
mkdir -p "$PROJECT_DIR/data/musica" "$PROJECT_DIR/data/podcast" "$PROJECT_DIR/state/navidrome"

if ! podman network exists "$NETWORK"; then
  podman network create "$NETWORK" >/dev/null
fi
if ! podman volume exists "$DB_VOLUME"; then
  podman volume create "$DB_VOLUME" >/dev/null
fi

if ! container_exists "$DB_CONTAINER"; then
  echo 'Creando MariaDB en Podman (almacenamiento persistente)...'
  podman run -d \
    --name "$DB_CONTAINER" \
    --network "$NETWORK" \
    --network-alias mariadb \
    --restart unless-stopped \
    --health-cmd 'healthcheck.sh --connect --innodb_initialized' \
    --health-interval 10s \
    --health-timeout 5s \
    --health-retries 10 \
    -e MARIADB_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    -e MARIADB_DATABASE="$MYSQL_DATABASE" \
    -e MARIADB_USER="$MYSQL_USER" \
    -e MARIADB_PASSWORD="$MYSQL_PASSWORD" \
    -v "$DB_VOLUME:/var/lib/mysql" \
    "$DB_IMAGE" >/dev/null
elif ! container_running "$DB_CONTAINER"; then
  podman start "$DB_CONTAINER" >/dev/null
fi

# Navidrome usa su SQLite propia en /data (NO utiliza MariaDB).
# Ambas bibliotecas aparecen por defecto bajo ND_MUSICFOLDER=/music.
if ! container_exists "$NAV_CONTAINER"; then
  echo 'Creando Navidrome en Podman...'
  podman run -d \
    --name "$NAV_CONTAINER" \
    --network "$NETWORK" \
    --restart unless-stopped \
    --userns keep-id \
    --user "$(id -u):$(id -g)" \
    -p "${APP_PORT}:4533" \
    -e ND_MUSICFOLDER=/music \
    -e ND_DATAFOLDER=/data \
    -e ND_SCANINTERVAL="$ND_SCANINTERVAL" \
    -e ND_LOGLEVEL="$ND_LOGLEVEL" \
    -e ND_SESSIONTIMEOUT="$ND_SESSIONTIMEOUT" \
    -v "$PROJECT_DIR/data/musica:/music/musica:ro,Z" \
    -v "$PROJECT_DIR/data/podcast:/music/podcast:ro,Z" \
    -v "$PROJECT_DIR/state/navidrome:/data:Z" \
    "$NAV_IMAGE" >/dev/null
elif ! container_running "$NAV_CONTAINER"; then
  podman start "$NAV_CONTAINER" >/dev/null
fi

echo
echo 'Contenedores:'
podman ps --filter "name=so-" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
echo "Web: http://localhost:${APP_PORT}"
echo 'IMPORTANTE: La base interna de Navidrome es SQLite; MariaDB se conserva para el laboratorio.'
