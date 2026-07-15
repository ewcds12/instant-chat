# Instant Chat

Instant Chat is a macOS instant messaging client with a retro visual style.

The product and repository use American English (`en-US`) exclusively.

## Current Status

The minimum end-to-end foundation is in place:

- The Flutter macOS client displays API and database connectivity.
- The Go API provides `GET /api/v1/health`.
- The health check verifies the MySQL connection with `PingContext`.
- Docker Compose provides a pinned MySQL 8.4 development environment.
- OpenAPI defines successful and degraded health responses.

Sign-in, contacts, messages, WebSocket, Drift, Redis, and file uploads have not been implemented.

## Technology Stack

- macOS client: Flutter, Dart, Riverpod, and Dio.
- Server: Go, REST, and `database/sql`.
- Database: MySQL 8.4 LTS.
- Local infrastructure: Docker Compose.
- API contract: OpenAPI 3.1.

Future features will add go_router, WebSocket, Drift, SQLite, sqlc, Redis, and MinIO only when they are needed.

## Requirements

- Flutter stable 3.44 or a compatible version.
- Go 1.26 or a compatible version.
- Docker Engine and Docker Compose v2.
- Xcode with the macOS desktop development tools.

If the development machine uses an HTTP proxy, make sure `NO_PROXY` includes at least `localhost,127.0.0.1,::1`. Otherwise, the Flutter test process may be unable to connect to its local WebSocket.

## Local Configuration

Create the local environment file from the repository root:

```bash
cp .env.example .env
```

Replace the example passwords in `.env` before starting the services. Git ignores `.env`; never commit real credentials.

## Start MySQL

Run from the repository root:

```bash
docker compose --env-file .env -f deploy/docker/compose.yaml up -d mysql
```

Check its status:

```bash
docker compose --env-file .env -f deploy/docker/compose.yaml ps
```

## Start the Go API

Run from the repository root:

```bash
set -a
source .env
set +a
cd services/api
go run ./cmd/api
```

The API listens on `http://127.0.0.1:8080` by default. Its health endpoint is:

```text
http://127.0.0.1:8080/api/v1/health
```

## Start the macOS Client

Open another terminal window and run:

```bash
cd apps/macos_client
flutter run -d macos
```

The client connects to `http://127.0.0.1:8080` by default. Override the address when needed:

```bash
flutter run -d macos --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

## Verification

Go:

```bash
cd services/api
gofmt -l .
go vet ./...
go test -race ./...
go build -o /tmp/instant-chat-api ./cmd/api
```

Flutter:

```bash
cd apps/macos_client
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build macos --debug
```

## Project Standards

Every AI coding agent must read the root `AGENTS.md` and then read `docs/AGENTS.md` in full.

Architecture boundaries are documented in `docs/architecture.md`. The REST contract is located at `api/openapi/openapi.yaml`.

## Next Milestone

Implement registration and sign-in, including server-side authentication, database migrations, client forms, and macOS Keychain token storage.
