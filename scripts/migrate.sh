#!/usr/bin/env bash

set -Eeuo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
environment_file="$repository_root/.env"

if [[ ! -f "$environment_file" ]]; then
  echo "Missing .env. Copy .env.example to .env and replace the example passwords." >&2
  exit 1
fi

if ! command -v go >/dev/null 2>&1; then
  echo "Go is required but was not found." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$environment_file"
set +a

if [[ -z "${MIGRATION_DATABASE_URL:-}" ]]; then
  echo "MIGRATION_DATABASE_URL must be set in .env." >&2
  exit 1
fi

cd "$repository_root"
go run -tags mysql \
  github.com/golang-migrate/migrate/v4/cmd/migrate@v4.19.1 \
  -path db/migrations \
  -database "$MIGRATION_DATABASE_URL" up
