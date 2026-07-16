# Instant Chat

Instant Chat is a macOS instant messaging client with a retro visual style.

The product and repository use American English (`en-US`) exclusively.

## Current Status

The authentication foundation is in place:

- The Flutter macOS client provides retro registration and sign-in forms.
- The client restores sessions from macOS Keychain and rotates expired access tokens.
- The authenticated client displays API and database connectivity and supports sign-out.
- The Go API provides health, registration, sign-in, refresh, sign-out, and current-user endpoints.
- The health check verifies the MySQL connection with `PingContext`.
- MySQL migrations and sqlc queries define users and opaque session tokens.
- Docker Compose provides a pinned MySQL 8.4 development environment.
- OpenAPI defines the complete implemented HTTP contract.

Contacts, conversations, messages, WebSocket, Drift, Redis, and file uploads have not been implemented.

## Technology Stack

- macOS client: Flutter, Dart, Riverpod, Dio, and macOS Keychain.
- Server: Go, REST, `database/sql`, and sqlc.
- Database: MySQL 8.4 LTS.
- Local infrastructure: Docker Compose.
- API contract: OpenAPI 3.1.
- Database migrations: golang-migrate.

Future features will add go_router, WebSocket, Drift, SQLite, Redis, and MinIO only when they are needed.

## Requirements

- Flutter stable 3.44 or a compatible version.
- Go 1.26 or a compatible version.
- Docker Engine and Docker Compose v2.
- Xcode with the macOS desktop development tools.
- golang-migrate 4.19 or a compatible version with MySQL support.

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

## Apply Database Migrations

Install the pinned migration CLI once:

```bash
go install -tags mysql github.com/golang-migrate/migrate/v4/cmd/migrate@v4.19.1
```

Load the local configuration and apply all migrations from the repository root:

```bash
set -a
source .env
set +a
migrate -path db/migrations -database "$MIGRATION_DATABASE_URL" up
```

Run this step after MySQL is healthy and before starting the API. Migration filenames are append-only after they reach a shared branch.

## Start the Go API

Run from the repository root:

```bash
set -a
source .env
set +a
cd services/api
go run ./cmd/api
```

The API listens on `http://127.0.0.1:8080` by default. Implemented endpoints are:

```text
GET  /api/v1/health
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout
GET  /api/v1/auth/me
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

Implement contacts and the initial conversation list without adding real-time messaging yet.
