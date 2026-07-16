#!/usr/bin/env bash

set -Eeuo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
environment_file="$repository_root/.env"
api_binary="${TMPDIR:-/tmp}/instant-chat-check-api-$$"

cleanup() {
  rm -f "$api_binary"
}
trap cleanup EXIT

for command_name in docker go flutter; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$command_name is required but was not found." >&2
    exit 1
  fi
done

if [[ ! -f "$environment_file" ]]; then
  echo "Missing .env. Copy .env.example to .env and replace the example passwords." >&2
  exit 1
fi

echo "Checking Docker Compose configuration..."
docker compose \
  --env-file "$environment_file" \
  -f "$repository_root/deploy/docker/compose.yaml" \
  config --quiet

echo "Checking SQL sources..."
(
  cd "$repository_root"
  go run github.com/sqlc-dev/sqlc/cmd/sqlc@v1.30.0 compile -f db/sqlc.yaml
)

echo "Checking the Go API..."
(
  cd "$repository_root/services/api"
  unformatted="$(gofmt -l .)"
  if [[ -n "$unformatted" ]]; then
    echo "Go files require formatting:" >&2
    echo "$unformatted" >&2
    exit 1
  fi
  go vet ./...
  go test -race ./...
  go build -o "$api_binary" ./cmd/api
)

export NO_PROXY="${NO_PROXY:+$NO_PROXY,}localhost,127.0.0.1,::1"
export no_proxy="${no_proxy:+$no_proxy,}localhost,127.0.0.1,::1"

echo "Checking the Flutter macOS client..."
(
  cd "$repository_root/apps/macos_client"
  dart format --output=none --set-exit-if-changed .
  flutter analyze --no-pub
  flutter test --no-pub
  flutter build macos --debug --no-pub
)

echo "All checks passed."
