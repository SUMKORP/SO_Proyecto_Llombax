#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_CONTAINER="so-mariadb"
NAV_CONTAINER="so-navidrome"
NETWORK="so-proyecto-net"
DB_VOLUME="so-mariadb-data"
DB_IMAGE="docker.io/library/mariadb:10.11"
NAV_IMAGE="docker.io/navidrome/navidrome:latest"

require_podman() {
  if ! command -v podman >/dev/null 2>&1; then
    echo 'ERROR: Instala Podman (sudo dnf install -y podman).' >&2
    exit 1
  fi
  if ! podman info >/dev/null 2>&1; then
    echo 'ERROR: Podman no está operativo para este usuario. Comprueba podman info.' >&2
    exit 1
  fi
}

load_env() {
  if [[ ! -f "$PROJECT_DIR/.env" ]]; then
    echo 'ERROR: Falta .env. Ejecuta: cp .env.example .env && nano .env' >&2
    exit 1
  fi
  # Archivo de configuración confiable, administrado por el dueño del proyecto.
  set -a
  # shellcheck disable=SC1091
  source "$PROJECT_DIR/.env"
  set +a
  : "${MYSQL_DATABASE:=navidrome_lab}"
  : "${MYSQL_USER:=navidrome_lab}"
  : "${APP_PORT:=4533}"
  : "${ND_SCANINTERVAL:=1h}"
  : "${ND_LOGLEVEL:=info}"
  : "${ND_SESSIONTIMEOUT:=48h}"
  if [[ -z "${MYSQL_ROOT_PASSWORD:-}" || -z "${MYSQL_PASSWORD:-}" || \
     "$MYSQL_ROOT_PASSWORD" == CAMBIAR_ROOT_PASSWORD || \
     "$MYSQL_PASSWORD" == CAMBIAR_USER_PASSWORD ]]; then
    echo 'ERROR: Cambia las contraseñas de ejemplo en .env.' >&2
    exit 1
  fi
  if [[ ! "$APP_PORT" =~ ^[0-9]+$ ]] || (( APP_PORT < 1024 || APP_PORT > 65535 )); then
    echo 'ERROR: APP_PORT debe ser un número entre 1024 y 65535 para Podman rootless.' >&2
    exit 1
  fi
  if [[ ! "$MYSQL_DATABASE" =~ ^[A-Za-z0-9_]+$ || ! "$MYSQL_USER" =~ ^[A-Za-z0-9_]+$ ]]; then
    echo 'ERROR: MYSQL_DATABASE y MYSQL_USER deben contener letras, números o _.' >&2
    exit 1
  fi
}

container_exists() { podman container exists "$1"; }
container_running() { [[ "$(podman inspect --format '{{.State.Running}}' "$1" 2>/dev/null || true)" == true ]]; }
