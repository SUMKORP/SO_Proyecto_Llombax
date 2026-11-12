#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require_podman
for name in "$NAV_CONTAINER" "$DB_CONTAINER"; do
  if container_running "$name"; then
    podman stop "$name"
  fi
done
echo 'Servicios detenidos. Los volúmenes, biblioteca y configuración se conservan.'
