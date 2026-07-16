# Instant Chat

Instant Chat is a macOS instant messaging client with a modern, native-feeling interface.

The product and repository use American English (`en-US`) exclusively.

## Current Status

The authentication, contacts, direct conversations, and persisted text-message foundations are in place:

- The Flutter macOS client provides modern registration and sign-in forms.
- Registration assigns a unique lowercase username for exact account search.
- The client restores sessions from macOS Keychain and rotates expired access tokens.
- The authenticated client provides modern chats, contacts, requests, and system-status workspaces.
- The chat workspace provides real conversation filtering and a persistent desktop master-detail layout.
- The resizable macOS window opens at 1,180 by 660 points.
- Users can search by exact username, send contact requests, accept or reject incoming requests, remove contacts, and open a direct conversation.
- Direct channels load cursor-paginated history, receive realtime messages, recover sequence gaps after reconnecting, and can send or retry text messages without creating duplicates.
- The Go API provides health, registration, sign-in, refresh, sign-out, and current-user endpoints.
- The Go API enforces unique bilateral contact relationships and unique direct conversations.
- The health check verifies the MySQL connection with `PingContext`.
- MySQL migrations and sqlc queries define users, opaque session tokens, contact relationships, conversations, members, and ordered messages.
- Docker Compose provides a pinned MySQL 8.4 development environment.
- OpenAPI defines the implemented HTTP and WebSocket event contracts.

Local Drift storage, read receipts, Redis, and file uploads have not been implemented.

## Technology Stack

- macOS client: Flutter, Dart, Riverpod, Dio, and macOS Keychain.
- Server: Go, REST, WebSocket, `database/sql`, and sqlc.
- Database: MySQL 8.4 LTS.
- Local infrastructure: Docker Compose.
- API contract: OpenAPI 3.1.
- Database migrations: golang-migrate.

Future features will add go_router, Drift, SQLite, Redis, and MinIO only when they are needed.

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

## Start Development

Start the complete development environment from the repository root:

```bash
make dev
```

This command starts MySQL, waits for its health check, applies pending migrations, builds and starts the Go API, and opens the Flutter macOS client. Close the client or press `Ctrl+C` to stop the API. MySQL stays available for faster restarts.

Stop MySQL and the Docker development network when they are no longer needed:

```bash
make stop
```

Other development commands:

```bash
make migrate
make check
```

`make migrate` applies pending migrations. `make check` validates Docker Compose and SQL sources, then runs Go formatting checks, vet, race tests, the Go build, Dart formatting checks, Flutter analysis, Flutter tests, and the macOS debug build.

## Manual Startup and Troubleshooting

Start MySQL:

```bash
docker compose --env-file .env -f deploy/docker/compose.yaml up -d mysql
```

Apply migrations with the pinned tool version:

```bash
./scripts/migrate.sh
```

Run this step after MySQL is healthy and before starting the API. Migration filenames are append-only after they reach a shared branch.

Start the API:

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
GET  /api/v1/users/search?username={username}
POST /api/v1/contact-requests
GET  /api/v1/contact-requests
POST /api/v1/contact-requests/{request_id}/accept
POST /api/v1/contact-requests/{request_id}/reject
GET  /api/v1/contacts
DELETE /api/v1/contacts/{user_id}
POST /api/v1/conversations
GET  /api/v1/conversations
POST /api/v1/conversations/{conversation_id}/messages
GET  /api/v1/conversations/{conversation_id}/messages?before={sequence}&limit={count}
GET  /api/v1/conversations/{conversation_id}/messages?after={sequence}&limit={count}
GET  /api/v1/realtime  (WebSocket upgrade)
```

Start the client in another terminal:

```bash
cd apps/macos_client
flutter run -d macos
```

The client connects to `http://127.0.0.1:8080` by default. Override the address when needed:

```bash
flutter run -d macos --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

## Verification

```bash
make check
```

## Project Standards

Every AI coding agent must read the root `AGENTS.md` and then read `docs/AGENTS.md` in full.

Architecture boundaries are documented in `docs/architecture.md`. The REST contract is located at `api/openapi/openapi.yaml`.

## Next Milestone

Add local Drift caching and unread state on top of the persisted REST and WebSocket message source of truth.
