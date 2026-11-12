#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_env
if ! command -v ngrok >/dev/null 2>&1; then
  echo 'ERROR: ngrok no está instalado. Consulta https://ngrok.com/download' >&2
  exit 1
fi
echo "Exponiendo http://localhost:${APP_PORT} mediante ngrok. Ctrl+C para cerrar el túnel."
exec ngrok http "$APP_PORT"
