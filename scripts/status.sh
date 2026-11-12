#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require_podman
podman ps -a --filter 'name=so-' --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
