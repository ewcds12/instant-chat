#!/usr/bin/env bash

set -Eeuo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
environment_file="$repository_root/.env"
compose_file="$repository_root/deploy/docker/compose.yaml"
api_binary="${TMPDIR:-/tmp}/instant-chat-dev-api-$$"
api_pid=""

cleanup() {
  exit_code=$?
  trap - EXIT
  if [[ -n "$api_pid" ]] && kill -0 "$api_pid" >/dev/null 2>&1; then
    echo
    echo "Stopping the API..."
    kill -TERM "$api_pid"
    wait "$api_pid" 2>/dev/null || true
  fi
  rm -f "$api_binary"
  exit "$exit_code"
}
trap cleanup EXIT

for command_name in curl docker flutter go; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$command_name is required but was not found." >&2
    exit 1
  fi
done

if [[ ! -f "$environment_file" ]]; then
  echo "Missing .env. Copy .env.example to .env and replace the example passwords." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$environment_file"
set +a

echo "Starting MySQL..."
docker compose \
  --env-file "$environment_file" \
  -f "$compose_file" \
  up -d mysql

container_id="$(docker compose \
  --env-file "$environment_file" \
  -f "$compose_file" \
  ps -q mysql)"

if [[ -z "$container_id" ]]; then
  echo "MySQL container was not created." >&2
  exit 1
fi

echo "Waiting for MySQL..."
mysql_ready=false
for _ in {1..60}; do
  container_status="$(docker inspect \
    --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
    "$container_id")"
  if [[ "$container_status" == "healthy" ]]; then
    mysql_ready=true
    break
  fi
  if [[ "$container_status" == "exited" || "$container_status" == "dead" ]]; then
    echo "MySQL stopped before becoming healthy." >&2
    exit 1
  fi
  sleep 1
done

if [[ "$mysql_ready" != true ]]; then
  echo "MySQL did not become healthy within 60 seconds." >&2
  exit 1
fi

echo "Applying database migrations..."
"$repository_root/scripts/migrate.sh"

echo "Building the API..."
(
  cd "$repository_root/services/api"
  go build -o "$api_binary" ./cmd/api
)

echo "Starting the API..."
"$api_binary" &
api_pid=$!

api_url="http://${API_HOST:-127.0.0.1}:${API_PORT:-8080}"
api_ready=false
for _ in {1..60}; do
  if ! kill -0 "$api_pid" >/dev/null 2>&1; then
    wait "$api_pid" 2>/dev/null || true
    echo "The API stopped before becoming healthy." >&2
    exit 1
  fi
  if curl --fail --silent --show-error "$api_url/api/v1/health" >/dev/null 2>&1; then
    api_ready=true
    break
  fi
  sleep 1
done

if [[ "$api_ready" != true ]]; then
  echo "The API did not become healthy within 60 seconds." >&2
  exit 1
fi

export NO_PROXY="${NO_PROXY:+$NO_PROXY,}localhost,127.0.0.1,::1"
export no_proxy="${no_proxy:+$no_proxy,}localhost,127.0.0.1,::1"

echo "Opening the macOS client..."
echo "Close the client or press Ctrl+C to stop the API."
cd "$repository_root/apps/macos_client"
flutter run -d macos --dart-define="API_BASE_URL=$api_url"
