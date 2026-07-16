#!/usr/bin/env bash

set -Eeuo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
environment_file="$repository_root/.env"
compose_file="$repository_root/deploy/docker/compose.yaml"

if [[ ! -f "$environment_file" ]]; then
  echo "Missing .env. Nothing was stopped." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required but was not found." >&2
  exit 1
fi

docker compose \
  --env-file "$environment_file" \
  -f "$compose_file" \
  down
