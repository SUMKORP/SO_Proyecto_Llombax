#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require_podman
load_env
if ! container_running "$DB_CONTAINER"; then
  echo "ERROR: Inicia MariaDB antes del respaldo (scripts/start.sh)." >&2
  exit 1
fi
stamp="$(date +%Y-%m-%d_%H-%M-%S)"
backup_dir="$PROJECT_DIR/backups/backup_$stamp"
mkdir -p "$backup_dir"
chmod 700 "$backup_dir"

# SQL de MariaDB (independiente de Navidrome)
echo 'Respaldando MariaDB...'
podman exec --env "MYSQL_PWD=$MYSQL_PASSWORD" "$DB_CONTAINER" \
  mariadb-dump --user="$MYSQL_USER" --single-transaction "$MYSQL_DATABASE" \
  > "$backup_dir/mariadb.sql"
chmod 600 "$backup_dir/mariadb.sql"

# Una copia de la SQLite activa se debe hacer con el servicio detenido.
nav_was_running=0
restore_navidrome() {
  if (( nav_was_running )) && ! container_running "$NAV_CONTAINER"; then
    podman start "$NAV_CONTAINER" >/dev/null || true
  fi
}
trap restore_navidrome EXIT
if container_running "$NAV_CONTAINER"; then
  nav_was_running=1
  echo 'Pausando Navidrome para respaldar SQLite consistentemente...'
  podman stop "$NAV_CONTAINER" >/dev/null
fi
mkdir -p "$PROJECT_DIR/state/navidrome"
tar -C "$PROJECT_DIR/state" -czf "$backup_dir/navidrome-data.tar.gz" navidrome
restore_navidrome
nav_was_running=0
trap - EXIT

# Copia de las bibliotecas (puede ocupar mucho espacio).
echo 'Copiando música y podcasts...'
tar -C "$PROJECT_DIR/data" -czf "$backup_dir/bibliotecas.tar.gz" musica podcast

echo "Backup completado: $backup_dir"
