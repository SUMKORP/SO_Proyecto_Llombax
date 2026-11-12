#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require_podman
# Recrea contenedores para aplicar ajustes de .env, conservando los datos.
for name in "$NAV_CONTAINER" "$DB_CONTAINER"; do
  if container_exists "$name"; then
    podman rm -f "$name" >/dev/null
  fi
done
bash "$PROJECT_DIR/scripts/start.sh"
echo 'Contenedores recreados. Volúmenes y archivos persistentes intactos.'
